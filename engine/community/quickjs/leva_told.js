(function (all) {
  var lines = [];
  function digits(x) { var n = Math.abs(+String(x).replace('.', '')); if (n === 0) return 0.01; while (n !== 0 && n % 10 === 0) n /= 10;
    return Math.max(Math.pow(10, Math.floor(Math.log10(Math.abs(x))) - (Math.floor(Math.log(n) / Math.LN10) + 1)), 0.001); }   // (leva's utils/math.ts getStep)
  function stepOf(v, min, max, step) {   // (leva's plugins/Number/number-plugin.ts normalize)
    if (!step) {
      if (isFinite(min)) step = isFinite(max) ? +(Math.abs(max - min) / 100).toPrecision(1) : +(Math.abs(v - min) / 100).toPrecision(1);
      else if (isFinite(max)) step = +(Math.abs(max - v) / 100).toPrecision(1);
    }
    return step || digits(v) / 10;
  }
  function nice(name) {   // (a key shown as Godot's inspector shows a property: String::capitalize, core/string/ustring.cpp)
    var up = function (c) { return c !== c.toLowerCase(); }, low = function (c) { return c !== c.toUpperCase(); }, digit = function (c) { return c >= '0' && c <= '9'; };
    var out = '', start = 0;
    for (var i = 1; i < name.length; i++) {   // (_separate_compound_words: aA, AAa, 2Aa, 2aa, A2, a2)
      var p = name[i - 1], c = name[i], next = name[i + 1] || '';
      if ((low(p) && up(c)) || ((up(p) || digit(p)) && up(c) && low(next)) || (digit(p) && low(c) && low(next)) || ((up(p) || low(p)) && digit(c)))
        out += name.substring(start, i) + ' ', start = i;
    }
    out = (out + name.substring(start)).replace(/[\s_-]/g, ' ').toLowerCase().trim();
    return out.split(' ').filter(function (w) { return w.length > 0; }).map(function (w) { return w[0].toUpperCase() + w.substring(1); }).join(' ');
  }
  function one(name, v, fold) {
    if (v && v.__folder) {
      lines.push('// --group:' + name);
      for (var n in v.schema) one(n, v.schema[n], name);
      lines.push(fold ? '// --group:' + fold : '// --group');
      return;
    }
    var s = v !== null && typeof v === 'object' && !Array.isArray(v) ? v : { value: v }, x = s.value, label = s.label || nice(name);   // (leva's own label: as written)
    if (s.options) {
      var words = Array.isArray(s.options) ? s.options.slice() : Object.keys(s.options).map(function (k) { return s.options[k]; });
      var at = words.indexOf(x);
      if (at > 0) words.unshift(words.splice(at, 1)[0]);   // (as it comes: the head's first word)
      lines.push('// --select@' + name + ':' + label + ',' + words.join(','));
    } else if (typeof x === 'boolean') lines.push('// --check@' + name + ':' + label + ',' + (x ? 1 : 0));
    else if (typeof x === 'string' && /^#[0-9a-f]{6}$/i.test(x))
      ['r', 'g', 'b'].forEach(function (c, i) { lines.push('// --track@' + name + '_' + 'xyz'[i] + ':' + label + ' ' + c + ',0,1,' + parseInt(x.substr(1 + 2 * i, 2), 16) / 255 + ',0.001'); });
    else if (typeof x === 'number') {
      var lo = typeof s.min === 'number' ? s.min : typeof s.max === 'number' ? Math.min(s.max - 10, x) : Math.min(0, x);
      var hi = typeof s.max === 'number' ? s.max : Math.max(lo + 10, x);
      lines.push('// --track@' + name + ':' + label + ',' + lo + ',' + hi + ',' + x + ',' + stepOf(x, s.min, s.max, s.step));
    }
  }
  for (var n in all) one(n, all[n], '');
  return lines.join('\n');
})
