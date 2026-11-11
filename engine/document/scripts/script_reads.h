#ifndef MOTOLII_DOCUMENT_SCRIPTS_SCRIPT_READS_H_
#define MOTOLII_DOCUMENT_SCRIPTS_SCRIPT_READS_H_

// What the JavaScript on a layer may read of the rest of the project. The
// functions are declared in community/script_runner/script_runner.h; this is
// what answers them from the open project.
//
//   layerValue(id, name, t, otherwise, copy): what layer `id` shows for `name`
//     (one of doc_relate_names) at second t, with any relations it is in.
//     `otherwise` is given where the layer has no keyframes for it. With
//     `copy`, x, y and z are where the middle of that copy (a split text's
//     letter) is. An expression that asks this of its own layer (k.id) while
//     the layer's copies are being laid is told where they lie without the
//     layer's script and expressions: where they are before it moves them.
//
//   sampleImage(id, point, radius, postEffect, t): After Effects' sampleImage
//     (ae-expressions.docsforadobe.dev/layer/general/) of layer `id`: the
//     alpha-weighted average [red, green, blue, alpha] of the rectangle
//     `radius` around `point`, in the layer's own pixels, [0, 0] the centre of
//     its upper-left pixel. The arithmetic is stage/canvas/image_pixels.h's.
//
//   fromWorld(id, point, t): After Effects' fromWorld
//     (ae-expressions.docsforadobe.dev/layer/space-transforms/): where a point
//     of the stage, in stage units as layerValue gives x and y, is in the
//     pixels of layer `id`.
//
//   getByteFrequencyData, getFloatFrequencyData and getFloatTimeDomainData
//     (id, array, t): the Web's AnalyserNode methods (W3C Web Audio API, section 1.8) on the sound
//     of video layer `id`, a sound file being a video layer that is heard and
//     not seen: how strong each pitch is, and the wave. The second of the file
//     is the one the layer plays at t, as for its picture. The file's sound is
//     read whole the first time it is asked for, and that is waited for
//     (media/sound_level.h, which says how the numbers are worked out). Before
//     the layer comes on, after it has gone, and for any other layer: zeros.
//     The layer's volume and its sound effects are not taken in.
//
// What a picture is read from, today:
//   - An image layer: its file, drawn by ThorVG at its own size.
//   - A video layer: the frame of its file that the layer shows at second t
//     (its cut, speed and loop as media/video_layer.cpp plays them), decoded on
//     the CPU by GStreamer at the file's own size, sixty frames a second
//     (media/video_frames_for_scripts.h). A frame is decoded when first asked;
//     asking earlier and later times in turn seeks each time.
//   - Any other layer: nothing, [0, 0, 0, 0].
// Not done: postEffect. Both ways read the file, before the layer's masks,
// key and effects, which are drawn on the GPU. A datamoshed video is read as
// its file was before. A video's rotation tag is not applied.

namespace motolii {

struct Doc;
class Script;

// Makes `run` ask the project `d` for layerValue, sampleImage, fromWorld and
// the three that read sound.
// `d` must outlive the calls of `run`, which are made on the thread that holds
// it.
void doc_script_reads(Doc& d, Script& run);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_SCRIPTS_SCRIPT_READS_H_
