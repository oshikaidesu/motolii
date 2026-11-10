#ifndef MOTOLII_DOCUMENT_EVALUATE_EVALUATE_H_
#define MOTOLII_DOCUMENT_EVALUATE_EVALUATE_H_

// evaluate.h: doc_evaluate, which updates the stage to the document's state at
// one time, and the helpers that decide how much room a layer's effects need
// and which properties force a layer to be rebuilt.

namespace motolii {

struct Doc;

// Brings the stage to the state the document has at time `now`. This covers the
// camera and lens, layer order and depth sorting, scenes, per-layer materials
// and copies, lights, clipping and the 3D layers of imported After Effects
// compositions.
//
// A text layer whose words no longer fit, or a cel layer whose drawing changed,
// is rebuilt with doc_match and evaluation stops there. Nothing in the document
// is modified.
void doc_evaluate(Doc& d, double now);

// Property names that decide how a layer is built, written as a quoted list for
// use in SQL. When one of them changes, the layer is rebuilt by doc_match.
// doc_carry uses the list too.
inline const char* const doc_making =
    "'kind','file','shape','path','blend','fx','fx_off','keyed','space','begin'"
    ",'duration','speed','text','fill','fill_media','fill_rule','wide','points'"
    ",'inner','round','crop_left','crop_top','crop_right','crop_bottom','bloat'"
    ",'zigzag','offset','warp','clip','stroke','stroke_width','stroke_2','"
    "stroke_2_width','stroke_3','stroke_3_width','align','copies','letter_"
    "spacing','line_spacing','italic','cap','join','heads','head_size','head_"
    "shape','head_start','dash','dash_offset','metallic','roughness','"
    "reflectance','clear_coat','clear_coat_roughness','falloff','shadows','"
    "shadow_softness','contact_shadows','sheen','anisotropy','shading','"
    "thickness','light_group','script','copy_fill','gradient','gradient_angle',"
    "'gradient_scale','gradient_spread','wrap','wrap_at','split','ior','"
    "dispersion','swim','dark','vivid','marker','mosh','mosh_with','mosh_at'";
// Property names of a flat layer's ThorVG effects, see doc_fx. These are
// evaluated again at each time with fx_at and never force a rebuild. Their only
// influence on building is which of them are on and how much room around the
// layer they need, see doc_fx_room.
inline const char* const doc_fxing =
    "'blur','shadow','shadow_distance','shadow_angle','shadow_blur','shadow_"
    "opacity','glow','glow_blur','glow_opacity','tint','tint_black','tint_"
    "white','tritone','tritone_shadow','tritone_midtone','tritone_highlight'";
// Returns how far a layer's effects reach beyond the layer at most, in document
// units, rounded up to a power of two. Returns 0 if none reach. The layer's
// canvas is made with this much room, so a number changed within it is redrawn
// without rebuilding the canvas, as a texture atlas keeps power-of-two room.
double doc_fx_room(Doc& d, int layer);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_EVALUATE_H_
