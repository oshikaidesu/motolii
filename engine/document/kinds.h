#ifndef MOTOLII_DOCUMENT_KINDS_H_
#define MOTOLII_DOCUMENT_KINDS_H_
// The project: a table of keyframes, and the kinds of layer and named values it
// may hold.
//
// The document is a table of keyframes: the value of a layer's named property
// at a time, as (layer, name, at, value). A property with one keyframe is
// constant. A property with several keyframes moves between them. Each call
// makes one change, which is one undo step, and the canvas shows the change by
// the time the call returns. A change the canvas cannot show is not made.
//
// Easing: a keyframe holds a value, and the easing of the segment from a
// keyframe to the next defines how the value moves between them. The built-in
// easings are the nine kinds in easing_curves.h: Hold, Linear, Bezier, Bounce,
// Elastic, Cyclic, Random, Steps and ElasticSteps, each with its own numbers. A
// custom easing can be added as an SQLite expression stored in the document.
// Its variables are:
//   u        progress through the segment, from 0 to 1
//   t        seconds since the segment began
//   d        length of the segment in seconds
//   a, b     the values of the two keyframes
//   p1..p4   numbers supplied with the easing
// A custom easing is accepted only if it starts at the first keyframe's value
// and ends at the second's.
//
// Storage and undo come from SQLite: the file format, saving (a change is in
// the file when its call returns), and undo through the session extension. A
// change is recorded as a changeset, and undo applies the changeset inverted.
// The undo steps are stored in the file too. A layer's time uses the names from
// GES: start and duration.
//
// Property names follow ThorVG where ThorVG has a name for the same thing:
// translate's x and y, rotate, size, blend and its modes, text, fill, and the
// begin, add and remove of a segment. The properties are:
//
//   Numbers
//     x, y, z, rotate, size  Center position, rotation in degrees, and height.
//     rotate_x, rotate_y     Rotation in degrees about the layer's own x and y
//     axes, which
//                            tilts a layer back or turns it sideways.
//     opacity                1 is fully visible and 0 is invisible. Applies to
//     video, image
//                            and text layers.
//     start, duration        When the layer appears and for how long. If not
//     set, the layer
//                            stays for the whole project and loops.
//     begin, speed           Video only: the offset into the source and the
//     playback speed.
//                            A negative speed plays backwards.
//     order                  Stacking order among layers. A greater number is
//     nearer the
//                            viewer. If not set, layers stack in creation
//                            order.
//     visible                0 hides the layer without removing it from the
//     document, as in
//                            ThorVG.
//     clip                   1 shows the layer only inside the box of the layer
//     before it,
//                            for example a 3D layer cut by a rectangle.
//     wide                   Shape only: the width as a multiple of the height.
//     keyed                  Video only: 1 removes a solid background, such as
//     a green
//                            screen, whose color is the one shared by the four
//                            corners. 0 keeps the background. If not set, the
//                            background is removed when the video has such a
//                            color.
//
//   Words
//     blend                  How the layer combines with what is behind it:
//                            normal | add | multiply | screen.
//     file, shape            What the layer is made from. The add call sets
//     them. For a file
//                            layer it is the file, and for a text layer it is
//                            the font. For a solid it is one of the built-in
//                            shapes: ring | gem | cube. For a flat shape drawn
//                            by ThorVG it is rect | circle.
//     text                   The text to show, up to the end of the line.
//     fill                   The surface of the layer. For text it is a color
//     as six hex
//                            digits, such as ff3366. For a solid it is a color
//                            or the material glass.
//
// This header: the kinds of layer and relation, and doc_values, the table of
// named values that layers can have.

namespace motolii {

// The kinds of layer.
inline const char* const doc_kinds =
    "video image text solid shape camera light";
// The kinds of layer that are seen.
inline const char* const doc_visible_kinds = "video image text solid shape";
// The kinds of relation: a script file.
inline const char* const doc_relations = "relate";
// The built-in shapes a solid can have.
inline const char* const doc_shapes = "ring gem cube ball sketch";
// A named value that a layer can have: its name, the kinds of layer that have
// it, a range from low to high or a list of allowed words, and whether it can
// move, that is take keyframes. open: low and high only say how far the control
// goes. A value typed beyond them is accepted, like After Effects' slider range
// and valid range (PF_FloatSliderDef).
struct DocValue {
  const char* name;
  const char* kinds;
  double low, high;
  bool moves;
  const char* words;
  bool open = false;
};
inline const DocValue doc_values[] = {
    // For a group, z is how far its layers are away when it is out.
    {"x", "video image text solid shape camera light behaviour", -1e4, 1e4,
     true, nullptr},
    {"y", "video image text solid shape camera light behaviour", -1e4, 1e4,
     true, nullptr},
    {"z", doc_kinds, -1e4, 1e4, true, nullptr},
    // For a relation, rotate is added to each of its layers in turn.
    {"rotate", "video image text solid shape camera light behaviour", -1e6, 1e6,
     true, nullptr},
    {"rotate_x", "video image text solid shape camera light behaviour", -1e6,
     1e6, true, nullptr},
    {"rotate_y", "video image text solid shape camera light behaviour", -1e6,
     1e6, true, nullptr},
    // Scale along each axis as a multiple of the size, each on its own as After
    // Effects' Scale.
    // Below 0 flips the layer. A flat layer's scale_z is its thickness: if not
    // set, the layer is
    // flat. If set, its sheet becomes a box that its image is pushed through
    // (deep.glsl), like
    // After Effects' Extrusion Depth and Apple Motion's Depth on a flat text
    // solid. 0 closes it to
    // a sheet again.
    {"scale_x", doc_visible_kinds, -1e4, 1e4, true, nullptr},
    {"scale_y", doc_visible_kinds, -1e4, 1e4, true, nullptr},
    {"scale_z", "solid text shape image", -1e4, 1e4, true, nullptr},
    // script: a preset as code, a JavaScript file that gives the position of
    // each copy (script_runner.h).
    // The parameters in its header are values of the layer, named js_ plus the
    // parameter's name.
    // For the stage, script is a whole-screen effect: a .wgsl file
    // (screen_fx.h).
    {"script", "image text shape solid stage behaviour", 0, 0, false, ""},
    // fx: a layer's own effects, like After Effects' effects on a layer. They
    // are the whole-screen
    // effects' .wgsl files, one over another, applied to the layer as the
    // camera sees it. A
    // camera's fx are AbsentMotion's motions only, and they move its place as
    // AbsentMotion's camera
    // is moved (doc_fx_say).
    {"fx", "video image text shape solid camera", 0, 0, false, ""},
    // The effects that are turned off, as the titles of their cards separated
    // by ";". Like Alight
    // Motion's eye on an effect. Their values are kept.
    {"fx_off", "video image text shape solid camera", 0, 0, false, ""},
    // The layer that the stage's effects follow in place of a mouse. Their
    // pointer, center, mouse
    // or point parameters are where that layer is on the image. 0 means none.
    {"follow", "stage", 0, 1e9, false, nullptr},
    {"size", "video image text solid shape behaviour", 1e-3, 1e4, true,
     nullptr},
    {"anchor_x", doc_visible_kinds, -100, 100, true, nullptr},
    {"anchor_y", doc_visible_kinds, -100, 100, true, nullptr},
    {"anchor_z", doc_visible_kinds, -100, 100, true, nullptr},
    // distance and zoom: a camera looks at where it is, from around it as it is
    // turned, from so far
    // away or so near.
    {"distance", "camera", 0.01, 100, true, nullptr},
    {"zoom", "camera", 0.01, 100, true, nullptr},
    // The camera's lens: focus is how far from the camera layers are sharp, 0
    // being where it looks.
    // aperture is the f-number, and 0 means everything is sharp.
    // blur_level is After Effects' Blur Level: how many times the lens's own
    // blur.
    {"focus", "camera", 0, 1e4, true, nullptr},
    {"aperture", "camera", 0, 64, true, nullptr},
    {"blur_level", "camera", 0, 100, true, nullptr},
    {"opacity", "video image text shape behaviour", 0, 1, true, nullptr},
    {"clip", doc_visible_kinds, 0, 1, false, nullptr},
    // clip: the layer is clipped by the flat layer before it, with the render
    // code's matte.
    // clip_matte chooses whether the matte is how clear that layer is or how
    // light it is, like
    // After Effects' alpha and luma mattes. clip_invert does the opposite.
    // clip_feather softens the
    // edge, in points of the screen.
    // A group made to mask: its top layer is the shape that the others in it
    // are seen through, or
    // cut out by. Alight Motion's Group and Mask and Group and Exclude, see
    // docs/design/alight_motion_ui.md.
    {"group_mask", "shape", 0, 0, false, "none mask exclude"},
    // A solid is cut by a box, not a matte.
    {"clip_matte", "video image text shape", 0, 0, false, "alpha luma"},
    {"clip_invert", "video image text shape", 0, 1, false, nullptr},
    {"clip_feather", "video image text shape", 0, 500, false, nullptr},
    // After Effects' own: while any layer is solo only those layers are seen,
    // and a locked layer
    // cannot be changed.
    {"solo", doc_kinds, 0, 1, false, nullptr},
    {"lock", doc_kinds, 0, 1, false, nullptr},
    {"visible", "video image text solid shape camera light behaviour", 0, 1,
     false, nullptr},
    {"order", doc_kinds, -1e9, 1e9, false, nullptr},
    {"wide", "shape", 1e-3, 1e3, false, nullptr},
    {"shape", "shape", 0, 0, false,
     "rect circle solid polygon star line wave null ring arc arrow squircle "
     "cog path spiral chamfer"},
    // crop_left, crop_top, crop_right and crop_bottom cut a photo in from each
    // side, as a share of
    // its width or height, like Alight Motion's crop. points, inner and round
    // are a polygon's or
    // star's points, a star's inner points, and its rounded corners.
    {"points", "shape", 1, 360, false, nullptr},
    {"inner", "shape", 0.01, 1, false, nullptr},
    {"round", "shape image", 0, 0.5, true, nullptr},
    {"crop_left", "image", 0, 0.95, false, nullptr},
    {"crop_top", "image", 0, 0.95, false, nullptr},
    {"crop_right", "image", 0, 0.95, false, nullptr},
    {"crop_bottom", "image", 0, 0.95, false, nullptr},
    {"start", doc_kinds, 0, 1e6, false, nullptr},
    {"duration", doc_kinds, 1e-3, 1e6, false, nullptr},
    {"begin", "video image text shape", 0, 1e6, false, nullptr},
    {"speed", "video solid image text shape", -100, 100, false, nullptr},
    {"keyed", "video", 0, 1, false, nullptr},
    // time_remap: the seconds of its own that a program is at, keyed like After
    // Effects' Time Remap
    // (doc_own_time). time_remap_loop: what happens past its last keyframe,
    // like loopOut
    // (doc_keys_at).
    {"time_remap", "image text shape solid", 0, 1e6, true, nullptr},
    {"time_remap_loop", "image text shape solid", 0, 0, false,
     "none cycle pingpong offset"},
    // The time in seconds at which the project's own image is drawn. Below 0
    // means where the
    // playhead was left. Alight Motion's Set Project Thumbnail, see
    // motolii_poster.
    {"poster_at", "stage", -1, 1e6, false, nullptr},
    // How long a layer that is added lasts, in seconds. 0 means to the end of
    // the project.
    // AbsentMotion's New Layer Length, see doc_add.
    {"layer_length", "stage", 0, 3600, false, nullptr},
    // The project's tempo in beats per minute, 0 meaning none. The timeline's
    // grid goes by it, like
    // Live's Tempo field. Alight Motion has none.
    {"bpm", "stage", 0, 999, false, nullptr},
    // Where a bar begins, in seconds, like Live's Set 1.1.1 Here.
    {"bpm_from", "stage", 0, 1e6, false, nullptr},
    // For the stage, the project's frame rate: the whole project is seen only
    // at its frames
    // (time_is in render_layers.h). For a layer, its own frames per second,
    // with 0 meaning the
    // stage's (doc_stepped).
    {"frame_rate", "video image text solid shape stage", 0, 60, false, nullptr},
    // speed_hold: where the layer's Speed holds it in time, like After Effects'
    // Time Stretch: its
    // start, the playhead, or its end.
    {"speed_hold", "video solid image text shape", 0, 0, false,
     "start now end"},
    // How loud the layer's sound is heard and exported: 1 as it comes, 0 none,
    // 2 twice as loud.
    // Alight Motion's Volume, 0 to 200%.
    {"volume", "video", 0, 2, true, nullptr},
    // Where its sound strikes: the layer is louder by this many dB at once. 0
    // shows none.
    {"beats", "video", 0, 60, false, nullptr},
    {"blend", "video image text shape", 0, 0, false,
     "normal add multiply screen darken lighten overlay soft_light hard_light "
     "color_dodge color_burn difference exclusion hue saturation color "
     "luminosity linear_burn linear_light vivid_light pin_light darker_color "
     "lighter_color subtract divide"},
    {"file", "video image solid text", 0, 0, false, ""},
    {"shape", "solid", 0, 0, false, doc_shapes},
    {"text", "text", 0, 0, false, ""},
    {"fill", "text solid shape light", 0, 0, false, ""},
    {"fill_media", "shape", 0, 0, false, ""},
    // A level's: which of its drawings is shown, by the number in its file name
    // (doc_cel_file),
    // held from keyframe to keyframe as a timesheet holds it. -1 means none,
    // the cross of a
    // timesheet.
    {"cel", "image", -1, 1e6, true, nullptr},
    // An After Effects file's named stretch that it plays over and over. all
    // means the whole file.
    {"marker", "image", 0, 0, false, ""},
    // What the layer is called where layers are listed, behaviors included. If
    // not set, it is named
    // by its kind.
    {"name", "video image text solid shape camera light behaviour", 0, 0, false,
     ""},
    // Its color on the timeline, chosen from Ableton Live's clip colors in the
    // window's order. auto
    // picks one by the layer's number.
    {"label", doc_kinds, 0, 0, false,
     "auto rose orange yellow lime green mint aqua sky blue periwinkle orchid "
     "magenta red tangerine azure teal"},
    // The element the layer was put in from, linked. Its file is written as a
    // preset writes it,
    // {own}/elements/... See doc_element_add and Alight Motion's Element.
    {"element", doc_kinds, 0, 0, false, ""},
    // An element's re-timing (doc_element_clock).
    {"retime", doc_kinds, 0, 0, false,
     "freeze stretch loop loop_stretch blank"},
    {"retime_in", doc_kinds, 0, 1e6, false, nullptr},
    {"retime_out", doc_kinds, 0, 1e6, false, nullptr},
    {"element_length", doc_kinds, 0, 1e6, false, nullptr},
    // What an inserted element keeps of where it came from (doc_element_marks).
    {"element_at", doc_kinds, -1, 1e12, false, nullptr},
    {"element_part", doc_kinds, 0, 1e9, false, nullptr},
    {"element_text", "text", 0, 0, false, ""},
    // For a 3D file: which of the file's own animations it plays, over and
    // over, at its speed, from
    // when the layer comes on.
    {"animation", "solid", 0, 0, false, ""},
    // A light, Filament's own, created as a sun, a point or a spot (its file).
    // intensity: how
    // strong it is, 1 being as bright as the stage's own light. falloff: how
    // far a point or spot
    // reaches, in units of the stage. cone: how wide a spot's cone is, in
    // degrees. shadows: whether
    // the solid layers it lights cast shadows. Its color is its fill. It shines
    // the way it is
    // turned, straight ahead of it.
    {"intensity", "light", 0, 100, true, nullptr},
    {"falloff", "light", 0.01, 1000, false, nullptr},
    {"cone", "light", 1, 89, true, nullptr},
    {"shadows", "light", 0, 1, false, nullptr},
    // How soft its shadows are, as from a larger lamp: Filament's PCSS. 0 is
    // crisp.
    {"shadow_softness", "light", 0, 1, false, nullptr},
    // Filament's contact shadows: the thin shadow where layers touch, which its
    // shadow map misses,
    // found on the image.
    {"contact_shadows", "light", 0, 1, false, nullptr},
    // A sun seen in the room behind it (behind set to room): Filament's own
    // disk. sun_size is its
    // size in degrees across and sun_halo is the glow around it.
    {"sun_size", "light", 0, 10, true, nullptr},
    {"sun_halo", "light", 0, 100, true, nullptr},
    // Filament's light channels: a light of group 1 to 7 lights only the solids
    // of that group. 0,
    // the default, lights the solids of group 0 and every other.
    {"light_group", "light solid", 0, 7, false, nullptr},
    {"parent", doc_kinds, 0, 1e9, false, nullptr},
    // How much of its parent's rotation and size it takes: 1 all, 0 none, 2
    // twice. Alight Motion's
    // Parenting Helper weights.
    {"parent_rotate", doc_kinds, 0, 2, true, nullptr},
    {"parent_size", doc_kinds, 0, 2, true, nullptr},
    // roll: turned like a wheel rolling as the layer goes along x or y. The
    // wheel's radius is half
    // its smaller side plus roll_radius.
    {"roll", doc_kinds, 0, 0, false, "x y"},
    {"roll_radius", doc_kinds, -1e3, 1e3, true, nullptr},
    // A point cloud's: dissolve throws its grains out, each its own way, this
    // far. grain is how
    // large they are drawn (point_cloud.h).
    {"dissolve", "solid", 0, 100, true, nullptr},
    {"grain", "solid", 0.05, 20, true, nullptr},
    // mosh: a real datamosh. From mosh_at, a time of its video, the other
    // layer's motion is poured
    // into its last image (video_datamosh.h). mosh_with: the layer it goes
    // with. It is moved,
    // turned and sized as that layer is, then as itself. 0 means none.
    {"mosh", "video", 0, 1, false, nullptr},
    {"mosh_with", "video", 0, 1e9, false, nullptr},
    {"mosh_at", "video", 0, 1e6, false, nullptr},
    // space: 2d is not in the world and lies by the order alone. 2.5d is a
    // sheet in the world, in
    // front or behind by depth, always facing the viewer. 3d is filmed as it
    // is, with the camera
    // turning round it, as a solid is.
    {"space", "video image text shape", 0, 0, false, "2d 2.5d 3d"},
    // How the lines of a text lie one under another, ThorVG's own: 0 at the
    // left, 0.5 about the
    // middle, 1 at the right.
    {"align", "text", 0, 1, false, nullptr},
    // trim: how much of its path is cut off the end, like After Effects' Trim
    // Paths and ThorVG's
    // trimpath.
    {"trim", "shape", 0, 1, true, nullptr},
    // trim_begin cuts the same off the beginning. trim_offset slides the part
    // that is left along
    // the path, in turns.
    {"trim_begin", "shape", 0, 1, true, nullptr},
    {"trim_offset", "shape", -1e3, 1e3, true, nullptr},
    // The path bent, like After Effects' path operators and ThorVG's own. bloat
    // is pucker and
    // bloat: -1 in, 1 out. zigzag is its height as a share of the layer's
    // height, zigzag_ridges the
    // number of ridges a side, and zigzag_smooth chooses smooth or sharp.
    // offset offsets the path,
    // out or in, as a share of its height.
    {"bloat", "shape", -1, 1, true, nullptr},
    {"zigzag", "shape", -10, 10, true, nullptr},
    {"zigzag_ridges", "shape", 0, 100, true, nullptr},
    {"zigzag_smooth", "shape", 0, 1, true, nullptr},
    {"offset", "shape", -10, 10, true, nullptr},
    // The path warped as it is drawn, on the GPU, like After Effects' wave
    // warp. warp is the height
    // of the wave and warp_width its length, both as shares of the layer's
    // height. warp_angle is
    // the angle it runs at, in degrees. warp_speed is the number of waves per
    // second along it.
    {"warp", "shape", -10, 10, true, nullptr},
    {"warp_width", "shape", 0.001, 100, true, nullptr},
    {"warp_angle", "shape", -1e6, 1e6, true, nullptr},
    {"warp_speed", "shape", -1e3, 1e3, true, nullptr},
    // Points moved as the layer is drawn, on the GPU, for a shape of one color
    // only (flat_mesh).
    // bend is Cavalry's bend, in degrees round, across it or up it. twist is
    // After Effects' twist,
    // in degrees, most at the middle. pinch is Cavalry's pinch, in, or out when
    // less than 0. skew
    // is in degrees, along an axis turned by skew_axis. squash is squash and
    // stretch: taller and as
    // much narrower, keeping its area. wiggle is After Effects' wiggle paths:
    // how far as a share of
    // its height, wiggle_detail how fine, and wiggle_speed how fast.
    {"bend", "shape", -1e4, 1e4, true, nullptr},
    {"bend_direction", "shape", 0, 0, false, "horizontal vertical"},
    {"twist", "shape", -1e5, 1e5, true, nullptr},
    {"pinch", "shape", -1, 1, true, nullptr},
    {"skew", "shape", -89, 89, true, nullptr},
    {"skew_axis", "shape", -1e4, 1e4, true, nullptr},
    {"squash", "shape", -0.95, 10, true, nullptr},
    {"wiggle", "shape", -10, 10, true, nullptr},
    {"wiggle_detail", "shape", 0, 1000, true, nullptr},
    {"wiggle_speed", "shape", -1e3, 1e3, true, nullptr},
    // Cavalry's motion stretch: longer in the direction the layer moves, and
    // narrower, by this much
    // for each unit per second it goes.
    {"stretch", "shape", -10, 10, true, nullptr},
    // After Effects' corner pin: how far each corner is moved, as shares of the
    // layer's height, up
    // and right. Everything between follows.
    {"pin_tl_x", "shape", -10, 10, true, nullptr},
    {"pin_tl_y", "shape", -10, 10, true, nullptr},
    {"pin_tr_x", "shape", -10, 10, true, nullptr},
    {"pin_tr_y", "shape", -10, 10, true, nullptr},
    {"pin_bl_x", "shape", -10, 10, true, nullptr},
    {"pin_bl_y", "shape", -10, 10, true, nullptr},
    {"pin_br_x", "shape", -10, 10, true, nullptr},
    {"pin_br_y", "shape", -10, 10, true, nullptr},
    // copies: how many copies there are. Each copy is the one before moved,
    // turned about its anchor
    // and scaled by the same amount, like After Effects' Repeater. Where each
    // lies is up to its
    // script: shelves/create/repeats/repeater.js lays them in rows, turns,
    // scales and scatters
    // them.
    {"copies", "image text shape solid", 1, 1000, false, nullptr},
    // How much later the last copy moves than the first, in seconds. Each is as
    // late as its order
    // says.
    {"stagger", "image text shape solid", 0, 1e3, false, nullptr},
    // Which copy moves first: the first, the middle one, the last, or the outer
    // ones.
    {"stagger_from", "image text shape solid", 0, 0, false,
     "start centre end edges"},
    // Its copies colored from the first color to the last, in their order, as
    // six hex digits each.
    // One color colors all of them. none means the copies are not colored
    // individually.
    {"copy_fill", "image text shape", 0, 0, false, ""},
    // ramp goes from the first color to the last across all the copies. cycle
    // gives each copy one
    // color in turn, round and round.
    {"copy_fill_way", "image text shape", 0, 0, false, "ramp cycle"},
    // How many times as tall as it is, its anchor staying where it is: a bar
    // growing up from its
    // foot.
    {"tall", "image text shape", 0, 1e3, true, nullptr},
    // Its copies each so many times as tall again, in their order, going round:
    // numbers, such as
    // the data of a bar chart. none means all copies are equally tall.
    {"copy_tall", "image text shape solid", 0, 0, false, ""},
    // Where along copy_fill each copy's color is, given by a behavior
    // (copy_fill_at_by): 0 is the
    // first color, 1 the last. If not given, the copies' order decides.
    {"copy_fill_at", "image text shape", 0, 1, true, nullptr},
    // The last copy is as transparent as this and the first as the layer
    // itself. After Effects'
    // Repeater, End Opacity.
    {"copy_opacity_end", "image text shape", 0, 1, true, nullptr},
    // Its copies laid on another shape's outline, each turned the way the
    // outline goes, like
    // Cavalry's Duplicator on a shape. copy_on_offset slides them along it, as
    // a share of its
    // length.
    {"copy_on", "image text shape solid", 0, 1e9, false, nullptr},
    {"copy_on_offset", "image text shape solid", -1e4, 1e4, true, nullptr},
    // The layer whose copies its own copies join, one each from one to another:
    // lines between dots.
    // 0 means none.
    {"connect", "shape", 0, 1e9, false, nullptr},
    // Another layer: the nth copy of the first layer is joined to the nth copy
    // of this one, like
    // rungs between two strands. 0 means within the first layer.
    {"connect_to", "shape", 0, 1e9, false, nullptr},
    // Only copies nearer than this, in units of the stage, are joined: a
    // plexus. 0 joins each to
    // the next in their order.
    {"connect_reach", "shape", 0, 1e4, true, nullptr},
    // Put together with another shape, like Cavalry's Boolean: subtract is its
    // own less that one,
    // intersect is where both are, union is either, and exclude is either but
    // not both.
    {"boolean", "shape", 0, 0, false, "union subtract intersect exclude"},
    // The other shape, seen where it lies. 0 means none.
    {"boolean_with", "shape", 0, 1e9, false, nullptr},
    // Walks the outline again at this many points per outline, straight between
    // them, like
    // Cavalry's Resample Path: a circle becomes a polygon. 0 leaves it as made.
    {"resample", "shape", 0, 2048, true, nullptr},
    // Made of squares this large, as a share of its height, like Cavalry's
    // Voxelize. 0 leaves it as
    // it is.
    {"voxel", "shape", 0, 1, true, nullptr},
    // Roughened like Illustrator's Roughen. rough is how far points go out, as
    // a share of the
    // layer's height. rough_detail is how often a point is placed, in the same
    // units.
    {"rough", "shape", 0, 0.5, true, nullptr},
    {"rough_detail", "shape", 0.005, 1, true, nullptr},
    // How outlines that lie over each other are filled: filled, or a hole every
    // other time, as
    // SVG's and Cavalry's fill rule.
    {"fill_rule", "shape", 0, 0, false, "nonzero evenodd"},
    // A behavior, like Cavalry's: it gives each copy of what it is connected to
    // (`<name>_by` set to
    // it) a value, by the copy's number and the time. stagger gives values from
    // minimum to maximum
    // in the copies' order. oscillator waves, with frequency as times per
    // second, offset as a share
    // of a wave, and stagger as degrees of a wave between copies. noise is a
    // smooth noise. random
    // gives values at random by its seed.
    {"minimum", "behaviour", -1e6, 1e6, true, nullptr},
    {"maximum", "behaviour", -1e6, 1e6, true, nullptr},
    {"frequency", "behaviour", 0, 1000, true, nullptr},
    {"offset", "behaviour", -1e6, 1e6, true, nullptr},
    {"stagger", "behaviour", -1e6, 1e6, true, nullptr},
    {"seed", "behaviour", 0, 1e9, false, nullptr},
    // What it gives is rounded to this many: 90 turns a quarter at a time. 0
    // means no rounding.
    {"step", "behaviour", 0, 1e6, true, nullptr},
    // Falloff, like Cavalry's: where the behavior works. Inside the shape named
    // by region, which
    // can be any shape, seen or not, moving or not, it works fully, and outside
    // it not at all.
    // Between the two it fades over falloff_soft units of the stage. With
    // falloff_invert it is the
    // other way round. Elsewhere the value is the layer's own.
    {"region", "behaviour", 0, 1e9, false, nullptr},
    {"falloff_soft", "behaviour", 0, 1e4, true, nullptr},
    {"falloff_invert", "behaviour", 0, 1, false, nullptr},
    // A relation is a behavior that sets its layers in relation to each other
    // or to one of them. It is a script file in shelves/relations/ whose own
    // parameters are values of its layer (js_ plus the name). strength is how
    // much of the relation works: 0 is as if it were not there, so a relation
    // can be put on and taken off over time without a jump.
    {"strength", "behaviour", 0, 1, true, nullptr},
    // A relation's layers in their order, by number, with "_" where one was
    // removed. Its place is
    // kept so that no other layer moves.
    {"members", "behaviour", 0, 0, false, ""},
    // For each member, the relation it was in before, 0 meaning none. This
    // relation starts from
    // what that one gives.
    {"under", "behaviour", 0, 0, false, ""},
    // For each member, x and y where it showed when it joined. A relation's
    // script is told it as `from`, so it can add only the step from there to
    // its place.
    {"from", "behaviour", 0, 0, false, ""},
    // Turned into another shape by this much, like Cavalry's Morph: 0 is
    // itself, 1 is the other
    // shape where it lies.
    {"morph", "shape", 0, 1, true, nullptr},
    // The path follows another layer's track, like Cavalry's Trails: trail
    // names whose, and
    // trail_length over how many seconds back.
    {"trail", "shape", 0, 1e9, false, nullptr},
    {"trail_length", "shape", 0.001, 60, true, nullptr},
    {"morph_to", "shape", 0, 1e9, false, nullptr},
    // So many steps from the layer to its target, shown all at once as a blend.
    // 0 or 1 means none.
    {"morph_steps", "shape", 0, 64, false, nullptr},
    // Freehand strokes as they were drawn, separated by ";". Each has its tool
    // (0 pen, 1 brush, 2
    // fill, 3 eraser), its width, and then each point as x, y and pressure, in
    // the path's own
    // units. Made by AbsentMotion, see doc_brush.
    {"drawing", "shape", 0, 0, false, ""},
    // A path shape's own path, drawn with a pen: SVG path data, in units of its
    // height from its
    // middle, with y pointing down as in SVG.
    {"path", "shape", 0, 0, false, ""},
    // Another seed gives another wiggle of the path (evaluate.h).
    {"seed", "shape", 0, 1e6, false, nullptr},
    // More edges, each outside the last: Alight Motion's Add Border,
    // Illustrator's Appearance.
    {"stroke_2", "text", 0, 0, false, ""},
    {"stroke_2_width", "text", 0, 1000, false, nullptr},
    {"stroke_3", "text", 0, 0, false, ""},
    {"stroke_3_width", "text", 0, 1000, false, nullptr},
    // Its edge: a color, and how wide it is in points of the image at size 1.
    {"stroke", "text shape image", 0, 0, false, ""},
    {"stroke_width", "text shape image", 0, 1000, false, nullptr},
    // ThorVG's own: a text's letters and lines spaced so many times as far
    // apart as the font sets
    // them, and its slant. Also an edge's ends and corners, and dashes along it
    // that long, with
    // gaps as long, begun so far along.
    // Its lines broken in a box that many times as wide as its letters are
    // high, using ThorVG's
    // layout and wrap. A text's size is the height of all its lines, so this
    // goes with the letters,
    // not the image.
    {"wrap", "text", 0, 0, false,
     "none character word smart ellipsis vertical"},
    {"wrap_at", "text", 0, 1000, false, nullptr},
    // One line split into its letters or its words, each a copy of its own.
    // They lie where they
    // are, and move, wave and are colored each in their order.
    {"split", "text", 0, 0, false, "none letters words"},
    {"letter_spacing", "text", 0, 10, false, nullptr},
    {"line_spacing", "text", 0, 10, false, nullptr},
    {"italic", "text", 0, 0.5, false, nullptr},
    // A fill of two colors or more: across (linear, ThorVG's linear gradient)
    // or from the middle
    // out (radial, ThorVG's radial gradient). gradient_angle turns it, in
    // degrees clockwise, 0
    // being from top to bottom. gradient_scale is its length as a share of how
    // far it reaches.
    // gradient_spread chooses what happens past its ends: padded, reflected or
    // repeated.
    {"gradient", "text shape", 0, 0, false, "linear radial"},
    {"gradient_angle", "text shape", -1e6, 1e6, false, nullptr},
    {"gradient_scale", "text shape", 0.01, 100, false, nullptr},
    {"gradient_spread", "text shape", 0, 0, false, "pad reflect repeat"},
    // How the colors between its stops are mixed: CSS Color 4's
    // color-interpolation-method
    // (canvas_renderables.h, ramp_of).
    {"gradient_blend", "text shape", 0, 0, false, "rgb oklab hue steps"},
    {"cap", "shape", 0, 0, false, "butt round square"},
    {"join", "shape", 0, 0, false, "miter round bevel"},
    // After Effects' Bevel Style and Depth. Ogee and Step are Easy
    // Typography's.
    {"bevel", "text shape image", 0, 0, false,
     "none angular convex concave ogee step"},
    {"bevel_depth", "text shape image", 0, 4096, true, nullptr},
    // A thick layer's other faces, like After Effects' Bevel, Side and Back
    // Color, each with its
    // own metallic and roughness. If not set, they are as its front.
    {"bevel_color", "text shape image", 0, 0, false, ""},
    {"bevel_metallic", "text shape image", 0, 1, false, nullptr},
    {"bevel_roughness", "text shape image", 0, 1, false, nullptr},
    {"side_color", "text shape image", 0, 0, false, ""},
    {"side_metallic", "text shape image", 0, 1, false, nullptr},
    {"side_roughness", "text shape image", 0, 1, false, nullptr},
    {"back_color", "text shape image", 0, 0, false, ""},
    {"back_metallic", "text shape image", 0, 1, false, nullptr},
    {"back_roughness", "text shape image", 0, 1, false, nullptr},
    // Arrow heads on the open ends of its edge, like Cavalry's basicArrowHead:
    // which ends, and the
    // head's size as a multiple of the edge's length.
    {"heads", "shape", 0, 0, false, "none end start both"},
    {"head_size", "shape", 0.5, 40, false, nullptr},
    {"head_shape", "shape", 0, 0, false,
     "arrow circle box chevron bar t_line square square_filled diamond "
     "diamond_filled arrow_hollow arrow_filled circle_hollow circle_filled "
     "teardrop_hollow teardrop_filled"},
    {"head_start", "shape", 0, 0, false,
     "arrow circle box chevron bar t_line square square_filled diamond "
     "diamond_filled arrow_hollow arrow_filled circle_hollow circle_filled "
     "teardrop_hollow teardrop_filled"},
    {"dash", "shape", 0, 1000, false, nullptr},
    {"dash_offset", "shape", -1e4, 1e4, false, nullptr},
    // Filament's own surface of a solid in a color: how metallic, how rough,
    // how much it reflects,
    // a clear coat over it and how rough that is, and how much it lights
    // itself. For emissive, 1 is
    // its color itself on the image and more is brighter still.
    {"metallic", "solid text shape image video", 0, 1, false, nullptr},
    {"roughness", "solid text shape image video", 0, 1, false, nullptr},
    {"reflectance", "solid text shape image video", 0, 1, false, nullptr},
    // A solid filled with glass, the render code's own: ior is how much it
    // bends light (index of
    // refraction), dispersion how far its colors part, swim how much what is
    // behind it swims, dark
    // how fast a long way through it goes dark, and vivid how vivid what is
    // seen through it is.
    {"ior", "video image text shape solid", 1, 3, false, nullptr},
    {"dispersion", "video image text shape solid", 0, 0.5, false, nullptr},
    {"swim", "video image text shape solid", 0, 1, false, nullptr},
    {"dark", "video image text shape solid", 0, 20, false, nullptr},
    {"vivid", "video image text shape solid", 0, 3, false, nullptr},
    {"clear_coat", "video image text shape solid", 0, 1, false, nullptr},
    {"clear_coat_roughness", "video image text shape solid", 0, 1, false,
     nullptr},
    {"emissive", "video image text shape solid", 0, 20, true, nullptr},
    // Filament's velvet sheen at its rim, in its own color.
    {"sheen", "video image text shape solid", 0, 1, false, nullptr},
    // The material the layer wears, for any layer that is seen (Create's
    // Material group,
    // doc_material). shading chooses among Filament's shading models: lit,
    // cloth (soft, no sharp
    // highlight) and subsurface (light goes in, as in skin or wax); the render
    // code's thick glass
    // (thick_glass.mat); Filament's own glass (own_glass.mat); lacquer
    // (blade.mat); and a bubble
    // (bubble.mat). thickness is how thick it is to the light going through.
    {"shading", "video image text shape solid", 0, 0, false,
     "lit cloth subsurface glass filament_glass lacquer bubble"},
    {"thickness", "video image text shape solid", 0, 1, false, nullptr},
    // Highlights drawn out as on brushed metal. A negative value draws them out
    // the other way.
    {"anisotropy", "video image text shape solid", -1, 1, false, nullptr},
    // A camera's lens, Filament's own: projection can be orthographic, drawn
    // without depth so that
    // far is as large as near, as in an axonometric drawing. shift_x and
    // shift_y shift the lens
    // across and up, in shares of the image. A shift lens keeps uprights
    // upright.
    {"projection", "camera", 0, 0, false, "perspective orthographic"},
    {"shift_x", "camera", -2, 2, true, nullptr},
    {"shift_y", "camera", -2, 2, true, nullptr},
    // The stage's own values, on layer 0: the whole image, Filament's own. The
    // render_ values describe how a video is exported: its height, frames per
    // second, megabits per second, and how many times samples are laid on one
    // another for motion blur. 0 means as it was. The color grading, bloom,
    // vignette, fog and the like are Filament viewer settings files on the
    // shelf (see stage/effects/viewer_settings.h).
    {"render_height", "stage", 0, 8640, false, nullptr},
    {"render_rate", "stage", 0, 60, false, nullptr},
    {"render_mbps", "stage", 0, 500, false, nullptr},
    {"render_blur", "stage", 0, 64, false, nullptr},
    {"render_alpha", "stage", 0, 1, false, nullptr},
    // Which room lights the stage: the rooms made ready in out/.
    {"room", "stage", 0, 0, false,
     "small_studio studio_small_02_2k lightroom venetian_crossroads_2k "
     "graffiti_shelter_2k parking_garage_2k pillars_2k"},
    {"environment", "stage", 0, 10, false, nullptr},
    {"environment_rotate", "stage", -1e6, 1e6, false, nullptr},
    {"background", "stage", 0, 0, false, ""},
    // What is behind everything: the background's color, or the room itself.
    {"behind", "stage", 0, 0, false, "colour room"}};

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_KINDS_H_
