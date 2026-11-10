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
// every layer has, as After Effects' Properties panel keeps Layer Transform at
// the top for all layer types. Then Alight Motion's Opacity and Blending, which
// is how the layer lies on what is under it. Then the cards of each kind of
// layer, such as Text and Paragraph or Shape Properties.
inline const DocCard doc_cards[] = {
    // After Effects' Transform group: where the layer is, how large, how turned
    // and how visible.
    // Each is a property of its own.
    {"Transform",
     "space parent anchor_x anchor_y anchor_z x y z scale_x scale_y scale_z "
     "rotate_x rotate_y rotate opacity",
     "kind", "!camera"},
    // After Effects' camera: where it is, how it is turned and how far its eye
    // is from what it
    // looks at.
    {"Camera", "parent x y z rotate_x rotate_y rotate distance", "kind",
     "camera"},
    // After Effects' Camera Options: Zoom, Focus Distance and Aperture.
    {"Camera Options", "zoom focus aperture", "kind", "camera"},
    // After Effects' layer mode and track matte in their simplest form: the
    // layer is drawn over
    // what lies below as the mode says, or only inside the layer before it.
    {"Blending", "blend clip"},
    // After Effects' Source Text and Character panels and Cavalry's Text shape:
    // what the text says,
    // its font, its size and its alignment.
    // Shown for text without being asked, as Alight Motion keeps Edit Text
    // among a text's tiles (see LayerTools.kt in engine/third_party/
    // AbsentMotion). Slant, wrapping the lines in a box or setting them down
    // the page, and splitting into letters or words that each have their own
    // expression sit with the rest of the text, as After Effects' Character and
    // Paragraph panels do.
    {"Text",
     "text file size letter_spacing line_spacing align split italic wrap "
     "wrap_at",
     "kind", "text"},
    // After Effects' Polystar: the number of points and how far in between them
    // the star goes.
    {"Star", "points inner", "shape", "star"},
    {"Polygon", "points", "shape", "polygon"},
    // After Effects' Fill and Stroke and Cavalry's Fill and Stroke: a color,
    // colors along a
    // gradient, or the glass material, plus the stroke and its width. A text
    // has more outlines, each outside the last, drawn with the text (Alight
    // Motion's Border): they stand in the text's depth, unlike Multi-Border's,
    // which sit on its image.
    {"Fill",
     "fill fill_media stroke stroke_width stroke_2 stroke_2_width stroke_3 "
     "stroke_3_width"},
    {"Gradient", "gradient gradient_angle gradient_scale gradient_spread",
     nullptr, nullptr, true},
    // There is no Copies card. The number of copies and the copies' own values
    // are on the card of
    // the first expression, see doc_cards_of, as After Effects' Repeater keeps
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
    // Where in its file a video starts, as Premiere Pro's Slip. A number typed
    // here works like
    // dragging in the timeline, whose pale bar shows the same value.
    {"Source", "begin", "kind", "video"},
    // Volume, and the beats that the timeline's ruler shows where the sound
    // strikes.
    {"Sound", "volume beats", "kind", "video"},
    {"Matte", "clip_matte clip_invert clip_feather", "clip", "1"},
    // Alight Motion's Parenting Helper: how much of its parent's rotation and
    // size the layer takes,
    // and rolling like a wheel. Shown while the layer has a parent.
    {"Parent", "parent_rotate parent_size roll roll_radius", "parent", "!0"},
    // A group's re-timing, kept with it as an element: how it plays when it is
    // put in a longer or
    // shorter place, as Alight Motion's Element settings Re-timing and its
    // marks.
    {"Element", "retime retime_in retime_out", "shape", "null"},
    {"Connect", "connect connect_to connect_reach", nullptr, nullptr, true},
    // The shapes of the open ends of a line, as Cavalry's heads and Alight
    // Motion's line start and
    // end.
    {"Line", "cap join dash dash_offset heads head_shape head_start head_size",
     nullptr, nullptr, true},
    // The path is rebuilt: After Effects' shape operators, as ThorVG provides
    // them.
    {"Path", "round bloat offset zigzag zigzag_ridges zigzag_smooth", "kind",
     "shape", true},
    // A photo's rectangle, as Alight Motion's Edit Shape and AbsentMotion's
    // Shape Options: cut in
    // from its sides, what is left stays where it was, and the corners are
    // rounded. It is drawn as
    // a rectangle that its file fills, see doc_match.
    {"Edit Shape", "crop_left crop_top crop_right crop_bottom round", "kind",
     "image"},
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
    {"Projection", "projection shift_x shift_y"},
    {"Room", "room environment environment_rotate behind background"},
    // A behaviour written as a file: its own parameters come under it, as a
    // script's do.
    {"Relation", "strength", "file", "relate"},
    // Any behaviour with a file. A behaviour shows only such cards, see
    // doc_cards_of.
    {"Falloff", "region falloff_soft falloff_invert", "file", "!"},
    // After Effects' shape operator, added from the shelf.
    {"Trim Paths", "trim trim_begin trim_offset", nullptr, nullptr, true},
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
