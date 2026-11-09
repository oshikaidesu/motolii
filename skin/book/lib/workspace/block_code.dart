// An Expression card's Block mode (fx_code.dart): Google's Blockly as it comes (npm blockly 13.4.0, Apache-2.0,
// assets/blocks/blockly/LICENSE), in the system's web view (webview_flutter: WKWebView on macOS). The page,
// assets/blocks/expression_blocks.html, is told the workspace kept (Blockly's own JSON) once it is up, and tells each
// change back on the Motolii channel as {state, code}: the workspace, and the each() Blockly's JavaScript generator
// writes from it. Going from code back to blocks is not done: the blocks are the source, the code is made from them.
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) => _web.runJavaScript('motoliiLoad(${_kept()})')))
    ..loadFlutterAsset('assets/blocks/expression_blocks.html');

  String _kept() {   // (as a JavaScript value; a kept workspace that is not JSON is as none)
    try {
      return jsonEncode(jsonDecode(widget.state ?? 'null'));
    } catch (_) {
      return 'null';
    }
  }

  void _told(JavaScriptMessage m) {
    final said = jsonDecode(m.message) as Map<String, dynamic>;
    widget.changed(jsonEncode(said['state']), said['code'] as String);
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _web);
}
