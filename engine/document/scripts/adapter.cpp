#include "document/scripts/adapter.h"

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <ios>
#include <map>
#include <sstream>
#include <system_error>
#include <utility>
#include <vector>

#include "community/hydra/hydra_isf.h"
#include "community/isf/isf.h"
#include "community/p5/adapter_p5_shader.h"
#include "community/quickjs/script.h"
#include "community/script_runner/script_runner.h"
#include "community/sites/adapter.h"
#include "community/sites/adapter_net.h"
#include "community/sites/adapter_shadertoy_json.h"
#include "document/edit/arrange.h"
#include "document/edit/fx_put.h"
#include "document/edit/keys_put.h"
#include "document/edit/layer_edit.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/match.h"
#include "document/scripts/recipes.h"
#include "document/scripts/scripts.h"
#include "document/undo.h"
#include "shelf/shelf_folders.h"

namespace {

// Writes the animated parameters of imported code as keyframes on the layer
// that carries the effect `fx`, so that the user can edit them. A straight line
// needs only two keyframes; any other motion gets one keyframe per sample,
// HYDRA_STEP seconds apart.
void doc_door_keys(Doc& d, int layer, const std::string& fx,
                   const std::vector<HydraParameter>& moving) {
  for (const HydraParameter& k : moving) {
    const std::string name = doc_screen_parameter(fx, k.name);
    if (adapter_line(k.keys))
      doc_key(d, layer, name.c_str(), 0, k.keys[0]),
          doc_key(d, layer, name.c_str(), ADAPTER_LINE_ENDS,
                  adapter_line_end(k.keys));
    else
      for (size_t i = 0; i < k.keys.size(); ++i)
        doc_key(d, layer, name.c_str(), (double)i * HYDRA_STEP, k.keys[i]);
  }
}

// Extracts the shader of a p5.js sketch as an effect stored beside the sketch,
// as a .fs file and a .vs file. Returns the text of the .fs file. Returns an
// empty string when the sketch has no usable shader; `why` is then set if the
// sketch has a shader that cannot be used.
std::string doc_p5_shaded(const std::filesystem::path& file,
                          std::vector<HydraParameter>& moving,
                          std::string& why) {
  Script run(file.string(),
             (doc_engine("third_party/js/p5") / "p5.min.js").string());
  const std::string got = run.said("__shaded_take(30)");
  std::string fs, vs;
  if (!run.ok()) return why = run.trouble(), "";
  if (got.empty() || !adapter_p5_shader(got, fs, vs, moving, why)) return "";
  std::ofstream(std::filesystem::path(file).replace_extension(".fs")) << fs;
  std::ofstream(std::filesystem::path(file).replace_extension(".vs")) << vs;
  return fs;
}

// Creates or updates one part of a three.js scene as a solid layer. The mesh is
// written as a .glb file beside the script, the material comes from the scene,
// and the layer is placed where the scene places the part. The layer's js_part
// property holds `p`, so that the script can find its part again (see
// __three_each in community/p5/p5_stand.h). Passing `solid` as 0 creates a new
// layer; otherwise that layer is updated. Returns the layer, or 0 on failure.
int doc_three_part(Doc& d, Script& run, const std::filesystem::path& file,
                   int p, int solid) {
  const std::vector<uint8_t> shape =
      run.bytes("__three_glb(" + std::to_string(p) + ")");
  const std::filesystem::path glb =
      file.parent_path() /
      (file.stem().string() + "-" + std::to_string(p) + ".glb");
  std::ofstream out(glb, std::ios::binary);
  out.write((const char*)shape.data(), (std::streamsize)shape.size());
  out.close();
  // The scene reports four values for the part: the number of copies, the fill
  // color, and the metallic and roughness of its material.
  std::istringstream says(run.said("__three_says(" + std::to_string(p) + ")"));
  int most = 1;
  double metal = 0, rough = 1;
  std::string colour;
  says >> most >> colour >> metal >> rough;
  if (!solid && !(solid = doc_add(d, "solid", glb.string().c_str()))) return 0;
  doc_say(d, solid, "fill", colour.c_str());
  doc_set(d, solid, "metallic", metal), doc_set(d, solid, "roughness", rough),
      doc_set(d, solid, "copies", std::min(most, 1000));
  doc_say(d, solid, "script", file.string().c_str()),
      doc_set(d, solid, "js_part", p);
  return solid;
}

// Called when the code of a three.js scene is saved. Rebuilds its parts so that
// there is one solid layer for each mesh in the scene as it is now. Existing
// layers stay in their groups, new parts are added, and layers whose part no
// longer exists are removed. Returns the reason the code cannot run, or an
// empty string.
std::string doc_three_saved(Doc& d, const std::filesystem::path& file) {
  Script run(file.string(),
             (doc_engine("third_party/js/p5") / "p5.min.js").string());
  const int parts = std::atoi(run.said("__three_parts()").c_str());
  if (!run.ok()) return run.trouble();
  if (!parts) return "this three.js scene drew no meshes";
  // The layers made from this script, grouped by their parent layer; 0 means no
  // parent.
  std::map<int, std::vector<int>> stood;
  std::vector<int> gone;
  for (const int t : doc_layers(d))
    if (doc_word(d, t, "script") == file.string())
      stood[(int)doc_number(d, t, "parent", 0, 0)].push_back(t);
  doc_act(d);
  const bool together = d.act_together;
  d.act_together = true;
  for (const auto& [group, layers] : stood) {
    std::map<int, int> part;
    for (const int t : layers) part[(int)doc_number(d, t, "js_part", 0, 0)] = t;
    for (int p = 0; p < parts; ++p) {
      const int solid =
          doc_three_part(d, run, file, p, part.count(p) ? part[p] : 0);
      if (solid && !part.count(p) && group) doc_set(d, solid, "parent", group);
      part.erase(p);
    }
    for (const auto& [_, t] : part) gone.push_back(t);
  }
  for (const int t : gone) doc_remove(d, t);
  d.act_together = together;
  doc_acted(d);
  return "";
}

// Called when Hydra code is saved. Converts it to an ISF effect again and
// re-creates the keyframes of its animated parameters on every layer that uses
// the effect. Returns the reason the code cannot run, or an empty string.
std::string doc_hydra_saved(Doc& d, const std::filesystem::path& file,
                            const std::string& text) {
  std::string why, isf;
  std::vector<HydraParameter> moving;
  if (!hydra_isf(doc_folders("extensions/hydra").back().string(),
                 adapter_page(text), 30.0, isf, moving, why))
    return why;
  const std::string made =
      std::filesystem::path(file).replace_extension(".fs").string();
  std::ofstream(made) << isf;
  doc_act(d);
  for (const int t : doc_layers(d))
    if (doc_word(d, t, "fx").find(made) != std::string::npos)
      doc_door_keys(d, t, made, moving);
  doc_acted(d);
  return "";
}

// Called when the code of a p5.js sketch whose shader is an effect is saved.
// Extracts the effect again and re-creates its keyframes on every layer that
// uses it. Returns the reason the code cannot run, or an empty string.
std::string doc_p5_shaded_saved(Doc& d, const std::filesystem::path& file) {
  std::string why;
  std::vector<HydraParameter> moving;
  if (doc_p5_shaded(file, moving, why).empty()) return why;
  const std::string made =
      std::filesystem::path(file).replace_extension(".fs").string();
  doc_act(d);
  for (const int t : doc_layers(d))
    if (doc_word(d, t, "fx").find(made) != std::string::npos)
      doc_door_keys(d, t, made, moving);
  doc_acted(d);
  return "";
}

}  // namespace

int doc_door(Doc& d, const std::string& said, int picked) {
  std::string word = said, why;
  std::error_code wrong;
  // A link to an OpenProcessing sketch is downloaded first.
  if (const std::string work = adapter_site_work(said);
      !work.empty() &&
      (word =
           adapter_openprocessing(
               work, doc_folders("sites").back() / "openprocessing" / work, why)
               .string())
          .empty())
    return d.error = why, 0;
  std::string text = word;
  // If `word` is a short path of an existing file, read the code from it.
  // Otherwise `word` is the code.
  if (word.size() < 1024 && std::filesystem::is_regular_file(word, wrong)) {
    std::ifstream in(word);
    std::stringstream all;
    all << in.rdbuf();
    text = all.str();
  }
  const std::filesystem::path folder = doc_folders("programs").back();
  // True when the code is already a file in the Program shelf folder. It is
  // then used where it is and not stored again.
  const bool kept = std::filesystem::path(word).parent_path() == folder;
  // Libraries that the page loads: each file's name and the place it was
  // downloaded to.
  std::vector<std::pair<std::string, std::filesystem::path>> libraries;
  const std::filesystem::path brought = doc_folders("libraries").back();
  text = adapter_page(text,
                      text != word ? std::filesystem::path(word).parent_path()
                                   : std::filesystem::path{},
                      [&](const std::string& url) {
                        uint64_t mark = 1469598103934665603ull;
                        for (unsigned char c : url)
                          mark = (mark ^ c) * 1099511628211ull;
                        // A web address is not a usable file name, so the name
                        // is the FNV-1a hash of the address. Each address is
                        // downloaded once.
                        const std::string name =
                            std::to_string(mark & 0xffffff) + ".js";
                        std::filesystem::create_directories(brought, wrong);
                        if (!std::filesystem::exists(brought / name, wrong) &&
                            !adapter_fetch(url, brought / name))
                          return std::string();
                        libraries.push_back({name, brought / name});
                        return name;
                      });
  if (text != word)
    text =
        adapter_shader_files(text, std::filesystem::path(word).parent_path());
  const bool tabs = adapter_has(text, "\"renderpass\"");
  // A Shadertoy file with all its tabs is converted here to one ISF file, as
  // Hydra code is.
  if (tabs) {
    std::string why;
    if ((text = adapter_shadertoy(text, why)).empty()) return d.error = why, 0;
  }
  // `came` keeps the text as it arrived, before Hydra conversion. `told` is its
  // JavaScript form.
  const std::string came = text, form = tabs ? "shadertoy" : adapter_form(text),
                    told = adapter_js(text, form);
  const bool hydra = form == "hydra",
             shader = hydra || form == "shadertoy" || form == "sandbox" ||
                      form == "twigl" || form == "bonzomatic";
  std::vector<HydraParameter> moving;
  // Hydra code is converted to an ISF effect and stored in that form. The
  // converter is hydra_isf.cpp.
  if (hydra) {
    std::string why, isf;
    if (!hydra_isf(doc_folders("extensions/hydra").back().string(), text, 30.0,
                   isf, moving, why))
      return d.error = why, 0;
    text = isf;
  }
  if (!shader && !script_is_sketch(told))
    return d.error = "this is not code that Motolii can read", 0;
  // The FNV-1a hash of the text, as its last four hex digits, is added to the
  // file name so that different code gets a different file.
  uint64_t hash = 1469598103934665603ull;
  for (unsigned char c : text) hash = (hash ^ c) * 1099511628211ull;
  char tail[16];
  std::snprintf(tail, sizeof tail, "-%04llx",
                (unsigned long long)(hash & 0xffff));
  const std::string name = adapter_name(form);
  std::filesystem::create_directories(folder, wrong);
  std::filesystem::path file =
      folder / (name + tail + (shader ? ".fs" : ".js"));
  // Code that is already a file in the shelf folder is used as it is, except
  // Hydra code, which is stored converted. Other code is written to the shelf
  // folder unless that file already exists.
  if (kept && !hydra)
    file = word;
  else if (!std::filesystem::exists(file, wrong))
    std::ofstream(file) << text;
  // Images that the code loads are copied from the place it came from to beside
  // the stored file.
  if (word != came && !kept)
    adapter_images(text, std::filesystem::path(word).parent_path(), file);
  // The code needs its libraries beside it, as it needs its images.
  for (const auto& [name, from] : libraries) {
    const std::filesystem::path to = file.parent_path() / file.stem();
    std::filesystem::create_directories(to, wrong);
    std::filesystem::copy_file(
        from, to / name, std::filesystem::copy_options::skip_existing, wrong);
  }
  // The Hydra code as it was written is kept beside the converted effect. The
  // Program shelf shows this file.
  if (hydra)
    std::ofstream(file.parent_path() / (file.stem().string() + ".hydra"))
        << came;
  // A p5.js sketch that paints its canvas with a shader is imported as that
  // shader, an effect like any other, and not as an image of its output.
  std::string shaded;
  if (form.empty() && adapter_has(told, "hader(") &&
      (shaded = doc_p5_shaded(file, moving, why)).empty() && !why.empty())
    return d.error = why, 0;
  const std::string fx =
      shaded.empty()
          ? file.string()
          : std::filesystem::path(file).replace_extension(".fs").string();
  const bool effect = shader || !shaded.empty();
  // Begin the undo step.
  doc_act(d);
  int layer = 0;
  // An effect that reads an input image goes on the selected layer.
  if (effect &&
      adapter_has(shaded.empty() ? adapter_isf(text) : shaded, "inputImage") &&
      picked) {
    if (doc_fx_file(d, picked, fx.c_str(), d.stage->now)) layer = picked;
    // An effect that makes its own pixels becomes a rectangle layer stretched
    // over the canvas.
  } else if (effect) {
    if ((layer = doc_add(d, "shape", "rect")) &&
        doc_say(d, layer, "name", name.c_str()) &&
        doc_fx_file(d, layer, fx.c_str(), d.stage->now))
      doc_fit(d, layer, "stretch");
    // Each pair of a mesh and a material becomes a solid layer of its own,
    // under a group layer when there is more than one. The layers are placed in
    // the 3D world and are not a picture of it.
  } else if (form == "three") {
    Script run(file.string(),
               (doc_engine("third_party/js/p5") / "p5.min.js").string());
    const int parts = std::atoi(run.said("__three_parts()").c_str());
    if (!run.ok())
      return d.error = run.trouble(), d.act_ok = false, doc_acted(d), 0;
    if (!parts)
      return d.error = "this three.js scene drew no meshes", d.act_ok = false,
             doc_acted(d), 0;
    const bool together = d.act_together;
    // Rebuild the canvas (doc_match) once at the end. Otherwise each part is an
    // undo step of its own and each one rebuilds all the parts.
    d.act_together = true;
    if (parts > 1 && (layer = doc_add(d, "shape", "null")))
      doc_say(d, layer, "name", name.c_str());
    for (int p = 0; p < parts; ++p) {
      const int solid = doc_three_part(d, run, file, p, 0);
      if (!solid) break;
      if (!layer) layer = solid;
      doc_say(d, solid, "name", (name + " " + std::to_string(p + 1)).c_str());
      if (parts > 1) doc_set(d, solid, "parent", layer);
    }
    d.act_together = together;
    // A p5.js sketch in WEBGL mode becomes a cube solid that runs the script.
  } else if (told.find("WEBGL") != std::string::npos) {
    if ((layer = doc_add(d, "solid", "cube")))
      doc_say(d, layer, "name", name.c_str()),
          doc_say(d, layer, "script", file.string().c_str());
    // If the script failed on its first run, report that. A white box is not
    // what the sketch drew.
    if (DocScript* sc = layer ? doc_script_of(d, file.string()) : nullptr;
        sc && sc->run && !sc->run->ok())
      return d.error = sc->run->trouble(), d.act_ok = false, doc_acted(d), 0;
    // Any other p5.js sketch becomes an image layer fitted to the canvas.
  } else if ((layer = doc_add(d, "image", file.string().c_str())))
    doc_say(d, layer, "name", name.c_str()), doc_fit(d, layer, "fit");
  // What moves in the code becomes keyframes, so that it can be edited.
  if (layer && !moving.empty()) {
    doc_evaluate(d, d.stage->now);
    doc_door_keys(d, layer, fx, moving);
  }
  return doc_acted(d) ? layer : 0;
}

std::string doc_code_saved(Doc& d, const std::string& file) {
  std::string& why = doc_scripts_kept(d).why[file];
  std::error_code wrong;
  const long long stamp =
      (long long)std::filesystem::last_write_time(file, wrong)
          .time_since_epoch()
          .count();
  long long& seen = doc_scripts_kept(d).sketches[file].saved;
  const std::string ext = std::filesystem::path(file).extension().string();
  std::ifstream in(file);
  std::stringstream all;
  all << in.rdbuf();
  const bool three = ext == ".js" && adapter_form(all.str()) == "three";
  const bool shaded =
      ext == ".js" &&
      std::filesystem::exists(
          std::filesystem::path(file).replace_extension(".vs"), wrong);
  if (!wrong && stamp != seen) {
    seen = stamp, why.clear();
    if (ext == ".hydra")
      why = doc_hydra_saved(d, file, all.str());
    else if (three)
      why = doc_three_saved(d, file);
    else if (shaded)
      why = doc_p5_shaded_saved(d, file);
  }
  ++files_changed();
  doc_files_moved(d);
  if (ext == ".js" && !three && !shaded) doc_sketch_written(d, file);
  doc_match(d);
  // An ISF effect that is half typed keeps being drawn as it was last built,
  // and the reason is reported (see community/isf/isf.cpp). The reason is
  // stored here and not in `why`, because doc_match may have erased `why`. See
  // doc_script_of.
  if (ext == ".fs")
    isf_file(file), doc_scripts_kept(d).why[file] = isf_trouble(file);
  return doc_scripts_kept(d).why[file];
}
