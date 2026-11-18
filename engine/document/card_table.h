#ifndef MOTOLII_DOCUMENT_CARD_TABLE_H_
#define MOTOLII_DOCUMENT_CARD_TABLE_H_
// card_table.h: the cards a layer's properties are grouped in.

#include <string>

namespace motolii {

// The cards a user sees a layer's values on, besides where the layer is and its
// fill: a title and the values on it, in the order shown. A layer is shown
// those of them its kind has. A value that the window has no other place for
// goes here. The card is shown only while the property named by `when` reads
// one of the words of `is`, space separated; a leading "!" means none of them,
// and "!" alone means the property is set (doc_cards_of). added: the card is
// shown only once one of its values is set or keyed, or the user asked for it
// with More. It is not one of the tiles Alight Motion shows for the kind.
// later: this card and the cards after it are the optional features, which go
// below the cards of the layer's effects.
struct DocCard {
  const char* title;
  const char* names;
  const char* when = nullptr;
  const char* is = nullptr;
  bool added = false;
  bool later = false;
};

// Each entry is a card with a title and the space separated properties it
// shows. The order is the order of the cards. First come the properties that
// every layer has
// the top for all layer types. Then Alight Motion's Opacity and Blending, which
// is how the layer lies on what is under it. Then the cards of each kind of
// layer, such as Text and Paragraph or Shape Properties.
inline const DocCard doc_cards[] = {
    // After Effects' Transform group: where the layer is, how large, how turned
    // and how visible.
    // Each is a property of its own.
    // Shown for every placed kind, the camera included; the engine keeps only
    // the properties that kind has, so a camera sees just parent, position and
    // rotation here (no anchor, scale or opacity), and its lens stays on the
    // Camera card below.
    {"Transform",
     "space parent anchor_x anchor_y anchor_z x y z scale_x scale_y scale_z "
     "rotate_x rotate_y rotate opacity"},
    // After Effects' camera lens. Where the camera is and how it is turned live
    // on the Transform card above, like every other placed layer.
    {"Camera",
     "focal_length projection shift_x shift_y focus aperture blur_level",
     "kind", "camera"},
    // After Effects' layer mode and track matte in their simplest form: the
    // layer is drawn over
    // what lies below as the mode says, or only inside the layer before it.
    {"Blending", "blend clip clip_matte clip_invert clip_feather"},
    // After Effects' Source Text and Character panels and Cavalry's Text shape:
    // what the text says,
    // its font, its size and its alignment.
    // Shown for text without being asked
    // among a text's tiles (see LayerTools.kt in engine/third_party/
    // AbsentMotion). Slant, wrapping the lines in a box or setting them down
    // the page, and splitting into letters or words that each have their own
    // expression sit with the rest of the text
    // Paragraph panels do.
    {"Text",
     "text text_styles file size letter_spacing line_spacing align split "
     "italic wrap wrap_at",
     "kind", "text"},
    // After Effects' Fill and Stroke and Cavalry's Fill and Stroke: a color,
    // colors along a
    // gradient, or the glass material, plus the stroke and its width. A text
    // has more outlines, each outside the last, drawn with the text (Alight
    // Motion's Border): they stand in the text's depth, unlike Multi-Border's,
    // which sit on its image.
    {"Fill",
     "fill fill_media gradient gradient_angle gradient_scale gradient_spread "
     "stroke stroke_width"},
    // There is no Copies card. The number of copies and the copies' own values
    // are on the card of
    // the first expression, see doc_cards_of
    // its Copies, Offset
    // and Transform (Start and End Opacity) inside it.
    // A flat layer lit from within. Above 1 the canvas's bloom picks it up
    // where the layer lies in
    // the canvas's own view. A flat layer laid over a solid layer is clear
    // around it and keeps no
    // halo, because ThorVG's glow does that.
    {"Shine", "emissive", "kind", "!solid", true, true},
    // Playback of the layer. The frame rate of the canvas itself is set in the
    // size box.
    {"Play", "marker animation speed speed_hold frame_rate", "kind", "!stage",
     true},
    // A program's own time, for a program that paints a flat image and for one
    // that has a body, see
    // doc_own_time.
    {"Time Remap", "time_remap time_remap_loop", nullptr, nullptr, true},
    // The drawings of an animation level: an image that has a drawing is one.
    {"Drawing", "cel", "cel", "!0"},
    // After Effects' shape operators, as ThorVG provides them, plus Polystar's
    // own points: the number of corners and how far in the star goes. Trim is
    // here too, for drawing a line along the path.
    {"Paths",
     "points inner round bloat offset zigzag zigzag_ridges zigzag_smooth "
     "trim trim_offset morph morph_to morph_steps "
     "resample rough rough_detail fill_rule trail trail_length",
     "kind", "text shape image"},
    // Where in its file a video starts, how loud it is
    // heard and exported, and the beats the timeline's ruler marks.
    {"Media", "begin volume beats", "kind", "video"},
    // Alight Motion's Parenting Helper: how much of its parent's rotation and
    // size the layer takes,
    // and rolling like a wheel. Shown while the layer has a parent.
    {"Parent", "parent_rotate parent_size roll roll_radius", "parent", "!0"},
    // A group's re-timing, kept with it as an element: how it plays when it is
    // put in a longer or
    // shorter place
    // marks.
    {"Element", "retime retime_in retime_out", "shape", "null"},
    {"Connect", "connect connect_to connect_reach", nullptr, nullptr, true},
    // The shapes of the open ends of a line
    // Motion's line start and
    // end.
    {"Line", "cap join dash dash_gap dash_offset heads head_shape head_start "
             "head_size",
     nullptr, nullptr, true},
    // Cut the layer in from its sides; what is left stays where it was, as
    // Alight Motion's crop. Any placed layer is cut, by Filament's scissor on
    // its own box (evaluate_clipping); a photo is cut to a rectangle its file
    // fills, see doc_match, so its rounded corners (round, on the Paths card)
    // follow the cut.
    {"Crop", "crop_left crop_top crop_right crop_bottom"},
    {"Bevel", "bevel bevel_depth bevel_color bevel_metallic bevel_roughness",
     nullptr, nullptr, true},
    // After Effects' Side and Back Color: the other faces of a thick layer.
    {"Side",
     "side_color side_metallic side_roughness back_color back_metallic "
     "back_roughness",
     nullptr, nullptr, true},
    // The material a layer wears and its own parameters: Create's Material
    // group. There is a card
    // for each material, shown for that material, see doc_material.
    {"Surface",
     "shading metallic roughness reflectance clear_coat clear_coat_roughness "
     "sheen anisotropy thickness emissive",
     "shading", "lit cloth subsurface", true},
    {"Glass", "shading ior dispersion swim dark vivid", "shading",
     "glass filament_glass"},
    {"Lacquer", "shading metallic", "shading", "lacquer"},
    {"Bubble", "shading vivid", "shading", "bubble"},
    // Which lights reach the layer.
    {"Lit", "light_group", "kind", "solid", true},
    {"Light",
     "intensity falloff cone shadows shadow_softness contact_shadows "
     "light_group sun_size sun_halo",
     "kind", "light"},
    {"Room", "room environment environment_rotate behind background"},
    // A behaviour written as a file: its own parameters come under it, as a
    // script's do.
    {"Relation", "strength", "file", "relate"},
    // Any behaviour with a file. A behaviour shows only such cards, see
    // doc_cards_of.
    {"Falloff", "region falloff_soft falloff_invert", "file", "!"},
    // The compressed images of a video, see media/video_datamosh.h.
    {"Datamosh", "mosh_with mosh_at", nullptr, nullptr, true},
    // A point cloud's own, see stage/render/point_cloud.h.
    {"Points", "dissolve grain", nullptr, nullptr, true},
};
// Returns true if `one` is a whole word of the space separated list `words`.
inline bool doc_among(const std::string& words, const std::string& one) {
  return (" " + words + " ").find(" " + one + " ") != std::string::npos;
}

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_CARD_TABLE_H_
