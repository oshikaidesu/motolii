// A dialog closes the way a Mac or Windows dialog does: Esc, Cmd+. and a press on the scrim close it, and the keyboard focus goes back
// to where it was. The expected behaviour comes from those systems' dialogs. Needs no engine.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/widgets/modal_card.dart';

class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool open = false;
  final before = FocusNode();
  void show() => setState(() => open = true);
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Focus(focusNode: before, child: const SizedBox.expand()),
      if (open)
        ModalCard(
          title: 'Dialog',
          onClose: () => setState(() => open = false),
          children: const [Text('inside')],
        ),
    ],
  );
}

Widget _window() => WidgetsApp(
  color: const Color(0xFF000000),
  builder: (_, _) => const _Host(),
);

Future<_HostState> _opened(WidgetTester tester) async {
  await tester.pumpWidget(_window());
  final host = tester.state<_HostState>(find.byType(_Host));
  host.before.requestFocus();
  await tester.pump();
  host.show();
  await tester.pumpAndSettle();
  return host;
}

void main() {
  testWidgets('Esc closes it and the focus goes back', (tester) async {
    final host = await _opened(tester);
    expect(find.text('inside'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('inside'), findsNothing);
    expect(host.before.hasPrimaryFocus, isTrue);
  });

  testWidgets('Cmd+. closes it', (tester) async {
    await _opened(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.period);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();
    expect(find.text('inside'), findsNothing);
  });

  testWidgets('a press on the scrim closes it', (tester) async {
    await _opened(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('inside'), findsNothing);
  });
}
