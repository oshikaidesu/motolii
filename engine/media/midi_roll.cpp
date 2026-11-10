// Renders a MIDI file as a piano roll in SVG.
//
// The SVG is produced by bladeSk's PianoRollSvg.js, used unmodified
// (third_party/midi_roll, MIT) and run in QuickJS the way three_isf.cpp runs
// three.js. The script's MIDI parser (midi-parser-js) is GPL-3 and is not
// included. Instead the script receives the notes that GStreamer's midiparse
// element reads (see midi_notes.h) in the shape MidiParser.parse returns:
// timeDivision, formatType, and track[].event[] with deltaTime, type (9 for
// note on, 8 for note off), channel and data.
//
// The look follows ALMaMPlayer (github.com/almam72/ALMAMPlayer; only its
// numbers are used). The whole song is one row, 300 points per second
// (GlobalVariables.speed). The row height is 688 divided by the range of the
// notes (main_interface.gd). Notes are 18 points high with round ends, as in
// note_texture.png (20 x 18). Each note is a rectangle whose rx is half its
// height, drawn inset from its edge by a stroke in the background color.
// Insetting a round-ended bar still gives a round-ended bar. Notes are colored
// on a black background.
#include "media/midi_roll.h"

#include <quickjs.h>
#include <thorvg.h>

#include <cmath>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <sstream>

#include "media/midi_notes.h"

// Renders `file` as SVG text; see midi_roll.h for the parameters.
std::string midi_roll(const std::string& file, double bpm, std::string& why,
                      std::string* notes) {
  std::vector<MidiEvent> events = midi_events(file.c_str());
  if (events.empty()) return why = "no notes in " + file, "";
  // Factor that rescales times to play the file's beats at the requested tempo;
  // see midi_notes.h.
  const double by = bpm > 0 ? midi_bpm(file.c_str()) / bpm : 1.0;
  // The song in midi-parser-js form. One tick is one millisecond: timeDivision
  // is 1000 ticks per "beat" of one second.
  std::ostringstream song;
  song << "{\"timeDivision\":1000,\"formatType\":0,\"track\":[{\"event\":[";
  double was = 0, end = 0;
  for (size_t i = 0; i < events.size(); ++i) {
    const MidiEvent& e = events[i];
    const double at = std::round(e.at * by * 1000.0);
    song << (i ? "," : "") << "{\"deltaTime\":" << (at - was)
         << ",\"type\":" << (e.on ? 9 : 8) << ",\"channel\":" << e.channel
         << ",\"data\":[" << e.pitch << "," << (e.on ? e.velocity : 0) << "]}";
    was = at, end = std::max(end, at);
  }
  song << "]}]}";
  const int seconds = (int)std::ceil(end / 1000.0) + 1;
  // spacing is the row height as ALMaMPlayer computes it. A note is 18 points
  // high inside the row, and inset is the stroke width that fills the rest with
  // the background color.
  const double spacing = midi_spacing(events),
               inset = std::max(0.0, spacing - 18.0);
  std::ifstream in(std::filesystem::path(__FILE__).parent_path() /
                   "third_party/midi_roll/PianoRollSvg.js");
  std::stringstream source;
  source << in.rdbuf();
  if (source.str().empty()) return why = "PianoRollSvg.js is not there", "";
  const std::string run =
      "var module = { exports: {} };\nvar MidiParser = { parse: () => (" +
      song.str() + ") };\n" + source.str() +
      "\nvar roll = new module.exports('');\nglobalThis.__said = roll.render({ "
      "barsPerRow: " +
      std::to_string(seconds) +
      ", barSubdivisions: 1, timeDivision: 1000, width: " +
      std::to_string(seconds * 300) +
      ", lineHeight: " + std::to_string(spacing) +
      ", staggered: false, removeShorterThan: 0, tracksToRender: "
      "Object.fromEntries([...Array(16).keys()].map(i => [i, true])) });\n"
      // The script's own notes in the order it draws them: the rows of render()
      // and their notes, as in _renderContent.
      "globalThis.__notes = "
      "roll._sliceTrackToRows(roll._trimTrack(roll._getMergedTracks()))."
      "flatMap(r => r.notes).map(n => n.note + ' ' + n.velOn + ' ' + n.time + "
      "' ' + n.duration).join('\\n');\n";
  JSRuntime* rt = JS_NewRuntime();
  JSContext* cx = JS_NewContext(rt);
  std::string out;
  JSValue ran = JS_Eval(cx, run.c_str(), run.size(), "<PianoRollSvg>",
                        JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(ran)) {
    JSValue e = JS_GetException(cx);
    const char* s = JS_ToCString(cx, e);
    why = std::string("PianoRollSvg.js: ") + (s ? s : "?");
    JS_FreeCString(cx, s), JS_FreeValue(cx, e);
  } else {
    JSValue g = JS_GetGlobalObject(cx), s = JS_GetPropertyStr(cx, g, "__said");
    if (const char* c = JS_ToCString(cx, s)) out = c, JS_FreeCString(cx, c);
    JSValue n = JS_GetPropertyStr(cx, g, "__notes");
    if (const char* c = JS_ToCString(cx, n); c && notes)
      *notes = c, JS_FreeCString(cx, c);
    else if (c)
      JS_FreeCString(cx, c);
    JS_FreeValue(cx, n), JS_FreeValue(cx, s), JS_FreeValue(cx, g);
  }
  JS_FreeValue(cx, ran);
  JS_FreeContext(cx), JS_FreeRuntime(rt);
  if (out.empty())
    return why.empty() ? why = "PianoRollSvg.js returned nothing" : why, "";
  // Apply the ALMaMPlayer look as a stylesheet inserted after the script's own
  // one. ThorVG applies a <style> only to elements after it and lets the later
  // rule win, as CSS does. The round ends are set as each note's rx attribute
  // below because ThorVG's CSS does not read rx.
  const std::string look =
      "<style>.line { display: none; } .blackRow { display: none; } "
      ".octaveText { display: none; } "
      ".note { fill: #ed9e85; stroke: #000; stroke-width: " +
      std::to_string(inset) +
      "; } .note_black { fill: #ed9e85; stroke: #000; stroke-width: " +
      std::to_string(inset) + "; }</style>";
  if (const size_t at = out.find("</style>"); at != std::string::npos)
    out.insert(at + 8, look);
  // Give each note an id in drawing order; midi_roll_notes reads the notes back
  // by these ids.
  int i = 0;
  for (size_t at = 0;
       (at = out.find("<rect class=\"note", at)) != std::string::npos; at += 6)
    out.insert(at + 5, " id=\"note" + std::to_string(i++) + "\" rx=\"" +
                           std::to_string(0.5 * spacing) + "\"");
  return out;
}

// The cache file name is a hash of what goes in, as video_datamosh.h names its
// videos.
std::string midi_roll_file(const std::string& file, double bpm,
                           std::string& why) {
  std::string key = file + "|" + std::to_string(bpm);
  std::error_code e;
  if (auto at = std::filesystem::last_write_time(file, e); !e)
    key += "|" + std::to_string((long long)at.time_since_epoch().count());
  uint64_t hash = 1469598103934665603ull;
  for (unsigned char c : key) hash = (hash ^ c) * 1099511628211ull;
  const char* home = std::getenv("HOME");
  const std::filesystem::path dir =
      std::filesystem::path(home ? home : "/tmp") /
      "Library/Caches/Motolii/midi";
  char name[40];
  std::snprintf(name, sizeof name, "%016llx.svg", (unsigned long long)hash);
  const std::string out = (dir / name).string();
  if (std::filesystem::exists(out, e) &&
      std::filesystem::exists(
          std::filesystem::path(out).replace_extension(".notes"), e))
    return out;
  std::string notes;
  const std::string svg = midi_roll(file, bpm, why, &notes);
  if (svg.empty()) return "";
  std::filesystem::create_directories(dir, e);
  std::ofstream(out) << svg;
  // Store bladeSk's own notes, in drawing order, in a .notes file beside the
  // SVG.
  std::ofstream(std::filesystem::path(out).replace_extension(".notes"))
      << notes;
  return out;
}

// Reads the size with ThorVG, in points of the roll at 300 points per second.
bool midi_roll_box(const std::string& svg, double& w, double& h) {
  static const bool started = tvg::Initializer::init(0) == tvg::Result::Success;
  tvg::Picture* p = tvg::Picture::gen();
  float fw = 0.f, fh = 0.f;
  const bool read = started && p->load(svg.c_str()) == tvg::Result::Success &&
                    p->size(&fw, &fh) == tvg::Result::Success && fw > 0.f &&
                    fh > 0.f;
  tvg::Paint::rel(p);
  return read && (w = fw, h = fh, true);
}

// Rectangles come from the SVG; pitch, velocity and timing come from the .notes
// file beside it.
std::vector<MidiRollNote> midi_roll_notes(const std::string& svg) {
  std::ifstream in(svg);
  std::stringstream all;
  all << in.rdbuf();
  const std::string text = all.str();
  std::vector<MidiRollNote> notes;
  std::ifstream said(std::filesystem::path(svg).replace_extension(".notes"));
  const auto number = [&](size_t from, const char* name) {
    const size_t at = text.find(name, from);
    return at == std::string::npos
               ? 0.0
               : std::atof(text.c_str() + at + std::strlen(name));
  };
  for (size_t at = 0; (at = text.find("id=\"note", at)) != std::string::npos;
       ++at) {
    MidiRollNote n;
    n.x = number(at, " x=\""), n.y = number(at, " y=\""),
    n.high = number(at, " height=\"");
    // bladeSk's time and duration, in ticks of one millisecond each; see
    // midi_roll.
    double time = 0, length = 0;
    said >> n.pitch >> n.velocity >> time >> length;
    n.on = time / 1000.0, n.off = (time + length) / 1000.0;
    notes.push_back(n);
  }
  return notes;
}
