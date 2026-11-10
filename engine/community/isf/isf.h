#ifndef MOTOLII_COMMUNITY_ISF_ISF_H_
#define MOTOLII_COMMUNITY_ISF_ISF_H_

// Reads ISF effect files (.fs) as .wgsl effect files. The conversion is done in
// isf.cpp and cached on disk, so each file is converted only once per change.
#include <string>

// Returns the .wgsl file to read for an effect file. A file that is not ISF is
// returned as it is. For a .fs file, returns the converted .wgsl, or "" if the
// conversion failed.
std::string isf_file(const std::string& file);

// Returns why the current content of the file could not be converted to WGSL.
// Returns "" if it was converted, or if isf_file has not been called for it
// yet. Meanwhile isf_file keeps returning the last successful conversion.
std::string isf_trouble(const std::string& file);

// Returns tags describing what an ISF effect does, read from the file itself so
// that nobody has to label it by hand. Shadertoy also flags its shaders from
// what they define and filters by it. The tags are separated by spaces and come
// from: transition, generator, sound, multipass, feedback, time, image. Returns
// "" if there are none or if the file is not ISF.
std::string isf_tags(const std::string& file);

// Returns the file that a duplicated effect is a copy of. Duplicating an effect
// card (doc_fx_duplicate) names the copy like "Glow~2.fs" beside "Glow.fs". The
// copy is read from the original file, while its parameter values stay its own
// because a parameter's name comes from its file (doc_screen_parameter). Any
// other file is returned as it is.
std::string fx_source(const std::string& f);

#endif  // MOTOLII_COMMUNITY_ISF_ISF_H_
