#ifndef MOTOLII_COMMUNITY_P5_P5_STAND_H_
#define MOTOLII_COMMUNITY_P5_P5_STAND_H_

// p5.js with no page: a sketch from the net, its file as it is, run by p5.js
// itself (third_party/js/p5, 1.11.13, LGPL-2.1, its file as it is released) in
// the script's QuickJS, as Cavalry's and AviUtl's scripts are run by stand-ins
// for what they ask of their host. No browser and nothing drawn: what p5 draws
// in WEBGL is taken at drawBuffersScaled, the one adapter its box, plane,
// ellipsoid, cylinder, cone and torus all go through
// (src/webgl/p5.RendererGL.Retained.js), with its model matrix (uModelMatrix),
// and said as the copies of a thing. A frame once run is kept: a sketch only
// goes forward, so going back is reading. Frames are its own 60 a second, as
// requestAnimationFrame and a clock stepped by hand (timesnap's way).
//
// The stand-in JavaScript lives as three files in third_party/js/p5/stand/,
// loaded by community/script_runner/script_runner.cpp when a sketch runs:
//   p5_before.js   evaluated before p5.min.js (the page p5 expects)
//   p5_after.js    evaluated after p5.min.js and p5.sound (the canvas, media,
//                  light and shader adapters)
//   p5_start.js    appended to the sketch's own body so the sketch runs

#endif  // MOTOLII_COMMUNITY_P5_P5_STAND_H_
