// The pieces the InspectorSync tests share: one card, an owner that writes down what it is told, and a document started on it.
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/card_declaration.dart' show CardDeclaration;
import 'package:motolii/inspector/inspector_edits.dart';
import 'package:motolii/inspector/inspector_snapshot.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_sync.dart';
import 'package:motolii/inspector/inspector_values.dart';

// One card. Its fields: v_amount (default 4), v_mode (default 1) and v_x (default 0).
const syncCard = '''
struct First {
  amount: f32, // @range(0, 10) @default(4)
  mode: i32, // @enum(Low, Med, High) @default(1)
  x: f32,
}
''';

Color syncTone() => const Color(0xFF000000);

/// The owner of the values. It writes down everything it is told, in order; '{' and '}' are the ends of one undo step.
class SyncOwner {
  /// With [takesLater] it takes a step only when [takeStep] is called, as an owner on another thread does.
  SyncOwner({required bool hearsFlags, bool takesLater = false}) {
    edits = InspectorEdits(
      onValues: (changed, {required live}) =>
          told.add([live ? 'values, live' : 'values', Map.of(changed)]),
      onDrop: () => told.add('drop'),
      onKey: (prop, mark) => told.add(['key', prop, mark]),
      onWords: (changed, {required live}) {
        told.add(['words', Map.of(changed)]);
        return takesWords;
      },
      onFlags: hearsFlags
          ? (changed) {
              told.add(['flags', Map.of(changed)]);
              return takesFlags;
            }
          : null,
      onAnimateAll: (on) => told.add(['animate all', on]),
      together: (tells) {
        told.add('{');
        tells();
        told.add('}');
      },
      onRoute: (panel) => told.add(['route', panel]),
      onAim: (slot) => told.add(['aim', slot]),
      whenTaken: takesLater ? untaken.add : null,
    );
  }

  /// The steps told and not taken yet, oldest first.
  final untaken = <void Function()>[];

  /// Takes the oldest step not taken yet.
  void takeStep() => untaken.removeAt(0)();

  final told = <Object>[];
  bool takesWords = true, takesFlags = true;
  late final InspectorEdits edits;

  /// What it was told since the last call.
  List<Object> take() {
    final all = [...told];
    told.clear();
    return all;
  }
}

InspectorValues syncDoc() {
  final doc = InspectorValues(
    Kind.shape,
    cards: [CardDeclaration('First', syncCard, toneOf: syncTone)],
  );
  addTearDown(doc.dispose);
  return doc;
}

/// A document filled from [snapshot] whose every notification is reported to an owner, as the Inspector's host does.
(InspectorValues, InspectorSync, SyncOwner) syncStarted({
  InspectorSnapshot snapshot = const InspectorSnapshot(),
  bool hearsFlags = true,
  bool takesLater = false,
}) {
  final doc = syncDoc(),
      sync = InspectorSync()..start(doc, snapshot),
      owner = SyncOwner(hearsFlags: hearsFlags, takesLater: takesLater);
  doc.addListener(() => sync.report(doc, owner.edits));
  return (doc, sync, owner);
}

const syncNothing = InspectorSnapshot();
const syncAt = KeyframeState.at, syncAnim = KeyframeState.anim;
