#ifndef MOTOLII_DOCUMENT_SCRIPTS_SCRIPT_READS_H_
#define MOTOLII_DOCUMENT_SCRIPTS_SCRIPT_READS_H_

// What the JavaScript on a layer may read of the rest of the project.
// Expressions normally use the concise JS host API (host_prelude.js: `stage`,
// `layer()`, `audio`, `midi`) or After Effects syntax (`thisComp`, `thisLayer`,
// `effect`, `sourceRectAtTime`, `loopOut`); both delegate to these native
// callbacks registered on `Script` (community/script_runner/script_runner.h):
//   - layerValue(id, name, t, otherwise, copy): any numeric property of any
//     layer (or stage `0`), with relation & copy-center support for the 8
//     relation properties and cycle guard (depth < 4).
//   - layerKeys(id, name), layerNamed(name), layerWord(id, name).
//   - layerBounds(id, t), toWorld(id, point, t), fromWorld(id, point, t),
//     toScreen(point, t), sampleImage(id, point, radius, postEffect, t).
//   - layers(), layerChildren(id), cameraInfo(t), layerEffect(id, fx, param,
//   t).
//   - getByteFrequencyData / getFloatFrequencyData / getFloatTimeDomainData /
//     audioBands(id, t): single layer (`id > 0`) or mixed stage audio (`id <=
//     0`).
//   - midiInfo(layerId, source, channel, t): velocity, pitch, gate, bpm.

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
