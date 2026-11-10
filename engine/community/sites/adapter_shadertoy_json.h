#ifndef MOTOLII_COMMUNITY_SITES_ADAPTER_SHADERTOY_JSON_H_
#define MOTOLII_COMMUNITY_SITES_ADAPTER_SHADERTOY_JSON_H_

// Reads a Shadertoy shader as the site stores it, with all its tabs, into
// adapter_tabs_isf (adapter_shadertoy.h). Follows rust_ae's
// isf_from_shadertoy_project and uses the JSON's own field names.

#include <string>

// Converts the JSON of a Shadertoy shader, as given by the site's API or its
// Export, with all its tabs, into one ISF text. Returns "" and sets `why` if it
// cannot be converted. A sound tab is left out, as VVISF leaves it out. A
// cubemap tab draws something nothing here can read, so it is an error.
std::string adapter_shadertoy(const std::string& json, std::string& why);

#endif  // MOTOLII_COMMUNITY_SITES_ADAPTER_SHADERTOY_JSON_H_
