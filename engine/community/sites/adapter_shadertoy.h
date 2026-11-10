#ifndef MOTOLII_COMMUNITY_SITES_ADAPTER_SHADERTOY_H_
#define MOTOLII_COMMUNITY_SITES_ADAPTER_SHADERTOY_H_

// Converts a Shadertoy shader to an ISF file with each tab as a pass. Follows VVISF's
// ShadertoyConverter.cpp (BSD-3-Clause), which sorts the buffers first and puts the Image last, and
// rust_ae's shadertoy.rs, which makes each buffer PERSISTENT and FLOAT.
// Each tab's code stays as it was written. What differs between tabs is handled by macros around
// the code:
//   Each iChannel becomes a number that adapter_read interprets. A sampler passed to a function is
//     therefore passed as that number, which Vulkan GLSL could not do with the image itself.
//   Names that more than one tab declares are renamed per tab. On the site the tabs are separate
//     files, but here they are one file. rust_ae refused such shaders, and a macro makes them work.
// The site's built-in uniforms are plain variables, not macros, so a function's own parameter named
// iResolution still works.

#include <string>
#include <vector>

// Removes the declarations that other Shadertoy players add for themselves: shader-toy for VS
// Code's #iChannel lines, GLSL Sandbox's uniforms, and a file's own #version and #define lines.
std::string adapter_toy_clean(const std::string& text);

// One tab of a Shadertoy shader. `name` is its title, `target` is the buffer it draws into or ""
// for the final output, and `code` is its source.
// `channel[n]` says what iChannel n reads: -1 nothing (a keyboard, a sound, a cube, or no input), 0
// the image the effect is applied to, N the Nth buffer. 16 is added where the input is sampled with
// repeat wrapping.
struct AdapterTab {
    std::string name, target, code;
    int channel[4] = {-1, -1, -1, -1};
};

// Builds one ISF effect from the tabs of a shader. `common` is the code of the Common tab. `tabs`
// holds the buffer tabs in order, followed by the Image tab. `film` says whether any channel reads
// the image the effect is applied to. `about` and `credit` fill the DESCRIPTION and CREDIT fields.
std::string adapter_tabs_isf(std::string common, std::vector<AdapterTab> tabs, bool film, const std::string& about = "Shadertoy", const std::string& credit = "");

#endif  // MOTOLII_COMMUNITY_SITES_ADAPTER_SHADERTOY_H_
