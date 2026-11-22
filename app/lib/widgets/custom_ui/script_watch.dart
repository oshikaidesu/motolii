// Shared error banner and hot-reload watcher re-export for JS Custom UI scripts
// (used by both Inspector Custom Cards and Dockable Custom Panels).
// 詳細: docs/design/custom_panels.md
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;

export 'package:motolii/storage/script_watch.dart' show ScriptFileWatcher;

/// Readable, non-crashing error banner for JS syntax/runtime errors in custom UI scripts.
class CustomUiErrorBanner extends StatelessWidget {
  const CustomUiErrorBanner({
    required this.error,
    this.fileLabel = '',
    this.onReload,
    super.key,
  });

  final String error;
  final String fileLabel;
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Shape.s(7)),
      decoration: BoxDecoration(
        color: InspectorSkin.well,
        borderRadius: Shape.round(5),
        border: Border.all(color: InspectorSkin.tonePlace),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fileLabel.isEmpty ? 'Custom UI error' : fileLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.name(InspectorSkin.tonePlace),
                ),
              ),
              if (onReload case final reload?)
                Pressable(
                  onTap: reload,
                  builder: (_, hot) => Text(
                    'Retry',
                    style: TextStyles.micro(hot ? Grey.g95 : Grey.g76),
                  ),
                ),
            ],
          ),
          SizedBox(height: Shape.s(3)),
          Text(
            error,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.micro(Grey.g91),
          ),
        ],
      ),
    );
  }
}
