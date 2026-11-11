#ifndef MOTOLII_COMMUNITY_SITES_ADAPTER_H_
#define MOTOLII_COMMUNITY_SITES_ADAPTER_H_

// Adapters for code found on the net. They detect which site a pasted program
// was written for and turn it into something the engine runs without the user
// changing the code. JavaScript becomes a p5.js sketch running on the p5.js
// canvas (community/p5/p5_stand.h). A shader becomes an ISF effect
// (community/isf/isf.cpp). Information taken from the page, such as the
// libraries it needs, goes in a comment line before the code, so the sketch's
// own lines stay as they were (sketch_marked in community/quickjs/script.h).
// Each form follows its site's own conventions:
//   Dwitter: the variables c, x, S, C, T, R and the function u(t), called 60
//   times a second on a
//     white 1920 x 1080 canvas (dwitter/templates/dweet/dweet.html in the
//     Dwitter repository).
//   tixy.land: the variables t, i, x, y and with(Math), on a 16 x 16 grid drawn
//   in white or red. Turtletoy: walk(i), from the turtletoy package on npm.
//   Two.js and Paper.js: their own canvas renderers.
//   Shadertoy: mainImage and its uniforms.
//   GLSL Sandbox: the time and resolution uniforms.
//   twigl: the variables r m t f s b and FC (src/fragmen.js in the twigl
//   repository). Bonzomatic: fGlobalTime, v2Resolution and out_color, from its
//   default shader.
//   Subtitles and lyrics (ASS, SRT, LRC, WebVTT and the rest): what FFmpeg's
//   probe reads as subtitles, drawn by libass (community/subtitles).
//   CSS animations, as a CodePen pen's CSS: @keyframes and no JavaScript. They
//   move the letters of a text layer (community/css).

#include <filesystem>
#include <functional>
#include <string>
#include <vector>

namespace motolii {

// Returns true if `t` contains `word`.
inline bool adapter_has(const std::string& t, const char* word) {
  return t.find(word) != std::string::npos;
}

// Returns the display name of a form, as shown on the Program shelf chips and
// used in the names of program files. A form with no known name is returned as
// it is.
std::string adapter_name(const std::string& form);
// Detects the form of pasted code. Returns "" for ISF, a p5.js sketch, one of
// our own presets, or text that is not code. Otherwise returns one of:
// shadertoy, sandbox, hydra, three, two, turtle, paper, canvas, bonzomatic,
// twigl, dweet, tixy, subtitles, css, after_effects.
std::string adapter_form(const std::string& t);

// Returns the library a form runs on, as a path under third_party/js, or "" if
// it needs none.
std::string adapter_library(const std::string& form);

// Extracts the code from a whole HTML page that was copied. Returns the
// contents of its inline <script> tags, and the libraries the page loads are
// handled as the form's library. `beside` is the directory holding the saved
// page's own script files. A script loaded from the net, other than the p5.js
// and three.js ones bundled here, is passed to `fetched`, which returns a file
// name. That name is written as a "//! needs" line above the code, because a
// library is not part of the sketch's own lines (Script in script_runner.h
// reads that line). Returns `t` unchanged if the page has no usable scripts.
std::string adapter_page(
    const std::string& t, const std::filesystem::path& beside = {},
    const std::function<std::string(const std::string&)>& fetched = {});
// Reads back the "//! needs" lines that adapter_page wrote at the top of
// `text`. Returns the file names in order.
std::vector<std::string> adapter_needs(const std::string& text);

// Replaces each p5.js loadShader call with a createShader call holding the
// source of the two files found in `beside`. The saved sketch is a single file
// and a script cannot fetch files, so the shader source is embedded. A call
// whose files are missing or empty is left as it is.
std::string adapter_shader_files(const std::string& text,
                                 const std::filesystem::path& beside);

// Copies the files a sketch loads by name (its pictures with loadImage, its
// data with loadTable, loadJSON, loadStrings, loadXML, loadBytes, fetch or
// d3's csv, tsv, json and text) from `beside` to a folder next to `saved`,
// named after it, because a script has no files of its own (see `beside` in
// media/video_frames_for_scripts.h). Missing files are skipped.
void adapter_files(const std::string& text, const std::filesystem::path& beside,
                   const std::filesystem::path& saved);

// Returns library source in a form a script can run. For three.js, the export
// list of its ES module is rewritten into one globalThis.THREE object, the way
// three.min.js exposed its names. Other forms are returned as they are.
std::string adapter_library_text(const std::string& form, std::string text);

// Wraps a JavaScript form as a p5.js sketch, keeping the source's lines where
// they were. Returns the source as it is for any other form.
std::string adapter_js(const std::string& src, const std::string& form);

// Converts shader code to an ISF effect, expressing what the shader asks of its
// site in ISF terms. A shader that reads iChannel takes the image of the layer
// it is applied to, whether that is a video or anything else. Returns `text`
// unchanged for any other form.
std::string adapter_isf(const std::string& text);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_SITES_ADAPTER_H_
