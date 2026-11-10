// Reads the parameters of a script of any dialect: an AviUtl2 script's by its
// adapter, a sketch's as its lines that draw, a three.js scene's as its part,
// and for the rest the header lines, which leva's object form is turned into.
#include "community/script_runner/script_parameters.h"

#include <filesystem>
#include <fstream>
#include <istream>
#include <sstream>
#include <string>
#include <vector>

#include "community/aviutl/aviutl.h"
#include "community/quickjs/script.h"
#include "community/quickjs/script_leva.h"
#include "community/sites/adapter.h"
#include "community/three/solid_three.h"

namespace motolii {

std::vector<ScriptParameter> script_parameters(const std::string& file) {
  if (aviutl_is(file))
    return aviutl_parameters(file);  // (an AviUtl2 script's head: aviutl.cpp)
  std::vector<ScriptParameter> parameters;
  std::ifstream in(file);
  std::stringstream told_head;
  std::istream* from = &in;
  if (std::filesystem::path(file).extension() == ".js") {
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
                      // document/scripts/adapter.h)
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
    in.clear(), in.seekg(0);
    if (const std::string head = leva_head(all.str()); !head.empty())
      told_head.str(head),
          from = &told_head;  // (leva's object at its top: script_leva.h)
  }
  return script_header_parameters(*from);
}

}  // namespace motolii
