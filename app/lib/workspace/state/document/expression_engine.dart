// The questions the Code tab asks of a running expression: what it gives at the playhead, which names of the reference
// it runs, and what its runtime adds. The engine answers; the panels show the answers.
import 'dart:convert';

import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/storage/disk.dart' show modifiedOf;
import 'package:motolii/workspace/code/expression_reference.dart'
    show expressionReference, runsHere, runtimeAdds;
import 'package:motolii/workspace/state/workspace_controller.dart';

final _asked = <String, Future<Map<String, String>?>>{};

/// What the running expression of the code file [file] has of the reference (`Layer.wiggle` to `bare` or `member`),
/// asked once for each time the file is written; null for code that is not an After Effects expression. The Functions
/// list and the editor's completion both read it, so they cannot disagree.
Future<Map<String, String>?> supportedIn(WorkspaceController ws, String file) {
  final key = '$file ${modifiedOf(file)?.microsecondsSinceEpoch ?? 0}';
  return _asked[key] ??= ws.inside!
      .askScript(file, runsHere(expressionReference))
      .then(
        (said) => said.isEmpty
            ? null
            : {
                for (final e
                    in (jsonDecode(said) as Map<String, dynamic>).entries)
                  e.key: e.value as String,
              },
      );
}

/// What [supportedIn] and the runtime's own functions say of [file], asked together: the reference's names that run,
/// and the functions JSON-encoded, or '' for a script that is not an After Effects expression.
Future<(Map<String, String>?, String)> askFunctions(
  WorkspaceController ws,
  String file,
) async {
  final said = await Future.wait([
    supportedIn(ws, file),
    ws.inside!.askScript(file, runtimeAdds),
  ]);
  return (said[0] as Map<String, String>?, said[1] as String);
}

/// What the expression of [file] gave at [ms] milliseconds, or its last error, as JSON; '' for none.
Future<String> expressionAt(
  WorkspaceController ws,
  String file,
  int ms,
) => ws.inside!.askScript(
  file,
  '(() => { const a = globalThis.__ae_at, v = a && a.get($ms), l = globalThis.__ae_last; '
  // (NaN and Infinity as JavaScript writes them, as a console shows them: JSON would make them null)
  'return JSON.stringify(v || (l && l.error ? l : null), '
  '(k, x) => typeof x === "number" && !isFinite(x) ? String(x) : x); })()',
);

/// Has the engine read the code file [file] again, as it does when the file was written outside the app (the engine
/// looks at a file's time only when told): [then] hears whether it runs, and why not.
void readCodeFile(
  WorkspaceController ws,
  String file,
  void Function(bool done, String why) then,
) {
  final m = ws.inside;
  if (m == null) return;
  ws.after(m.later('code', word: file), then);
}
