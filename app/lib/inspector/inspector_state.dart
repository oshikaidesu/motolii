enum KeyframeState { off, anim, at }

enum Kind { shape, text, camera, group, none }

/// The property that a value belongs to. All values of one property share one key mark.
/// The document's x, y, z belong to position; scale_x to scale_z to scale; rotate_x, rotate_y and rotate to rotation; anchor_x to anchor_z to anchor.
String propOf(String id) =>
    _place.hasMatch(id) ? 'v_position' : _axis.firstMatch(id)?.group(1) ?? id;
// Compiled once because propOf runs hundreds of times for every frame.
final _place = RegExp(r'^v_[xyz]$'), _axis = RegExp(r'^(v_\w+?)_[xyz]$');
