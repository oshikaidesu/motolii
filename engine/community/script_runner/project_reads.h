#ifndef MOTOLII_COMMUNITY_SCRIPT_RUNNER_PROJECT_READS_H_
#define MOTOLII_COMMUNITY_SCRIPT_RUNNER_PROJECT_READS_H_

// The functions any script reads the rest of the project with: layerValue,
// layerKeys, layerNamed, sampleImage, fromWorld, getByteFrequencyData,
// getFloatFrequencyData and getFloatTimeDomainData. script_runner.h says what
// each takes and gives; the owner of the Script supplies what answers them
// (Script::reads, reads_pictures, reads_sound).

#include <quickjs.h>

#include <string>

#include "community/script_runner/script_runner.h"

namespace motolii {

// What answers each function. One left empty answers as script_runner.h says
// it does while none is set.
struct ProjectReads {
  Script::LayerReader value;    // layerValue
  Script::ImageSampler sample;  // sampleImage
  Script::PointMapper point;    // fromWorld
  Script::SoundReader sound;    // getByteFrequencyData and the other two
  Script::KeyReader keys;       // layerKeys
  Script::LayerFinder named;    // layerNamed
};

// Gives the JavaScript of `cx` those functions, each bound to its member of
// `answers`, which must stay where it is for as long as `cx` lives. Returns
// true if the text `src` names one of them: such a script asks the project,
// which only the thread that calls it holds.
bool project_reads_give(JSContext* cx, const std::string& src,
                        ProjectReads* answers);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_SCRIPT_RUNNER_PROJECT_READS_H_
