#ifndef MOTOLII_COMMUNITY_AFTER_EFFECTS_AE_EXPR_H_
#define MOTOLII_COMMUNITY_AFTER_EFFECTS_AE_EXPR_H_

// The After Effects expression runtime: its JavaScript lives beside acorn as
// engine/third_party/js/ae/ae_prelude.js. community/script_runner/script_runner.cpp
// evaluates that file into a QuickJS-ng context when a script uses AE.compile,
// after loading acorn (third_party/js/acorn/acorn.js).
//
// The engine's only role here is to hand the JS runtime the easing solver as
// `__bezier` (community/script_runner/script_natives.cpp bezier_ease, the same
// solver as motion/easing_curves.h) and to read the two .js files from disk.
// Everything the expression does — compile, run, vector arithmetic, random,
// wiggle, ease, loopIn/Out, the Prop and Layer wrappers — is in ae_prelude.js.
//
// Usage from a script (inside ae_prelude.js):
//   const f = AE.compile(`...an expression as it was posted...`);
//   AE.run(f, { index, time, value, comp, layer, effect })
//   AE.comp({ width, height, numLayers },
//           [{ name, index, width, height, position: (t) => [x, y], controls }])
//   AE.layer(spec) and AE.name("X Offset") → "X_Offset"
//
// Supported, not supported, and the random-sequence caveat are described at
// the top of ae_prelude.js.

#endif  // MOTOLII_COMMUNITY_AFTER_EFFECTS_AE_EXPR_H_
