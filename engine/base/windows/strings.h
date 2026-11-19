#ifndef MOTOLII_BASE_WINDOWS_STRINGS_H_
#define MOTOLII_BASE_WINDOWS_STRINGS_H_
// POSIX's <strings.h> on Windows, for outside code that includes it as it is
// (AbsentMotion's drawing.cpp): its case-blind comparisons under the C
// runtime's names. Seen only by the targets that put this folder on their path.
#include <string.h>
#define strcasecmp _stricmp
#define strncasecmp _strnicmp
#endif  // MOTOLII_BASE_WINDOWS_STRINGS_H_
