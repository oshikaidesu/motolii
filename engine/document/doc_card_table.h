// doc_card_table.h: part of doc.h (the cards a thing's values are gathered in). Read only through doc.h.
static const DocCard doc_cards[] = {
    // (in the order a hand needs them: first what every thing has, as After Effects' Properties panel keeps Layer Transform at the top for all layer types; then, Alight Motion's Opacity & Blending, how it lies on what is under it; then its own, Text and Paragraph, Shape Properties)
    {"Transform", "space parent anchor_x anchor_y anchor_z x y z scale_x scale_y scale_z rotate_x rotate_y rotate opacity", "kind", "!camera"},   // (After Effects' Transform group: where it is, how large, how turned, how seen; each its own value)
    {"Camera", "parent x y z rotate_x rotate_y rotate distance zoom", "kind", "camera"},
    {"Fog", "fog fog_near fog_far fog_color", "kind", "camera"},   // (the camera's own, as Alight Motion's camera has: its colour, where it begins, where it is whole; the stage's when it says none)   // (After Effects' camera: what it looks at, where it is and how turned, how far its eye is, its zoom)
    {"Blending", "blend clip"},   // (After Effects' layer mode and its track matte, in its simplest: drawn over what lies below as it says, or only inside the one before it)
    {"Text", "text file size letter_spacing line_spacing align", "kind", "text"},   // (After Effects' Source Text and Character, Cavalry's Text Shape: what it says, in which font, how large, which way it lines up)
    {"Star", "points inner", "shape", "star"},   // (After Effects' Polystar: how many points, how far in between them)
    {"Polygon", "points", "shape", "polygon"},
    {"Fill", "fill fill_media stroke stroke_width"},   // (After Effects' Fill and Stroke, Cavalry's Fill and Stroke: a colour, colours down it, or the material glass; its edge and how wide)
    {"Type", "split italic wrap wrap_at", "kind", "text"},   // (a text's, shown unasked, as Alight Motion keeps Edit Text among a text's tiles (AbsentMotion's LayerTools.kt): its slant, its lines broken in a box or set down the page, its letters or words each its own (the user, 11/5: more of a text's expression where it is picked))
    {"Gradient", "gradient gradient_angle gradient_scale gradient_spread", "fill", "~ ", true},
    // (no Copies card: how many and the copies' own values are on the first expression's card (doc_cards_of), as
    //  After Effects' Repeater keeps its Copies, Offset and Transform (Start/End Opacity) within it)
    {"Wave", "wave_x wave_y wave_z wave_rotate wave_size wave_speed wave_phase wave_noise noise_scale seed", nullptr, nullptr, true},
    {"Field", "field_x field_y field_z field_radius field_band field_size field_rotate field_push", nullptr, nullptr, true},
    {"Shine", "emissive", "kind", "!solid", true},   // (a flat thing lit from within: past 1, the stage's bloom takes it up where it lies in the stage's own view; laid over a solid thing, a picture of its own is clear round it and keeps no halo: ThorVG's glow does that)
    {"Motion", "orient", "kind", "!camera", true},   // (how it goes along its way: turned the way it is going, After Effects' Auto-Orient)
    {"Play", "marker animation speed speed_hold frame_rate", "kind", "!stage", true},   // (a thing's; the stage's own frame rate is said in the size box)
    {"Time Remap", "time_remap time_remap_loop", "file", "~.js"}, {"Time Remap", "time_remap time_remap_loop", "script", "~.js"},   // (a program's own time, of one that paints flat and of one with a body: doc_own_time)
    {"Drawing", "cel", "cel", "!0"},   // (a level's drawings: a picture told a drawing is one)
    {"Source", "begin", "kind", "film"},   // (where in its file it starts: Premiere Pro's Slip takes a number typed as the hand's drag does; the timeline's pale bar is the same value carried)
    {"Sound", "volume beats", "kind", "film"},   // (its beats: shown on the timeline's ruler where it strikes)
    {"Matte", "clip_matte clip_invert clip_feather", "clip", "1"},
    {"Parent", "parent_rotate parent_size roll roll_radius", "parent", "!0"},   // (Alight Motion's Parenting Helper: how much of its parent's turn and size it takes, and rolling as a wheel; while it has a parent)
    {"Element", "retime retime_in retime_out", "shape", "null"},   // (a group's, kept with it as an element: how it is played when put in longer or shorter, Alight Motion's Element settings' Re-timing and its marks)
    {"Scale Assist", "scale_assist scale_assist_amount scale_assist_damp", "scale_assist", "!"},   // (Alight Motion's Scale Assist: one way grown alone, or both, kept as bulky as it was; once put on from the Effects shelf, as its effect is: looks/Scale Assist.motolii)
    {"Connect", "connect connect_to connect_reach", nullptr, nullptr, true},
    {"Line", "cap join dash dash_offset heads head_shape head_start head_size", nullptr, nullptr, true},   // (and its open ends' shapes: Cavalry's heads, Alight Motion's line start and end)
    {"Path", "round bloat offset zigzag zigzag_ridges zigzag_smooth", "kind", "shape", true},   // (its path made anew: After Effects' shape operators, ThorVG's own)
    {"Edit Shape", "crop_left crop_top crop_right crop_bottom round", "kind", "picture"},   // (a photo's rect, Alight Motion's Edit Shape, AbsentMotion's Shape Options: cut in from its sides, what is left where it was, and its corners rounded; drawn as a rect its own file fills, doc_match)
    {"Deform", "warp bend twist pinch skew squash wiggle stretch bend_direction pin_tl_x pin_tl_y pin_tr_x pin_tr_y pin_bl_x pin_bl_y pin_br_x pin_br_y warp_width warp_angle warp_speed skew_axis wiggle_detail wiggle_speed", "kind", "shape", true},   // (its points moved as it is drawn: Cavalry's deformers)
    {"Strokes", "stroke_2 stroke_2_width stroke_3 stroke_3_width", "kind", "text"},   // (shown unasked: Alight Motion's Border & Shadow is among a text's tiles)   // (more edges, each outside the last, drawn with the words: they stand in its depth, as Multi-Border's, on its picture, do not)
    {"Bevel", "bevel bevel_depth bevel_color bevel_metallic bevel_roughness", nullptr, nullptr, true},
    {"Side", "side_color side_metallic side_roughness back_color back_metallic back_roughness", nullptr, nullptr, true},   // (After Effects' Side and Back Color: a thick thing's other faces)
    // (the material it wears, and its own knobs: Create's Material group; a card for each, shown for its own: doc_material)
    {"Surface", "shading metallic roughness reflectance clear_coat clear_coat_roughness sheen anisotropy thickness emissive", "shading", "@lit cloth subsurface", true},
    {"Glass", "shading ior dispersion swim dark vivid", "shading", "@glass filament_glass"},
    {"Lacquer", "shading metallic", "shading", "@lacquer"},
    {"Bubble", "shading vivid", "shading", "@bubble"},
    {"Lit", "light_group", "kind", "solid", true},   // (which lights reach it)
    {"Light", "intensity falloff cone shadows shadow_softness contact_shadows light_group sun_size sun_halo", "kind", "light"},
    {"Projection", "projection shift_x shift_y"},
    {"Grade", "tone_mapper exposure contrast saturation vibrance temperature slope offset power shadows_color midtones_color highlights_color", nullptr, nullptr, true},
    {"Lens", "bloom ambient_occlusion reflections lens_flare vignette vignette_color fog fog_near fog_far fog_color anti_aliasing", "kind", "stage"},   // (the stage's; a camera's own fog is on its Fog card)
    {"Room", "room environment environment_rotate behind background"},
    {"Physics", "physics bounce friction gravity", nullptr, nullptr, true},
    {"Around", "strength radius offset tilt leader centre_x centre_y rotate rotate_y lag", "file", "around"},   // (a relation's card: its things round a middle, or round a leader; turned in turn, lag apart)
    {"Row", "strength gap centre_x centre_y rotate rotate_y lag", "file", "row"},
    {"Follow", "strength leader lag leader_b hand", "file", "follow"},
    {"Push", "strength leader radius", "file", "push"},
    {"Group", "strength lag x y spread scatter rotate rotate_y size opacity", "file", "group"},   // (things in an order and nothing else: away by its own move, turn, size and opacity, each in turn)
    {"Relation", "strength", "file", "relate"},   // (one written as a file: its own knobs come under it, as a recipe's)
    {"Falloff", "region falloff_soft falloff_invert", "file", "!"},   // (any with a file: a behaviour shows only such cards, doc_cards_of)
    {"Note", "label note", nullptr, nullptr, true},   // (what a maker wrote of it: After Effects' layer comment)
    {"Trim Paths", "trim trim_begin trim_offset", "trim", "+"},
    {"Datamosh", "mosh_with mosh_at", "mosh", "+"},
    {"Points", "dissolve grain", "file", "~.ply"},   // (a point cloud's own: point_cloud.h)   // (the film's own compressed pictures, video_datamosh.h)   // (After Effects' shape operator: added from the shelf)
    {"Gaussian Blur", "blur blur_direction", "blur", "+"},   // (the effects (doc_effects), each its card while it is on, as After Effects' Effect Controls)
    {"Drop Shadow", "shadow shadow_distance shadow_angle shadow_blur shadow_opacity", "shadow", "+"},
    {"Glow", "glow_opacity", "glow", "+"},   // (how strong: Filament's bloom on its own picture, doc_moment)
    {"Duotone", "tint tint_black tint_white", "tint", "+"},
    {"Gradient Map", "tritone tritone_shadow tritone_midtone tritone_highlight", "tritone", "+"},
};
static bool doc_among(const std::string& words, const std::string& one) { return (" " + words + " ").find(" " + one + " ") != std::string::npos; }
