// An Expression card's Block mode (fx_code.dart): Google's Blockly as it comes (npm blockly 13.4.0, Apache-2.0,
// assets/blocks/blockly/LICENSE), in the system's web view (webview_flutter: WKWebView on macOS). The page,
// assets/blocks/expression_blocks.html, is told the workspace kept (Blockly's own JSON) once it is up, and tells each
// change back on the Motolii channel as {state, code}: the workspace, and the each() Blockly's JavaScript generator
// writes from it. Going from code back to blocks is not done: the blocks are the source, the code is made from them.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart' show WebKitWebViewController;

class BlockCode extends StatefulWidget {
  const BlockCode(this.state, this.changed, {super.key});
  final String? state;   // (the workspace as last kept; null: the page's first, one "copy" block)
  final void Function(String state, String code) changed;
  @override
  State<BlockCode> createState() => _BlockCodeState();
}

class _BlockCodeState extends State<BlockCode> {
  late final WebViewController _web = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..addJavaScriptChannel('Motolii', onMessageReceived: _told)
    ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) => _web.runJavaScript('motoliiLoad(${_kept()})${_log ? '; motoliiLog()' : ''}')))
    ..loadFlutterAsset('assets/blocks/expression_blocks.html');

  // (what the page is given, on stderr beside the window's own (MainFlutterWindow.swift InputLog), when asked)
  static final _log = Platform.environment['MOTOLII_INPUT_LOG'] == '1';

  @override
  void initState() {
    super.initState();
    if (_web.platform case final WebKitWebViewController web when kDebugMode) web.setInspectable(true);   // (Safari's Develop menu reaches it)
  }

  String _kept() {   // (as a JavaScript value; a kept workspace that is not JSON is as none)
    try {
      return jsonEncode(jsonDecode(widget.state ?? 'null'));
    } catch (_) {
      return 'null';
    }
  }

  void _told(JavaScriptMessage m) {
    final said = jsonDecode(m.message) as Map<String, dynamic>;
    if (said['say'] case final String say) return stderr.writeln('page $say');
    widget.changed(jsonEncode(said['state']), said['code'] as String);
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _web);
}
