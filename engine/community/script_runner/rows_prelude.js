var __was = {};
function __relate() {   // (a file's relate(); a file written for copies, with each(i, n, t, k), runs on layers too: layer n of the row is copy n, and what each() says goes on top of where the layer is as it does on a copy, places and turns added, size and opacity multiplied: document/scripts/expressions.cpp)
  if (typeof relate === 'function') return relate;
  return (things, t, k) => things.map((a, n) => {
    const e = each(n, things.length, t, k, a) || {}, add = name => a[name] + (+e[name] || 0), times = name => a[name] * (e[name] === undefined ? 1 : +e[name]);
    return { i: a.i, x: add('x'), y: add('y'), z: add('z'), rotate: add('rotate'), rotate_x: add('rotate_x'), rotate_y: add('rotate_y'), size: times('size'), opacity: times('opacity') };
  });
}
function __copies_by_relate(n, t, k, laid) {   // (a relation's relate() on the copies of one layer: the copies laid so far are its things, as layers are a relation's; it says where each goes, and what goes back is the change, places and turns added, size and opacity multiplied, as each() says it: the way round of __relate())
  const names = ['x', 'y', 'z', 'size', 'rotate', 'rotate_x', 'rotate_y', 'opacity'], many = names.length, by = [];
  const things = [];
  for (let i = 0; i < n; ++i) { const o = { i, w: 0, h: 0, id: 0, near: 1, from: { x: NaN, y: NaN } }; names.forEach((name, j) => o[name] = laid[i * many + j]); things.push(o); }
  (relate(things, t, k) || things).forEach((o, m) => by[o && o.i !== undefined ? o.i : m] = o);
  const out = new Float64Array(many * n);
  for (let i = 0; i < n; ++i) names.forEach((name, j) => {
    const was = laid[i * many + j], is = by[i] && by[i][name], to = typeof is === 'number' && isFinite(is) ? is : was;
    out[i * many + j] = name === 'size' || name === 'opacity' ? (was ? to / was : 1) : to - was;
  });
  return out;
}
function __relates(all, t, k, rel, frame, awake) {   // (a relation written as a file: its relate() told all its things at once, document/evaluate/relations.h; what it leaves out stays as it was. Its Falloff weighs what it says, as Cavalry's does a Behaviour's Strength; one that remembers is told it as near and weighs it itself, as MASH's Python node reads getFalloff)
  const names = ['x', 'y', 'z', 'size', 'rotate', 'rotate_x', 'rotate_y', 'opacity'], many = names.length, by = [], relate = __relate(), solves = relate.length > 3, cached = __was[rel] = __was[rel] || [];
  const things = all.map((v, i) => { const o = { i, w: v[many], h: v[many + 1], id: v[many + 2], near: v[many + 3], from: { x: v[many + 4], y: v[many + 5] } }; names.forEach((n, j) => o[n] = v[j]); return o; });   // (from: x and y where it showed when it joined, NaN where that is not known)
  if (awake) ((solves ? relate(things, t, k, (frame && cached[frame - 1]) || null) : relate(things, t, k)) || things).forEach((o, n) => by[o && o.i !== undefined ? o.i : n] = o);
  if (solves) cached[frame] = awake ? by : null;
  const out = new Float64Array(many * all.length);
  all.forEach((v, i) => names.forEach((n, j) => { const is = by[i] && by[i][n], to = typeof is === 'number' && isFinite(is) ? is : v[j]; out[i * many + j] = solves ? to : v[j] + (to - v[j]) * v[many + 3]; }));
  return out;
}
function __forces(all, t, k, rel, frame, awake) {   // (a relation that pushes: its force() told its things as d3-force tells a force its nodes, each where it is and how fast; what it adds to their speed the world weighs and adds up, document/evaluate/world.h. What else it writes on a thing it finds there the next frame, as a particle's attributes, not to be changed for what is cached)
  const names = ['x', 'y', 'z', 'size', 'rotate', 'rotate_x', 'rotate_y', 'opacity', 'vx', 'vy', 'vz'], many = names.length, cached = __was[rel] = __was[rel] || [], had = frame && cached[frame - 1];
  const things = all.map((v, i) => { const o = Object.assign({}, had && had[i], { i, index: i, w: v[many], h: v[many + 1], id: v[many + 2], near: v[many + 3], home: { x: v[many + 4], y: v[many + 5], z: v[many + 6] } }); names.forEach((n, j) => o[n] = v[j]); return o; });
  if (awake) force(things, t, k);
  cached[frame] = things;
  const out = new Float64Array(many * all.length);
  all.forEach((v, i) => names.forEach((n, j) => { const is = things[i][n]; out[i * many + j] = typeof is === 'number' && isFinite(is) ? is : v[j]; }));
  return out;
}
function __asleep(rel, frame) { (__was[rel] = __was[rel] || [])[frame] = null; return new Float64Array(1); }
