#ifndef MOTOLII_COMMUNITY_SITES_ADAPTER_NET_H_
#define MOTOLII_COMMUNITY_SITES_ADAPTER_NET_H_

// Fetches things from the net for the adapters in adapter.h. Downloads use curl, started directly
// with no shell in between.
// Also reads works from OpenProcessing. A work named by its address is fetched through the site's
// public API (openprocessing.org/api: its tabs, libraries, files and license) and laid out in a
// folder the way a saved page is, so the adapter reads it like any other page. The site allows 40
// requests a minute. A work takes 3 requests plus one for each of its files.

#include <filesystem>
#include <string>

// Downloads `url` to the file `to` with curl. Redirects are followed only over http and https, and
// the download stops after 60 seconds. Returns true on success.
bool adapter_fetch(const std::string& url, const std::filesystem::path& to);

// Returns the number of the work if `word` is the address of an OpenProcessing sketch, or "" if it
// is not.
std::string adapter_site_work(const std::string& word);

// Downloads the OpenProcessing work `id` into the directory `at`, with its code tabs and files, and
// returns the path of the HTML page that loads them. On failure returns an empty path and sets
// `why` to the reason.
std::filesystem::path adapter_openprocessing(const std::string& id, const std::filesystem::path& at, std::string& why);

#endif  // MOTOLII_COMMUNITY_SITES_ADAPTER_NET_H_
