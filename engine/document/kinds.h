#ifndef MOTOLII_DOCUMENT_KINDS_H_
#define MOTOLII_DOCUMENT_KINDS_H_
// The kinds of layer and the named values (properties) a layer can have.
// 詳細: docs/design/document_model.md

namespace motolii {

inline const char* const doc_kinds =
    "video image text solid shape camera light";
inline const char* const doc_visible_kinds = "video image text solid shape";
inline const char* const doc_placed_kinds =
    "video image text solid shape camera light behaviour";
inline const char* const doc_sheet_kinds = "text shape image";
inline const char* const doc_sheet_solid_kinds = "image text shape solid";
inline const char* const doc_video_sheet_kinds = "video image text shape";
inline const char* const doc_relations = "relate";
inline const char* const doc_shapes = "ring gem cube ball sketch";
// open: low and high only say how far the control goes; a typed value beyond
// them is accepted.
struct DocValue {
  const char* name;
  const char* kinds;
  double low, high;
  bool moves;
  const char* words;
  bool open = false;
};
inline const DocValue doc_values[] = {
    // For a group, z is how far its layers spread when it is expanded.
    {"x", doc_placed_kinds, -1e4, 1e4, true, nullptr},
    {"y", doc_placed_kinds, -1e4, 1e4, true, nullptr},
    {"z", doc_kinds, -1e4, 1e4, true, nullptr},
    // For a relation, rotate is added to each of its layers in turn.
    {"rotate", doc_placed_kinds, -1e6, 1e6, true, nullptr},
    {"rotate_x", doc_placed_kinds, -1e6, 1e6, true, nullptr},
    {"rotate_y", doc_placed_kinds, -1e6, 1e6, true, nullptr},
    // scale_z is thickness; 0 closes it to a sheet (see deep.glsl).
    {"scale_x", doc_visible_kinds, -1e4, 1e4, true, nullptr},
    {"scale_y", doc_visible_kinds, -1e4, 1e4, true, nullptr},
    {"scale_z", doc_sheet_solid_kinds, -1e4, 1e4, true, nullptr},
    // A JS file giving each copy's position (script_runner.h). Header params
    // become layer values named js_<param>. For stage: a .wgsl screen effect.
    {"script", "image text shape solid stage behaviour", 0, 0, false, ""},
    // .wgsl effects stacked on the layer. Camera fx are motions only.
    {"fx", "video image text shape solid camera", 0, 0, false, ""},
    // Titles of turned-off effects, separated by ";". Values are kept.
    {"fx_off", "video image text shape solid camera", 0, 0, false, ""},
    // The layer that stage effects follow in place of a mouse. 0 = none.
    {"follow", "stage", 0, 1e9, false, nullptr},
    {"size", "video image text solid shape behaviour", 1e-3, 1e4, true,
     nullptr},
    {"anchor_x", doc_visible_kinds, -100, 100, true, nullptr},
    {"anchor_y", doc_visible_kinds, -100, 100, true, nullptr},
    {"anchor_z", doc_visible_kinds, -100, 100, true, nullptr},
    {"focal_length", "camera", 1, 400, true, nullptr},
    // focus: distance to sharp plane (0 = where it looks). aperture: f-number
    // (0 = everything sharp). blur_level: multiplier on the lens blur.
    {"focus", "camera", 0, 1e4, true, nullptr},
    {"aperture", "camera", 0, 64, true, nullptr},
    {"blur_level", "camera", 0, 100, true, nullptr},
    {"opacity", "video image text shape solid behaviour", 0, 1, true, nullptr},
    {"clip", doc_visible_kinds, 0, 1, false, nullptr},
    // Clipped by the flat layer before it (the render code's matte).
    // clip_matte: alpha or luma. clip_feather: edge softness in screen points.
    {"group_mask", "shape", 0, 0, false, "none mask exclude"},
    {"clip_matte", doc_visible_kinds, 0, 0, false, "alpha luma"},
    {"clip_invert", doc_visible_kinds, 0, 1, false, nullptr},
    {"clip_feather", doc_visible_kinds, 0, 500, false, nullptr},
    {"solo", doc_kinds, 0, 1, false, nullptr},
    {"lock", doc_kinds, 0, 1, false, nullptr},
    {"visible", doc_placed_kinds, 0, 1, false, nullptr},
    {"order", doc_kinds, -1e9, 1e9, false, nullptr},
    {"wide", "shape", 1e-3, 1e3, false, nullptr},
    // points sets corner count (3 = triangle, 4 = quad, inner > 0 = star).
    {"shape", "shape", 0, 0, false, "rect circle"},
    // Crop as a share of width/height. Implemented via Filament's scissor.
    {"points", "shape", 3, 360, false, nullptr},
    {"inner", "shape", 0.01, 1, false, nullptr},
    {"round", "shape text image", 0, 0.5, true, nullptr},
    {"crop_left", doc_visible_kinds, 0, 0.95, false, nullptr},
    {"crop_top", doc_visible_kinds, 0, 0.95, false, nullptr},
    {"crop_right", doc_visible_kinds, 0, 0.95, false, nullptr},
    {"crop_bottom", doc_visible_kinds, 0, 0.95, false, nullptr},
    {"start", doc_kinds, 0, 1e6, false, nullptr},
    {"duration", doc_kinds, 1e-3, 1e6, false, nullptr},
    {"begin", doc_video_sheet_kinds, 0, 1e6, false, nullptr},
    {"speed", doc_visible_kinds, -100, 100, false, nullptr},
    {"keyed", "video", 0, 1, false, nullptr},
    // Keyed own-time (doc_own_time). loop: what happens past the last keyframe.
    {"time_remap", doc_sheet_solid_kinds, 0, 1e6, true, nullptr},
    {"time_remap_loop", doc_sheet_solid_kinds, 0, 0, false,
     "none cycle pingpong offset"},
    // Below 0 means where the playhead was left.
    {"poster_at", "stage", -1, 1e6, false, nullptr},
    // 0 means to the end of the project.
    {"layer_length", "stage", 0, 3600, false, nullptr},
    // 0 means no tempo. The timeline grid follows this.
    {"bpm", "stage", 0, 999, false, nullptr},
    {"bpm_from", "stage", 0, 1e6, false, nullptr},
    // For stage: project frame rate. For a layer: its own fps (0 = stage's).
    {"frame_rate", "video image text solid shape stage", 0, 60, false, nullptr},
    {"speed_hold", doc_visible_kinds, 0, 0, false, "start now end"},
    {"volume", "video", 0, 2, true, nullptr},
    // Beat detection threshold in dB. 0 shows none.
    {"beats", "video", 0, 60, false, nullptr},
    {"blend", doc_visible_kinds, 0, 0, false,
     "normal add multiply screen darken lighten overlay soft_light hard_light "
     "color_dodge color_burn difference exclusion hue saturation color "
     "luminosity linear_burn linear_light vivid_light pin_light darker_color "
     "lighter_color subtract divide"},
    {"file", "video image solid text", 0, 0, false, ""},
    {"shape", "solid", 0, 0, false, doc_shapes},
    {"text", "text", 0, 0, false, ""},
    // Format: "start count declarations" per line (community/css/text.h).
    {"text_styles", "text", 0, 0, false, ""},
    {"fill", "text solid shape light", 0, 0, false, ""},
    {"fill_media", "shape", 0, 0, false, ""},
    // Which drawing is shown by its file-name number. -1 = none.
    {"cel", "image", -1, 1e6, true, nullptr},
    // Named stretch of the source file. "all" = whole file.
    {"marker", "image", 0, 0, false, ""},
    {"name", doc_placed_kinds, 0, 0, false, ""},
    // "auto" picks a color by the layer's number.
    {"label", doc_kinds, 0, 0, false,
     "auto rose orange yellow lime green mint aqua sky blue periwinkle orchid "
     "magenta red tangerine azure teal"},
    // Linked element preset. See doc_element_add.
    {"element", doc_kinds, 0, 0, false, ""},
    // Re-timing (doc_element_clock).
    {"retime", doc_kinds, 0, 0, false,
     "freeze stretch loop loop_stretch blank"},
    {"retime_in", doc_kinds, 0, 1e6, false, nullptr},
    {"retime_out", doc_kinds, 0, 1e6, false, nullptr},
    {"element_length", doc_kinds, 0, 1e6, false, nullptr},
    // What an inserted element keeps of where it came from (doc_element_marks).
    {"element_at", doc_kinds, -1, 1e12, false, nullptr},
    {"element_part", doc_kinds, 0, 1e9, false, nullptr},
    {"element_text", "text", 0, 0, false, ""},
    {"animation", "solid", 0, 0, false, ""},
    // Color is its fill. It shines straight ahead of the way it is turned.
    {"intensity", "light", 0, 100, true, nullptr},
    {"falloff", "light", 0.01, 1000, false, nullptr},
    {"cone", "light", 1, 89, true, nullptr},
    {"shadows", "light", 0, 1, false, nullptr},
    // Filament's PCSS. 0 = crisp.
    {"shadow_softness", "light", 0, 1, false, nullptr},
    // Contact shadows: found on the image where the shadow map misses.
    {"contact_shadows", "light", 0, 1, false, nullptr},
    {"sun_size", "light", 0, 10, true, nullptr},
    {"sun_halo", "light", 0, 100, true, nullptr},
    // Group 1–7 lights only solids of that group. 0 lights group 0 and all.
    {"light_group", "light solid", 0, 7, false, nullptr},
    {"parent", doc_kinds, 0, 1e9, false, nullptr},
    // How much of its parent's rotation/size it takes: 0 none, 1 all, 2 twice.
    {"parent_rotate", doc_kinds, 0, 2, true, nullptr},
    {"parent_size", doc_kinds, 0, 2, true, nullptr},
    // Rolls like a wheel along x or y. Radius = half smaller side +
    // roll_radius.
    {"roll", doc_kinds, 0, 0, false, "x y"},
    {"roll_radius", doc_kinds, -1e3, 1e3, true, nullptr},
    // Point cloud (point_cloud.h). dissolve = scatter distance, grain = size.
    {"dissolve", "solid", 0, 100, true, nullptr},
    {"grain", "solid", 0.05, 20, true, nullptr},
    // Real datamosh (video_datamosh.h). mosh_at: the reference frame time.
    // mosh_with: the layer whose motion drives it. 0 = none.
    {"mosh", "video", 0, 1, false, nullptr},
    {"mosh_with", "video", 0, 1e9, false, nullptr},
    {"mosh_at", "video", 0, 1e6, false, nullptr},
    // 2d = screen-stuck. 2.5d = billboard facing viewer. 3d = turned by camera.
    // Default is 2.5d (doc_add writes it on a new layer).
    {"space", doc_visible_kinds, 0, 0, false, "2d 2.5d 3d"},
    {"align", "text", 0, 1, false, nullptr},
    {"trim", "shape text", 0, 1, true, nullptr},
    // trim_offset slides the visible part along the path, in turns.
    {"trim_begin", "shape text", 0, 1, true, nullptr},
    {"trim_offset", "shape text", -1e3, 1e3, true, nullptr},
    // bloat: -1 puckers in, 1 bloats out.
    {"bloat", "shape text", -1, 1, true, nullptr},
    {"zigzag", "shape text", -10, 10, true, nullptr},
    {"zigzag_ridges", "shape text", 0, 100, true, nullptr},
    {"zigzag_smooth", "shape text", 0, 1, true, nullptr},
    // Offset as a share of height: positive = outward.
    {"offset", "shape text", -10, 10, true, nullptr},
    // Each copy is the previous one moved, rotated, and scaled by the same
    // amount. Layout is up to its script (e.g. shelves/create/repeats/).
    {"copies", doc_sheet_solid_kinds, 1, 1000, false, nullptr},
    {"stagger", doc_sheet_solid_kinds, 0, 1e3, false, nullptr},
    {"stagger_from", doc_sheet_solid_kinds, 0, 0, false,
     "start centre end edges"},
    // Colors as six hex digits each. One color colors all copies.
    {"copy_fill", doc_sheet_kinds, 0, 0, false, ""},
    {"copy_fill_way", doc_sheet_kinds, 0, 0, false, "ramp cycle"},
    // Height multiplier; anchor stays in place.
    {"tall", doc_sheet_kinds, 0, 1e3, true, nullptr},
    // Per-copy height multipliers, round-robin. "none" = all equal.
    {"copy_tall", doc_sheet_solid_kinds, 0, 0, false, ""},
    // 0 = first color, 1 = last. Set by a behavior (copy_fill_at_by).
    {"copy_fill_at", doc_sheet_kinds, 0, 1, true, nullptr},
    {"copy_opacity_end", doc_sheet_kinds, 0, 1, true, nullptr},
    // Copies laid on another shape's outline, turned to follow it.
    {"copy_on", doc_sheet_solid_kinds, 0, 1e9, false, nullptr},
    {"copy_on_offset", doc_sheet_solid_kinds, -1e4, 1e4, true, nullptr},
    // Copies join one-to-one with the other layer's copies. 0 = none.
    {"connect", "shape", 0, 1e9, false, nullptr},
    {"connect_to", "shape", 0, 1e9, false, nullptr},
    // Max join distance (stage units). 0 = sequential order only.
    {"connect_reach", "shape", 0, 1e4, true, nullptr},
    {"boolean", "shape", 0, 0, false, "union subtract intersect exclude"},
    // 0 = none.
    {"boolean_with", "shape", 0, 1e9, false, nullptr},
    // Re-walk the outline at this many points. 0 = as made.
    {"resample", "shape", 0, 2048, true, nullptr},
    // Snap to a grid of squares this large (share of height). 0 = as made.
    {"voxel", "shape", 0, 1, true, nullptr},
    // rough: displacement as share of height. rough_detail: point spacing.
    {"rough", "shape", 0, 0.5, true, nullptr},
    {"rough_detail", "shape", 0.005, 1, true, nullptr},
    {"fill_rule", "shape", 0, 0, false, "nonzero evenodd"},
    // A behavior gives each copy of its connected layer a value, by copy number
    // and time. stagger: linear ramp min→max. oscillator: wave with frequency
    // (Hz), offset (share of wave), stagger (degrees between copies). noise:
    // smooth random. random: by seed.
    {"minimum", "behaviour", -1e6, 1e6, true, nullptr},
    {"maximum", "behaviour", -1e6, 1e6, true, nullptr},
    {"frequency", "behaviour", 0, 1000, true, nullptr},
    {"offset", "behaviour", -1e6, 1e6, true, nullptr},
    {"stagger", "behaviour", -1e6, 1e6, true, nullptr},
    {"seed", "behaviour", 0, 1e9, false, nullptr},
    // Snap to multiples of this (e.g. 90 = quarter turns). 0 = no snap.
    {"step", "behaviour", 0, 1e6, true, nullptr},
    // Falloff: inside `region` (any shape) the behavior works fully; outside,
    // not at all. falloff_soft fades over that many stage units.
    {"region", "behaviour", 0, 1e9, false, nullptr},
    {"falloff_soft", "behaviour", 0, 1e4, true, nullptr},
    {"falloff_invert", "behaviour", 0, 1, false, nullptr},
    // A relation is a behavior driven by a script (shelves/relations/). Its
    // params become layer values (js_<name>). strength: 0 = no effect, can
    // animate on/off without a jump.
    {"strength", "behaviour", 0, 1, true, nullptr},
    // Members by layer number; "_" = removed (keeps positions stable).
    {"members", "behaviour", 0, 0, false, ""},
    // Each member's previous relation (0 = none); this one starts from there.
    {"under", "behaviour", 0, 0, false, ""},
    // Each member's screen position when it joined, passed to the script as
    // `from` so it can add only the delta.
    {"from", "behaviour", 0, 0, false, ""},
    {"morph", "shape", 0, 1, true, nullptr},
    // trail: which layer to follow. trail_length: seconds of history.
    {"trail", "shape", 0, 1e9, false, nullptr},
    {"trail_length", "shape", 0.001, 60, true, nullptr},
    {"morph_to", "shape", 0, 1e9, false, nullptr},
    // Blend steps between source and target. 0 or 1 = none.
    {"morph_steps", "shape", 0, 64, false, nullptr},
    // Freehand strokes: "tool,width,x,y,pressure,..." separated by ";".
    // Tools: 0 pen, 1 brush, 2 fill, 3 eraser.
    {"drawing", "shape", 0, 0, false, ""},
    // SVG path data, in units of height from the center, y pointing down.
    {"path", "shape", 0, 0, false, ""},
    // Extra strokes outside the previous one. Each entry "<id>:" with values
    // keyed as "<id>:stroke" and "<id>:stroke_width" (stroke_put.h).
    {"strokes", doc_sheet_kinds, 0, 0, false, ""},
    {"stroke", doc_sheet_kinds, 0, 0, false, ""},
    {"stroke_width", doc_sheet_kinds, 0, 1000, false, nullptr},
    // Box width in multiples of line height (community/css/text.h).
    {"wrap", "text", 0, 0, false,
     "none character word smart ellipsis vertical"},
    {"wrap_at", "text", 0, 1000, false, nullptr},
    {"split", "text", 0, 0, false, "none letters words lines"},
    // Thousandths of an em (css-inline-3 range).
    {"letter_spacing", "text", -1000, 10000, false, nullptr},
    // CSS line-height <number>, never below 0 (css-inline-3).
    {"line_spacing", "text", 0, 1e4, false, nullptr},
    // CSS font-style oblique angle (css-fonts-4).
    {"italic", "text", -90, 90, false, nullptr},
    // gradient_angle: degrees clockwise, 0 = top to bottom.
    // gradient_scale: length as share of reach.
    {"gradient", "text shape", 0, 0, false, "linear radial"},
    {"gradient_angle", "text shape", -1e6, 1e6, false, nullptr},
    {"gradient_scale", "text shape", 0.01, 100, false, nullptr},
    {"gradient_spread", "text shape", 0, 0, false, "pad reflect repeat"},
    // CSS Color 4 color-interpolation-method (canvas_renderables.h, ramp_of).
    {"gradient_blend", "text shape", 0, 0, false, "rgb oklab hue steps"},
    {"cap", doc_sheet_kinds, 0, 0, false, "butt round square"},
    {"join", doc_sheet_kinds, 0, 0, false, "miter round bevel"},
    {"stroke_align", doc_sheet_kinds, 0, 0, false, "center inside outside"},
    {"bevel", doc_sheet_kinds, 0, 0, false,
     "none angular convex concave ogee step"},
    {"bevel_depth", doc_sheet_kinds, 0, 4096, true, nullptr},
    // Separate materials for a thick layer's other faces. Unset = same as
    // front.
    {"bevel_color", doc_sheet_kinds, 0, 0, false, ""},
    {"bevel_metallic", doc_sheet_kinds, 0, 1, false, nullptr},
    {"bevel_roughness", doc_sheet_kinds, 0, 1, false, nullptr},
    {"side_color", doc_sheet_kinds, 0, 0, false, ""},
    {"side_metallic", doc_sheet_kinds, 0, 1, false, nullptr},
    {"side_roughness", doc_sheet_kinds, 0, 1, false, nullptr},
    {"back_color", doc_sheet_kinds, 0, 0, false, ""},
    {"back_metallic", doc_sheet_kinds, 0, 1, false, nullptr},
    {"back_roughness", doc_sheet_kinds, 0, 1, false, nullptr},
    {"heads", "shape", 0, 0, false, "none end start both"},
    // Head size as a multiple of edge length.
    {"head_size", "shape", 0.5, 40, false, nullptr},
    {"head_shape", "shape", 0, 0, false,
     "arrow circle box chevron bar t_line square square_filled diamond "
     "diamond_filled arrow_hollow arrow_filled circle_hollow circle_filled "
     "teardrop_hollow teardrop_filled"},
    {"head_start", "shape", 0, 0, false,
     "arrow circle box chevron bar t_line square square_filled diamond "
     "diamond_filled arrow_hollow arrow_filled circle_hollow circle_filled "
     "teardrop_hollow teardrop_filled"},
    {"dash", doc_sheet_kinds, 0, 1000, false, nullptr},
    {"dash_gap", doc_sheet_kinds, 0, 1000, false, nullptr},
    {"dash_offset", doc_sheet_kinds, -1e4, 1e4, false, nullptr},
    // Filament PBR surface.
    {"metallic", doc_visible_kinds, 0, 1, false, nullptr},
    {"roughness", doc_visible_kinds, 0, 1, false, nullptr},
    {"reflectance", doc_visible_kinds, 0, 1, false, nullptr},
    // Glass (render code's own): ior bends light, dispersion parts colors,
    // swim distorts what is behind, dark absorbs over distance, vivid
    // saturates.
    {"ior", doc_visible_kinds, 1, 3, false, nullptr},
    {"dispersion", doc_visible_kinds, 0, 0.5, false, nullptr},
    {"swim", doc_visible_kinds, 0, 1, false, nullptr},
    {"dark", doc_visible_kinds, 0, 20, false, nullptr},
    {"vivid", doc_visible_kinds, 0, 3, false, nullptr},
    {"clear_coat", doc_visible_kinds, 0, 1, false, nullptr},
    {"clear_coat_roughness", doc_visible_kinds, 0, 1, false, nullptr},
    {"emissive", doc_visible_kinds, 0, 20, true, nullptr},
    {"sheen", doc_visible_kinds, 0, 1, false, nullptr},
    // Filament shading models. thick_glass/lacquer/bubble are custom .mat
    // files.
    {"shading", doc_visible_kinds, 0, 0, false,
     "lit cloth subsurface glass filament_glass lacquer bubble"},
    {"thickness", doc_visible_kinds, 0, 1, false, nullptr},
    // Negative = opposite direction.
    {"anisotropy", doc_visible_kinds, -1, 1, false, nullptr},
    // orthographic: no depth perspective. shift_x/y: lens shift (share of
    // image)
    // keeps uprights upright.
    {"projection", "camera", 0, 0, false, "perspective orthographic"},
    {"shift_x", "camera", -2, 2, true, nullptr},
    {"shift_y", "camera", -2, 2, true, nullptr},
    // Stage (layer 0) values. render_* describe export settings.
    // Color grading, bloom, vignette etc. are Filament viewer settings on the
    // shelf (stage/effects/viewer_settings.h).
    {"render_height", "stage", 0, 8640, false, nullptr},
    {"render_rate", "stage", 0, 60, false, nullptr},
    {"render_mbps", "stage", 0, 500, false, nullptr},
    {"render_blur", "stage", 0, 64, false, nullptr},
    {"render_alpha", "stage", 0, 1, false, nullptr},
    {"room", "stage", 0, 0, false,
     "small_studio studio_small_02_2k lightroom venetian_crossroads_2k "
     "graffiti_shelter_2k parking_garage_2k pillars_2k"},
    {"environment", "stage", 0, 10, false, nullptr},
    {"environment_rotate", "stage", -1e6, 1e6, false, nullptr},
    {"background", "stage", 0, 0, false, ""},
    {"behind", "stage", 0, 0, false, "colour room"}};

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_KINDS_H_
