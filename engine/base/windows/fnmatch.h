#ifndef MOTOLII_BASE_WINDOWS_FNMATCH_H_
#define MOTOLII_BASE_WINDOWS_FNMATCH_H_
// POSIX's <fnmatch.h> on Windows: a name matched against a pattern of * and ? by the shell's own PathMatchSpec (no
// flags: a * crosses '/', as fnmatch's does without FNM_PATHNAME). Returns 0 when it matches, as fnmatch does.
#include <windows.h>
#include <shlwapi.h>
#pragma comment(lib, "shlwapi.lib")
inline int fnmatch(const char* pattern, const char* name, int) { return PathMatchSpecA(name, pattern) ? 0 : 1; }
#endif  // MOTOLII_BASE_WINDOWS_FNMATCH_H_
