import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';

const _kw = Color(0xFFCC7832);
const _builtIn = Color(0xFF6897BB);
const _str = Color(0xFF6A8759);
const _cmt = Color(0xFF808080);
const _fn = Color(0xFFFFC66D);
const _attr = Color(0xFFBBB529);
const _var = Color(0xFF9876AA);

final darkCodeStyles = <String, TextStyle>{
  'root': TextStyle(color: Grey.g91, backgroundColor: WindowTokens.well),
  'keyword': const TextStyle(color: _kw),
  'built_in': const TextStyle(color: _builtIn),
  'string': const TextStyle(color: _str),
  'number': const TextStyle(color: _builtIn),
  'comment': const TextStyle(color: _cmt),
  'class': const TextStyle(color: _fn),
  'function': const TextStyle(color: _fn),
  'params': TextStyle(color: Grey.g91),
  'attr': const TextStyle(color: _attr),
  'selector-tag': const TextStyle(color: _kw),
  'selector-class': const TextStyle(color: _fn),
  'attribute': const TextStyle(color: _attr),
  'variable': const TextStyle(color: _var),
  'title': const TextStyle(color: _fn),
  'type': const TextStyle(color: _builtIn),
  'literal': const TextStyle(color: _builtIn),
  'symbol': const TextStyle(color: _builtIn),
  'meta': const TextStyle(color: _attr),
};

const _lKw = Color(0xFFA626A4);
const _lBuiltIn = Color(0xFF0184BC);
const _lStr = Color(0xFF50A14F);
const _lNum = Color(0xFF986801);
const _lCmt = Color(0xFFA0A1A7);
const _lClass = Color(0xFFC18401);
const _lFn = Color(0xFF4078F2);
const _lTag = Color(0xFFE45649);

final lightCodeStyles = <String, TextStyle>{
  'root': TextStyle(color: Grey.g13, backgroundColor: WindowTokens.well),
  'keyword': const TextStyle(color: _lKw),
  'built_in': const TextStyle(color: _lBuiltIn),
  'string': const TextStyle(color: _lStr),
  'number': const TextStyle(color: _lNum),
  'comment': const TextStyle(color: _lCmt),
  'class': const TextStyle(color: _lClass),
  'function': const TextStyle(color: _lFn),
  'params': TextStyle(color: Grey.g13),
  'attr': const TextStyle(color: _lNum),
  'selector-tag': const TextStyle(color: _lTag),
  'selector-class': const TextStyle(color: _lClass),
  'attribute': const TextStyle(color: _lNum),
  'variable': const TextStyle(color: _lTag),
  'title': const TextStyle(color: _lFn),
  'type': const TextStyle(color: _lBuiltIn),
  'literal': const TextStyle(color: _lBuiltIn),
  'symbol': const TextStyle(color: _lBuiltIn),
  'meta': const TextStyle(color: _lNum),
};
