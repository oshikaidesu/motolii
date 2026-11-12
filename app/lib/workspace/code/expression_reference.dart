// The After Effects expression reference the Code tab shows beside the code: every name with the line that says what
// it does and its arguments. It is read from the type declarations of the npm package expression-globals-typescript
// (MIT, Tim Haywood) as they are, engine/third_party/js/expression-globals-typescript/index.d.ts. Nothing of the
// reference is written here by hand.
//
// The reference says what an expression may name. Which of the names run here is asked of the engine's own runtime
// (runsHere below builds the question; Motolii.later 'ask' puts it to the file's running script), as a browser's
// console completes a name by looking at the object itself.
import 'dart:convert';
import 'dart:io';

import 'package:motolii/bridge/engine_paths.dart' show motoliiDir;

/// One name of the reference: a function or a value of [owner].
class ReferenceEntry {
  const ReferenceEntry(
    this.owner,
    this.name,
    this.signature,
    this.about,
    this.arguments,
    this.gives,
  );

  /// The class it is declared in, as After Effects names its objects: Layer, Property, Comp, Key…
  final String owner;
  final String name;

  /// How it is written: `wiggle(freq, amp, octaves?, amp_mult?, time?)`, or the bare name for a value.
  final String signature;

  /// What it does, in the reference's own words.
  final String about;

  /// Each argument with what the reference says of it.
  final List<(String, String)> arguments;

  /// The class of what it gives, when that is one of the reference's classes (Comp for `thisComp`), else ''.
  final String gives;

  /// Whether it is called with arguments.
  bool get calls => signature.contains('(');
}

/// The reference, read once. Empty if the file is not where it is kept.
final List<ReferenceEntry> expressionReference = () {
  final file = File(
    '$motoliiDir/third_party/js/expression-globals-typescript/index.d.ts',
  );
  return file.existsSync()
      ? readReference(file.readAsStringSync())
      : const <ReferenceEntry>[];
}();

final _class = RegExp(r'^export declare class (\w+)');
final _member = RegExp(
  r'^\s+(?:readonly\s+)?(\w+)(?:<[^(]*>)?(\(.*\))?\??:\s*(.*);$',
);

/// Reads the members of every class of a TypeScript declaration file [dts], each with the comment above it.
List<ReferenceEntry> readReference(String dts) {
  final out = <ReferenceEntry>[];
  final seen = <String>{};
  String? owner;
  var comment = <String>[];
  var inComment = false;
  for (final line in const LineSplitter().convert(dts)) {
    if (_class.firstMatch(line) case final c?) {
      owner = c[1];
      comment = [];
      continue;
    }
    if (line.startsWith('}')) owner = null;
    if (owner == null) continue;
    final text = line.trim();
    if (text.startsWith('/**')) {
      inComment = !text.endsWith('*/');
      comment = [
        text.replaceFirst('/**', '').replaceFirst(RegExp(r'\*/$'), '').trim(),
      ];
      continue;
    }
    if (inComment) {
      if (text.endsWith('*/')) inComment = false;
      comment.add(text.replaceFirst(RegExp(r'^\*/?\s?'), ''));
      continue;
    }
    final m = _member.firstMatch(line);
    // An overload is the same name again: the first is kept.
    if (m == null || m[1] == 'constructor' || !seen.add('$owner.${m[1]}')) {
      comment = [];
      continue;
    }
    final lines = [
      for (final l in comment)
        if (l.trim().isNotEmpty) l.trim(),
    ];
    final returns = lines
        .where((l) => l.startsWith('@returns'))
        .map((l) => l.replaceFirst(RegExp(r'^@returns?\s*'), ''))
        .firstOrNull;
    final about = lines.where((l) => !l.startsWith('@')).join(' ');
    out.add(
      ReferenceEntry(
        owner,
        m[1]!,
        m[2] == null ? m[1]! : '${m[1]}(${_arguments(m[2]!).join(', ')})',
        about.isNotEmpty
            ? about
            : returns == null
            ? ''
            : 'Gives ${returns.replaceFirst(RegExp(r'^[Tt]he '), 'the ')}',
        [
          for (final l in lines)
            if (RegExp(r'^@param\s+(\w+)\s*(.*)$').firstMatch(l) case final p?)
              (p[1]!, p[2]!),
        ],
        RegExp(r'^(\w+)').firstMatch(m[3]!)?[1] ?? '',
      ),
    );
    comment = [];
  }
  final classes = {for (final e in out) e.owner};
  return [
    for (final e in out)
      ReferenceEntry(
        e.owner,
        e.name,
        e.signature,
        e.about,
        e.arguments,
        classes.contains(e.gives) ? e.gives : '',
      ),
  ];
}

/// The names of the arguments in a declaration's parentheses, each with its `?` when it may be left out.
List<String> _arguments(String inParentheses) {
  final text = inParentheses.substring(1, inParentheses.length - 1);
  final parts = <String>[];
  var depth = 0, from = 0;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if ('(<[{'.contains(c)) depth++;
    if (')>]}'.contains(c)) depth--;
    if (c == ',' && depth == 0) {
      parts.add(text.substring(from, i));
      from = i + 1;
    }
  }
  if (text.trim().isNotEmpty) parts.add(text.substring(from));
  return [
    for (final p in parts)
      RegExp(r'^\s*(\.\.\.)?(\w+\??)').firstMatch(p)?[2] ?? p.trim(),
  ];
}

/// How an expression reaches each class of [reference], found by following what the reference says each name gives,
/// from the three things an expression is handed: `thisLayer` (Layer), `thisComp` (Comp) and `thisProperty` (Property).
/// A name that is called is called with 1, as `effect(1)` and `key(1)` are.
Map<String, String> referenceRoots(List<ReferenceEntry> reference) {
  final roots = {
    'Layer': 'thisLayer',
    'Comp': 'thisComp',
    'Property': 'thisProperty',
  };
  for (var grew = true; grew;) {
    grew = false;
    for (final e in reference) {
      final from = roots[e.owner];
      if (from == null || e.gives.isEmpty || roots.containsKey(e.gives)) {
        continue;
      }
      roots[e.gives] = '$from?.${e.name}${e.calls ? '?.(1)' : ''}';
      grew = true;
    }
  }
  return roots;
}

/// The JavaScript that asks a running After Effects expression which names of [reference] it has. Its answer is JSON,
/// `{"Layer.wiggle": "bare", "Layer.sampleImage": "member"}`: a name is `bare` when the expression can say it alone,
/// `member` when it is reached through its object, and left out when the runtime does not have it. The answer is ''
/// for a script that is not an After Effects expression.
///
/// The whole question is one expression compiled once by the runtime's own AE.compile, with `?.` between the steps so
/// that an object the runtime lacks answers `undefined` and stops nothing.
String runsHere(List<ReferenceEntry> reference) {
  final roots = referenceRoots(reference);
  // After Effects looks a bare name up on the property the expression is on, then on its layer
  // (ae-expressions.docsforadobe.dev), so only those two are tried bare.
  final asked = jsonEncode([
    for (final e in reference)
      if (roots[e.owner] case final root?) ...[
        if (e.owner == 'Layer' || e.owner == 'Property')
          ['${e.owner}.${e.name}', 'bare', e.name],
        ['${e.owner}.${e.name}', 'member', '$root?.${e.name}'],
      ],
  ]);
  return '''
(() => {
  if (typeof AE !== 'object' || !AE.compile) return '';
  const comp = AE.comp({ width: 1920, height: 1080 }, [{ name: 'Layer 1', index: 1, width: 100, height: 100,
    position: () => [0, 0, 0], rotation: () => 0, scale: () => [100, 100], opacity: () => 100, anchorPoint: () => [0, 0] }]);
  const layer = comp.layer(1);
  const c = { index: 1, time: 0, value: 0, comp, layer, effect: layer.effect, property: layer.position };
  const kind = (src) => { try { return AE.run(AE.compile(src), c); } catch (e) { return undefined; } };
  const asked = $asked, out = {};
  // All at once; a name the parser refuses is then tried by itself, so that it stops none of the others.
  const kinds = kind('[' + asked.map((a) => 'typeof (' + a[2] + ')').join(',') + ']')
    || asked.map((a) => kind('typeof (' + a[2] + ')') || 'undefined');
  asked.forEach((a, i) => { if (kinds[i] !== 'undefined' && !(a[0] in out)) out[a[0]] = a[1]; });
  return JSON.stringify(out);
})()''';
}

/// The JavaScript that asks any running script which functions its runtime adds to JavaScript's own. Its answer is
/// JSON, a list of names, in the order the runtime made them.
const String runtimeAdds = '''
(() => JSON.stringify(Object.getOwnPropertyNames(globalThis).filter((n) =>
  typeof __plain === 'object' && !__plain.includes(n) && !n.startsWith('__') && typeof globalThis[n] === 'function')))()''';
