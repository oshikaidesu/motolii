// Reads the parameters of a script of any dialect: an AviUtl2 script's by its
// adapter, a sketch's as its lines that draw, a three.js scene's as its part,
// and for the rest the header lines, which leva's object form is turned into.
#include "community/script_runner/script_parameters.h"

#include <cctype>
#include <filesystem>
#include <fstream>
#include <istream>
#include <regex>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "community/after_effects_plugin/ae_plugin.h"
#include "community/aviutl/aviutl.h"
#include "community/quickjs/script.h"
#include "community/quickjs/script_leva.h"
#include "community/quickjs/wgsl_attributes.h"
#include "community/sites/site_adapter.h"
#include "community/three/solid_three.h"

namespace motolii {

namespace {

// Turns a human-readable name into a snake_case identifier that fits
// ScriptParameter::name (which the inspector uses as a key).
std::string snake_name(const std::string& human) {
  std::string n = human;
  for (char& c : n)
    c = std::isalnum(static_cast<unsigned char>(c))
            ? static_cast<char>(std::tolower(static_cast<unsigned char>(c)))
            : '_';
  return n;
}

// Pulls every CSS custom property declaration (`--name: 2s;`, `--name: 10px;`)
// out of `css` and emits one track parameter per unique property that has
// a numeric default. CSS units (s, ms, px, %, deg, rem, em) are read but
// dropped; the slider sees the number. Range defaults to [0, max(1, 2*value)]
// so the user can push the value up or down from where the pen started it.
// The parameter's label is `--name`, which is what the user sees in the CSS.
void append_css_variable_params(const std::string& css,
                                std::vector<ScriptParameter>& out) {
  // Match `--name: <number><unit?>` (ignore gradient / calc / var() uses).
  static const std::regex varRe{
      R"(--([A-Za-z][\w-]*)\s*:\s*(-?\d+(?:\.\d+)?)\s*(ms|s|px|%|deg|rem|em)?\b)"};
  std::set<std::string> seen;
  for (std::sregex_iterator it(css.begin(), css.end(), varRe), end; it != end;
       ++it) {
    const std::string cssName = it->str(1);
    if (!seen.insert(cssName).second) continue;
    const double value = std::stod(it->str(2));
    const std::string unit = it->str(3);
    const double unitScale = unit == "ms" ? 0.001 : 1.0;  // slider in seconds
    const double seed = value * unitScale;
    ScriptParameter p;
    p.kind = "track";
    p.name = snake_name(cssName);
    p.label = "--" + cssName;
    p.low = std::min(0.0, seed);
    p.high = std::max(1.0, std::abs(seed) * 2.0);
    p.usual = seed;
    p.step = 0;
    // Remember the unit so doc_css_lay can write the slider's value back
    // into the pen with the same unit the author used. 'ms' is folded to
    // seconds here, so the unit stored is 's' instead.
    p.unit = unit == "ms" ? std::string("s") : unit;
    out.push_back(std::move(p));
  }
}

// Pulls every `effect("Name Control")("Slider")` reference out of each
// AE.compile(`...`) call in `js` and emits one track parameter per unique
// control. The parameter's name is a snake_case form of the effect name;
// the label is the effect name as pasted. Range defaults to 0..1 so the
// user can set it on the card; After Effects' own Slider control also
// starts at 0..1.
void append_ae_expression_params(const std::string& js,
                                 std::vector<ScriptParameter>& out) {
  // The expression source is quoted with backticks in recipes
  // (AE.compile(`...`)). This keeps the regex simple and matches the
  // existing ae_ease_test / sample_image_test shape.
  const std::regex compileRe{R"(AE\.compile\(\s*`([^`]*)`)"};
  const std::regex effectRe{
      R"(effect\(\s*["']([^"']+)["']\s*\)\s*\(\s*["']([^"']+)["']\s*\))"};
  std::set<std::string> seen;
  for (std::sregex_iterator it(js.begin(), js.end(), compileRe), end; it != end;
       ++it) {
    const std::string inside = it->str(1);
    for (std::sregex_iterator ex(inside.begin(), inside.end(), effectRe),
         ex_end;
         ex != ex_end; ++ex) {
      const std::string effectName = ex->str(1);
      const std::string propName = ex->str(2);
      const std::string key = effectName + "/" + propName;
      if (!seen.insert(key).second) continue;
      ScriptParameter p;
      p.kind = "track";
      p.name = snake_name(effectName);
      p.label = effectName;
      p.low = 0;
      p.high = 1;
      p.usual = 0;
      p.step = 0;
      out.push_back(std::move(p));
    }
  }
}

}  // namespace

std::vector<ScriptParameter> script_parameters(const std::string& file) {
  if (aviutl_is(file))
    return aviutl_parameters(file);  // (an AviUtl2 script's head: aviutl.cpp)
  if (ae_plugin_is(file)) return ae_plugin_parameters(file);
  std::vector<ScriptParameter> parameters;
  std::ifstream in(file);
  std::stringstream told_head;
  std::istream* from = &in;
  const std::string ext = std::filesystem::path(file).extension().generic_string();
  if (ext == ".wgsl") {
    std::stringstream wgsl_all;
    wgsl_all << in.rdbuf();
    const std::string wgsl_src = wgsl_all.str();
    std::istringstream wgsl_head(wgsl_src);
    auto headerParams = script_header_parameters(wgsl_head);
    parameters.insert(parameters.end(), headerParams.begin(), headerParams.end());
    auto attrParams = wgsl_attribute_parameters(wgsl_src);
    parameters.insert(parameters.end(), attrParams.begin(), attrParams.end());
    return parameters;
  }
  if (ext == ".js") {
    std::stringstream all;
    all << in.rdbuf();
    const std::string told = adapter_js(
        all.str(),
        adapter_form(
            all.str()));  // (a form from the net told as a sketch: adapter.h)
    if (script_is_sketch(told) &&
        told.find("function relate") == std::string::npos &&
        !script_pushes(told) &&
        !solid_is(file)) {  // (a relation is p5's too, but its head says its
                            // parameters; a solid's shape says THREE. too, but
                            // is no scene from the net: its head says its
                            // parameters, solid_three.h)
      if (adapter_form(all.str()) ==
          "three") {  // (which part of the scene this thing is:
                      // document/scripts/import_adapter.h)
        ScriptParameter part;
        part.kind = "track", part.name = "part", part.label = "Part",
        part.high = 9999, part.step = 1;
        return {part};
      }
      std::vector<SketchLine> lines;
      sketch_marked(told, &lines);
      for (const SketchLine& l : lines) {
        ScriptParameter k;
        k.kind = "track", k.name = "line_" + std::to_string(l.line),
        k.label = l.what + " " + std::to_string(l.line), k.high = 1,
        k.usual = 1;
        parameters.push_back(k);
      }
      return parameters;
    }
    // A recipe that holds After Effects expressions: harvest its free
    // effect() references so the user can drive them from the card.
    if (all.str().find("AE.compile") != std::string::npos) {
      append_ae_expression_params(all.str(), parameters);
    }
    // A CSS pen's custom properties (`--duration: 2s`) become sliders too,
    // so the user can retime or resize what the pen does without editing
    // the CSS text.
    if (adapter_form(all.str()) == "css") {
      append_css_variable_params(all.str(), parameters);
    }
    in.clear(), in.seekg(0);
    if (const std::string head = leva_head(all.str()); !head.empty())
      told_head.str(head),
          from = &told_head;  // (leva's object at its top: script_leva.h)
  }
  auto headerParams = script_header_parameters(*from);
  parameters.insert(parameters.end(), headerParams.begin(), headerParams.end());
  return parameters;
}

}  // namespace motolii
