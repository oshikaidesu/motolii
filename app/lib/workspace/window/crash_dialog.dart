// Shows a dialog when the previous session crashed, with the crash report.
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/storage/disk.dart' show existsFile;
import 'package:motolii/storage/open_in_host.dart' show openInHost;
import 'package:motolii/storage/shelf_disk.dart' show deleteFile;
import 'package:motolii/storage/text_file.dart' show readTextNow;
import 'package:motolii/workspace/state/help_readme.dart'
    show crashLogsFolder, issueReportUrl;

String get _crashReportPath => '${crashLogsFolder()}/crash_report.txt';

/// Checks for a crash report and shows a dialog if one exists.
Future<void> showCrashDialogIfNeeded(BuildContext context) async {
  final path = _crashReportPath;
  if (!existsFile(path)) return;
  final report = readTextNow(path);
  if (report.trim().isEmpty) {
    deleteFile(path);
    return;
  }
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'crash report',
    barrierColor: Grey.g00.withValues(alpha: 0.65),
    pageBuilder: (context, a1, a2) => Center(
      child: _CrashDialog(report: report, path: path),
    ),
  );
}

class _CrashDialog extends StatelessWidget {
  const _CrashDialog({required this.report, required this.path});
  final String report;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 560,
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: Grey.g10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Grey.g20, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '前回クラッシュしました',
              style: TextStyle(
                color: Grey.g95,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Text(
                  report,
                  style: TextStyle(
                    color: Grey.g56,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _button('コピー', () {
                  Clipboard.setData(ClipboardData(text: report));
                }),
                const SizedBox(width: 8),
                _button('問題を報告', () {
                  Clipboard.setData(ClipboardData(text: report));
                  openInHost(issueReportUrl);
                }),
                const SizedBox(width: 8),
                _button('閉じる', () {
                  deleteFile(path);
                  Navigator.of(context).pop();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed) => GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Grey.g13,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: Grey.g95, fontSize: 12)),
    ),
  );
}
