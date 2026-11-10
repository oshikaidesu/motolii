#ifndef MOTOLII_COMMUNITY_THREE_THREE_ISF_H_
#define MOTOLII_COMMUNITY_THREE_THREE_ISF_H_

// Declares the converter from a three.js screen effect (examples/jsm/shaders/*.js)
// to ISF effect text, which isf.cpp then loads like any other ISF effect.
#include <string>
// Returns true if the file is a three.js effect: a .js file containing a
// fragmentShader.
bool three_is(const std::string& file);
// Returns the ISF text for the effect in `file`. On failure returns an empty
// string and sets `why` to the reason.
std::string three_isf(const std::string& file, std::string& why);

#endif  // MOTOLII_COMMUNITY_THREE_THREE_ISF_H_
