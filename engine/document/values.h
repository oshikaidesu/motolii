#ifndef MOTOLII_DOCUMENT_VALUES_H_
#define MOTOLII_DOCUMENT_VALUES_H_
// Lists every property a layer may have and how the inspector shows it.

namespace motolii {

// How a value is shown to the user. The app draws its control from this and has
// nothing of its own. look is one of: count (a whole number), onoff, angle,
// stage (a length of the stage, shown in points of the image), down (a length
// up the stage, shown downward as the image counts), share (0 to 1, shown in
// hundredths), colour, colours and numbers (words of those), words (any text,
// typed), file (a file, given from a shelf), layer (another layer), seed, or
// none (as its range specifies). unit is the unit the value is read in. label
// is a name in plain words. low and high are the span the control covers; the
// value itself may go further, as its range specifies. fold is the name of the
// fold it lies in on its card if it is folded away, named by what the fold
// holds. A card's first row holds at most eight, as on Ableton's Push.
struct DocShown {
  const char* name;
  const char* look;
  const char* unit;
  const char* label;
  double low, high;
  const char* fold;
  bool open = false;
};

// One entry per property. The fields of DocShown are: property name, kind of
// control, unit, label shown to the user, lowest and highest value of the
// slider, and the name of the fold the property is grouped under (nullptr for
// none). The slider range is for display only; typed values may go beyond it.
inline const DocShown doc_shown[] = {
    {"text", "words", "", "Text", 0, 0, nullptr},
    {"text_styles", "words", "", "Styles", 0, 0, nullptr},
    {"file", "file", "", "Font", 0, 0, nullptr},
    // An image that fills a shape, as in Alight Motion's Fill > Media. It is
    // chosen from the Fill button of the Media shelf.
    {"fill_media", "file", "", "Media", 0, 0, nullptr},
    {"size", "", "px", "Size", 0, 2, nullptr},
    {"align", "share", "%", "Align", 0, 1, nullptr},
    {"fill", "colours", "", "Fill", 0, 0, nullptr},
    {"stroke", "colour", "", "Stroke", 0, 0, nullptr},
    {"stroke_width", "", "px", "Stroke width", 0, 16, nullptr},
    {"stroke_2", "colour", "", "Stroke 2", 0, 0, nullptr},
    {"stroke_2_width", "", "px", "Width 2", 0, 40, nullptr},
    {"stroke_3", "colour", "", "Stroke 3", 0, 0, nullptr},
    {"stroke_3_width", "", "px", "Width 3", 0, 40, nullptr},
    {"split", "", "", "Split", 0, 0, nullptr},
    {"letter_spacing", "", "", "Tracking", -100, 500, nullptr},
    {"line_spacing", "", "×", "Line height", 0.5, 3, nullptr},
    {"italic", "", "°", "Slant", 0, 20, nullptr},
    {"wrap", "", "", "Wrap", 0, 0, nullptr},
    {"wrap_at", "", "×", "Wrap at", 0, 40, nullptr},
    {"gradient", "", "", "Gradient", 0, 0, nullptr},
    {"gradient_angle", "angle", "°", "Angle", -180, 180, nullptr},
    {"points", "count", "", "Points", 3, 32, nullptr},
    {"inner", "share", "%", "Inner radius", 0.05, 1, nullptr},
    {"round", "share", "%", "Round", 0, 0.5, nullptr},
    {"trim", "share", "%", "Trim end", 0, 1, nullptr},
    {"trim_begin", "share", "%", "Trim start", 0, 1, nullptr},
    {"trim_offset", "share", "%", "Trim offset", -1, 1, nullptr},
    {"bloat", "", "", "Bloat", -1, 1, nullptr},
    {"offset", "", "", "Offset", -0.5, 0.5, nullptr},
    {"zigzag", "", "", "Zig zag", -0.3, 0.3, nullptr},
    {"zigzag_ridges", "count", "", "Ridges", 0, 20, "Zig zag"},
    {"zigzag_smooth", "onoff", "", "Smooth", 0, 1, "Zig zag"},
    {"gradient_scale", "", "×", "Stretch", 0.1, 4, nullptr},
    {"gradient_spread", "", "", "Past end", 0, 0, nullptr},
    {"copies", "count", "", "How many", 1, 200, nullptr},
    {"stagger", "", "s", "Delay", 0, 3, "Copies"},
    {"copy_fill", "colours", "", "Colours", 0, 0, "Copies"},
    {"copy_opacity_end", "", "", "Last opacity", 0, 1, "Copies"},
    {"tall", "", "×", "Height", 0, 3, "Copies"},
    {"copy_tall", "numbers", "", "Heights", 0, 0, "Copies"},
    {"stagger_from", "", "", "From", 0, 0, "Copies"},
    {"copy_fill_way", "", "", "Order", 0, 0, "Copies"},
    // How much of a relation's effect applies.
    {"strength", "share", "%", "Strength", 0, 1, nullptr},
    // The shape inside which a behaviour or a relation works, like Cavalry's
    // Falloff.
    {"region", "thing", "", "Falloff", 0, 0, nullptr},
    {"falloff_soft", "stage", "px", "Soft", 0, 2, nullptr},
    {"falloff_invert", "onoff", "", "Invert", 0, 1, nullptr},
    {"seed", "seed", "", "Seed", 0, 9999, nullptr},
    {"emissive", "", "×", "Light up", 0, 10, nullptr},
    {"marker", "", "", "Part", 0, 0, nullptr},
    {"cel", "", "", "Drawing", 1, 100, nullptr},
    {"animation", "", "", "Movement", 0, 0, nullptr},
    {"begin", "", "s", "In", 0, 60, nullptr},
    {"speed", "", "×", "Speed", -4, 4, nullptr},
    {"speed_hold", "", "", "Hold at", 0, 0, nullptr},
    {"time_remap", "", "s", "Time Remap", 0, 60, nullptr},
    {"time_remap_loop", "", "", "Loop", 0, 0, nullptr},
    {"retime", "", "", "Re-timing", 0, 0, nullptr},
    {"retime_in", "", "s", "End of intro", 0, 10, nullptr},
    // Retiming of a nested element, as in Alight Motion.
    {"retime_out", "", "s", "Start of outro", 0, 10, nullptr},
    // 0 means the layer is sampled as smoothly as the stage.
    {"frame_rate", "", "fps", "Frame rate", 0, 60, nullptr},
    // A value of 1 is shown as 100%, as Alight Motion shows it.
    {"volume", "share", "%", "Volume", 0, 2, nullptr},
    {"beats", "", "dB", "Beats", 0, 30, nullptr},
    {"clip_matte", "", "", "Cut by", 0, 0, nullptr},
    {"clip_invert", "onoff", "", "Invert", 0, 1, nullptr},
    {"clip_feather", "", "px", "Feather", 0, 100, nullptr},
    {"copy_on", "thing", "", "On", 0, 0, nullptr},
    {"copy_on_offset", "share", "%", "Slide", -1, 1, nullptr},
    {"connect", "thing", "", "Join", 0, 0, nullptr},
    {"x", "", "px", "Position X", -4, 4, nullptr},
    {"y", "", "px", "Position Y", -3, 3, nullptr},
    // Measured in image points from the top left corner; see motolii_reading.
    {"z", "", "px", "Position Z", -6, 6, nullptr},
    {"scale_x", "share", "%", "Scale X", 0, 4, nullptr},
    {"scale_y", "share", "%", "Scale Y", 0, 4, nullptr},
    {"scale_z", "share", "%", "Scale Z", 0, 4, nullptr},
    {"rotate", "angle", "°", "Rotation", -180, 180, nullptr},
    {"rotate_x", "angle", "°", "X Rotation", -180, 180, nullptr},
    {"rotate_y", "angle", "°", "Y Rotation", -180, 180, nullptr},
    {"opacity", "share", "%", "Opacity", 0, 1, nullptr},
    {"blend", "", "", "Blend", 0, 0, nullptr},
    {"clip", "onoff", "", "Clip to below", 0, 1, nullptr},
    {"label", "", "", "Label colour", 0, 0, nullptr},
    {"distance", "", "px", "Distance", 0.05, 4, nullptr},
    {"zoom", "share", "%", "Zoom", 0.1, 4, nullptr},
    // Focus distance and aperture follow After Effects' Focus Distance and
    // Blender's F-Stop. The sliders reach as far as the top view of the camera
    // panel, 3000 points of a 1080-point-high image or 8.9 units, and f/22.
    // Typed values may go as far as kinds.h allows: 1e4 and 64.
    {"focus", "stage", "px", "Focus Distance", 0, 9, nullptr},
    {"aperture", "", "", "F-Stop", 0, 22, nullptr},
    {"anchor_x", "", "%", "Anchor X", -1, 1, "Anchor"},
    {"anchor_y", "", "%", "Anchor Y", -1, 1, "Anchor"},
    {"anchor_z", "", "%", "Anchor Z", -1, 1, "Anchor"},
    {"parent", "thing", "", "Parent", 0, 0, nullptr},
    {"parent_rotate", "share", "%", "Its turn", 0, 2, nullptr},
    {"parent_size", "share", "%", "Its size", 0, 2, nullptr},
    {"roll", "", "", "Roll", 0, 0, nullptr},
    {"roll_radius", "", "", "Roll radius", -5, 5, nullptr},
    {"mosh_with", "thing", "", "Motion of", 0, 0, nullptr},
    {"dissolve", "", "", "Dissolve", 0, 2, nullptr},
    {"grain", "share", "%", "Grain", 0.1, 4, nullptr},
    {"mosh_at", "", "s", "From", 0, 10, nullptr},
    {"connect_to", "thing", "", "With", 0, 0, nullptr},
    {"resample", "", "", "Points", 0, 64, nullptr},
    {"voxel", "share", "%", "Squares", 0, 0.2, nullptr},
    {"rough", "share", "%", "Rough", 0, 0.2, nullptr},
    {"rough_detail", "share", "%", "Detail", 0.005, 0.2, nullptr},
    {"trail", "thing", "", "Trail", 0, 0, nullptr},
    {"trail_length", "", "s", "Trail length", 0.05, 4, nullptr},
    {"fill_rule", "", "", "Fill rule", 0, 0, nullptr},
    {"morph", "share", "%", "Morph", 0, 1, nullptr},
    {"morph_to", "thing", "", "Into", 0, 0, nullptr},
    {"morph_steps", "", "", "Steps", 0, 32, nullptr},
    {"boolean", "", "", "Boolean", 0, 0, nullptr},
    {"boolean_with", "thing", "", "Shape", 0, 0, nullptr},
    {"follow", "thing", "", "Follow", 0, 0, nullptr},
    {"connect_reach", "stage", "px", "Reach", 0, 2, nullptr},
    {"cap", "", "", "Ends", 0, 0, nullptr},
    {"bevel", "", "", "Bevel", 0, 0, nullptr},
    {"bevel_depth", "", "px", "Bevel Depth", 0, 200, nullptr},
    {"bevel_color", "colour", "", "Bevel Colour", 0, 0, nullptr},
    {"bevel_metallic", "share", "%", "Bevel Metal", 0, 1, nullptr},
    {"bevel_roughness", "share", "%", "Bevel Rough", 0, 1, nullptr},
    {"side_color", "colour", "", "Side Colour", 0, 0, nullptr},
    {"side_metallic", "share", "%", "Side Metal", 0, 1, nullptr},
    {"side_roughness", "share", "%", "Side Rough", 0, 1, nullptr},
    {"back_color", "colour", "", "Back Colour", 0, 0, nullptr},
    {"back_metallic", "share", "%", "Back Metal", 0, 1, nullptr},
    {"back_roughness", "share", "%", "Back Rough", 0, 1, nullptr},
    {"heads", "", "", "Heads", 0, 0, nullptr},
    {"head_size", "", "×", "Head", 0.5, 12, nullptr},
    {"head_shape", "", "", "Head shape", 0, 0, nullptr},
    {"head_start", "", "", "Start shape", 0, 0, nullptr},
    {"join", "", "", "Corners", 0, 0, nullptr},
    {"dash", "", "px", "Dash", 0, 100, nullptr},
    {"dash_offset", "", "px", "Offset", -100, 100, nullptr},
    {"metallic", "share", "%", "Metal", 0, 1, nullptr},
    {"roughness", "share", "%", "Rough", 0, 1, nullptr},
    {"reflectance", "share", "%", "Shine", 0, 1, nullptr},
    {"clear_coat", "share", "%", "Varnish", 0, 1, nullptr},
    {"clear_coat_roughness", "share", "%", "Haze", 0, 1, nullptr},
    {"sheen", "share", "%", "Sheen", 0, 1, nullptr},
    {"shading", "", "", "Material", 0, 0, nullptr},
    {"thickness", "share", "%", "Thick", 0, 1, nullptr},
    {"anisotropy", "", "", "Brushed", -1, 1, nullptr},
    {"ior", "", "", "Bend", 1, 3, nullptr},
    {"dispersion", "share", "%", "Rainbow", 0, 0.5, nullptr},
    {"swim", "share", "%", "Wobble", 0, 1, nullptr},
    {"dark", "", "", "Darken", 0, 20, nullptr},
    {"vivid", "", "×", "Colour", 0, 3, nullptr},
    {"intensity", "", "", "Bright", 0, 100, nullptr},
    {"falloff", "stage", "px", "Reach", 0, 20, nullptr},
    {"cone", "angle", "°", "Cone", 1, 89, nullptr},
    {"shadows", "onoff", "", "Shadows", 0, 1, nullptr},
    {"shadow_softness", "share", "%", "Soft", 0, 1, nullptr},
    {"sun_size", "angle", "°", "Disk", 0, 10, nullptr},
    {"sun_halo", "", "×", "Halo", 0, 100, nullptr},
    {"light_group", "", "", "Group", 0, 7, nullptr},
    {"contact_shadows", "onoff", "", "Contact", 0, 1, nullptr},
    {"projection", "", "", "Lens", 0, 0, nullptr},
    {"shift_x", "", "", "Shift X", -2, 2, nullptr},
    {"shift_y", "", "", "Shift Y", -2, 2, nullptr},
    {"crop_left", "share", "%", "Left", 0, 0.95, nullptr},
    {"crop_top", "share", "%", "Top", 0, 0.95, nullptr},
    {"crop_right", "share", "%", "Right", 0, 0.95, nullptr},
    // The crop sliders stop at 0.95, almost the whole image, which is as far as
    // Alight Motion goes.
    {"crop_bottom", "share", "%", "Bottom", 0, 0.95, nullptr},
    {"room", "", "", "Room", 0, 0, nullptr},
    {"environment", "", "×", "Bright", 0, 10, nullptr},
    {"environment_rotate", "angle", "°", "Turn", -180, 180, nullptr},
    {"behind", "", "", "Behind", 0, 0, nullptr},
    {"background", "colour", "", "Colour", 0, 0, nullptr},
};

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_VALUES_H_
