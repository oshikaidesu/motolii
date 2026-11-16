import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

/// Reads file paths from the clipboard and from drops onto the window.
///
/// - Channel "motolii/pasteboard", method "read": returns the current
///   clipboard's file paths. If the clipboard holds image or pdf data instead
///   of files, the bytes are written to a temp file and that path is returned.
/// - Channel "motolii/drops", event stream: each drop sends one message
///   { "paths": [String...] }. The Dart side listens and places each path as
///   a layer.
///
/// No third-party plugin, no Rust: only Cocoa's own NSPasteboard and NSView
/// dragging destination, so it can't fight the engine's dylib loader.
enum PasteboardFiles {
  private static var dropChannel: FlutterMethodChannel?
  private static var dropTarget: DropTarget?

  static func attach(to controller: FlutterViewController) {
    let r = controller.registrar(forPlugin: "MotoliiPasteboard")
    let read = FlutterMethodChannel(name: "motolii/pasteboard", binaryMessenger: r.messenger)
    read.setMethodCallHandler { call, result in
      switch call.method {
      case "read":
        result(readClipboardPaths())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    dropChannel = FlutterMethodChannel(name: "motolii/drops", binaryMessenger: r.messenger)
    // (install the dragging destination next tick, when the window is up)
    DispatchQueue.main.async {
      if let v = controller.view as? NSView {
        let t = DropTarget(view: v) { paths in
          dropChannel?.invokeMethod("paths", arguments: ["paths": paths])
        }
        dropTarget = t
      }
    }
  }

  // Returns file paths on the pasteboard, writing any image/pdf bytes to a
  // temp file first. Empty if the clipboard holds neither.
  private static func readClipboardPaths() -> [String] {
    let pb = NSPasteboard.general
    var paths: [String] = []
    if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
      for u in urls where u.isFileURL { paths.append(u.path) }
    }
    if paths.isEmpty {
      // (image: TIFF/PNG; pdf as its own type)
      if let png = pb.data(forType: .png) {
        if let p = writeTemp(png, ext: "png") { paths.append(p) }
      } else if let tiff = pb.data(forType: .tiff) {
        if let p = writeTemp(tiff, ext: "tiff") { paths.append(p) }
      } else if let pdf = pb.data(forType: .pdf) {
        if let p = writeTemp(pdf, ext: "pdf") { paths.append(p) }
      }
    }
    return paths
  }

  private static func writeTemp(_ data: Data, ext: String) -> String? {
    let stamp = Int(Date().timeIntervalSince1970 * 1000)
    let dir = (NSTemporaryDirectory() as NSString).appendingPathComponent("motolii_pasted_\(stamp)")
    do {
      try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    } catch { return nil }
    let path = (dir as NSString).appendingPathComponent("pasted.\(ext)")
    do {
      try data.write(to: URL(fileURLWithPath: path))
      return path
    } catch { return nil }
  }
}

/// A dragging destination registered on the Flutter view: when the user drops
/// files or folders from Finder (or any app that puts file URLs on the drag
/// pasteboard), the paths are handed to Dart.
final class DropTarget: NSObject {
  private let onDrop: ([String]) -> Void
  private weak var view: NSView?

  init(view: NSView, onDrop: @escaping ([String]) -> Void) {
    self.onDrop = onDrop
    self.view = view
    super.init()
    view.registerForDraggedTypes([.fileURL])
    // (Swizzle-free: wrap the view's drop by subclassing it would mean
    // replacing FlutterView, which we don't own. Instead, install a child
    // NSView over the content that forwards the drop. This is the standard
    // pattern desktop_drop takes too.)
    let overlay = DropOverlay(onDrop: onDrop)
    overlay.frame = view.bounds
    overlay.autoresizingMask = [.width, .height]
    view.addSubview(overlay)
    overlay.registerForDraggedTypes([.fileURL])
  }
}

/// Transparent NSView on top of the Flutter view that handles file drops and
/// otherwise lets every mouse / scroll event through to the view below.
final class DropOverlay: NSView {
  private let onDrop: ([String]) -> Void

  init(onDrop: @escaping ([String]) -> Void) {
    self.onDrop = onDrop
    super.init(frame: .zero)
  }

  required init?(coder: NSCoder) { fatalError() }

  // (events pass through: this view handles only drag-and-drop)
  override func hitTest(_ point: NSPoint) -> NSView? { nil }

  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    hasFileURLs(sender) ? .copy : []
  }

  override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    hasFileURLs(sender) ? .copy : []
  }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let paths = filePaths(sender)
    if paths.isEmpty { return false }
    onDrop(paths)
    return true
  }

  private func hasFileURLs(_ sender: NSDraggingInfo) -> Bool {
    sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
  }

  private func filePaths(_ sender: NSDraggingInfo) -> [String] {
    guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] else {
      return []
    }
    return urls.filter { $0.isFileURL }.map { $0.path }
  }
}
