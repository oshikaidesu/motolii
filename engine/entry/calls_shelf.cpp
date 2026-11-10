// The calls about what the shelves offer: effects, create scripts, presets,
// animators, relations and cards, the layer kind a file makes, and whether a
// font sets a text.
#include "document/cards.h"
#include "document/edit/fx_put.h"
#include "document/edit/layer_edit.h"
#include "document/edit/presets.h"
#include "document/scripts/recipes.h"
#include "document/scripts/scripts.h"
#include "entry/calls.h"
#include "entry/on_render_thread.h"
#include "shelf/shelf_folders.h"
#include "stage/canvas/canvas_renderables.h"

using namespace motolii;

// Returns the names of the effects that can be added, separated by spaces.
const char* motolii_effect_names(Motolii* m) {
  return by_look(m, [m] { return (m->listed = doc_effect_names()).c_str(); });
}
// Returns one line per create script: name, a tab, and its description.
const char* motolii_create_scripts(Motolii* m) {
  return by_look(m, [=] { return (said_word() = doc_recipe_names()).c_str(); });
}
// Returns the names of the effect files followed by the names of the AviUtl2
// scripts, one per line.
const char* motolii_effects(Motolii* m) {
  return by_look(m, [=] {
    // The file types are .wgsl, .fs, .mjs, .js, .json and .am. A .json file
    // holds Filament's own settings, see viewer_settings.h. A .am file is an
    // AbsentMotion motion, see absent_motion.h.
    const std::string files = doc_folder_names("effects",
                                               ".wgsl .fs .mjs .js .json .am"),
                      aviutl = doc_aviutl_names();
    return (said_word() =
                files + (files.empty() || aviutl.empty() ? "" : "\n") + aviutl)
        .c_str();
  });
}
// Records that files on the shelves changed on disk.
void motolii_files_changed(void) { ++files_changed(); }
// Returns the names of the presets on the shelf.
const char* motolii_presets(Motolii* m) {
  return by_look(m, [=] { return (said_word() = doc_preset_names()).c_str(); });
}
// Returns the names of the expression files, separated by spaces.
const char* motolii_animators(Motolii* m) {
  return by_look(m, [=] {
    return (said_word() = doc_folder_names("expressions", ".js")).c_str();
  });
}
// Returns the names of the relation files, separated by spaces.
const char* motolii_relations(Motolii* m) {
  return by_look(m, [=] {
    return (said_word() = doc_folder_names("relations", ".js")).c_str();
  });
}
// Runs the create script `script`, which makes layers and values in one go.
// Returns nonzero on success.
int motolii_create(Motolii* m, const char* script) {
  return on_render_thread(m,
                          [=] { return changes(m, doc_make(doc(m), script)); });
}
// Returns the display settings of property `name` as tab-separated fields:
// look, unit, label, low, high, the group it folds into, and 1 if that group
// starts open. The line is empty if the property has none.
const char* motolii_shown(Motolii* m, const char* name) {
  return by_look(m, [=] {
    const DocShown* s = doc_shown_of(*m->d, name);
    char line[512] = "";
    if (s)
      std::snprintf(line, sizeof line, "%s\t%s\t%s\t%g\t%g\t%s\t%d", s->look,
                    s->unit, s->label, s->low, s->high, s->fold ? s->fold : "",
                    (int)s->open);
    return (said_word() = line).c_str();
  });
}
// Returns the effect cards of the layer as text.
const char* motolii_cards(Motolii* m, int layer) {
  return by_look(
      m, [=] { return (said_word() = doc_cards_of(*m->d, layer)).c_str(); });
}
// Returns the cards that exist but stay hidden until the user asks for them, in
// the same format.
const char* motolii_cards_more(Motolii* m, int layer) {
  return by_look(m, [=] {
    std::string more;
    doc_cards_of(*m->d, layer, &more);
    return (said_word() = more).c_str();
  });
}
// Returns the titles of the layer's effect cards in effect order, separated by
// semicolons.
const char* motolii_fx_titles(Motolii* m, int layer) {
  return by_look(
      m, [=] { return (said_word() = doc_fx_titles(*m->d, layer)).c_str(); });
}
// Returns the layer kind that a file makes, decided by the end of its name, or
// "" for none.
const char* motolii_kind_of(const char* file) { return doc_kind_of(file); }
// Returns 1 if ThorVG can set `words` in the font file, otherwise 0.
int motolii_sets(const char* font, const char* words) {
  return type_sets(font, words) ? 1 : 0;
}
// Returns "" if the font file has every letter of `words`. Otherwise returns
// the letters it lacks, a tab, and the fallback font that has them all, which
// can be empty.
const char* motolii_font_lacks(const char* font, const char* words) {
  thread_local std::string said;
  if (!font || !words) return "";
  const std::string lacks = type_lacks(font, words);
  said =
      lacks.empty() ? std::string() : lacks + "\t" + type_fallback(font, words);
  return said.c_str();
}
