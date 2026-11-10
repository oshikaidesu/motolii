#ifndef MOTOLII_ENTRY_CALLS_TIME_H_
#define MOTOLII_ENTRY_CALLS_TIME_H_
// Implements the time calls of motolii.h: the project's length and current time, its poster image
// and properties (read without opening it), a still image of the preview, and the watch on the
// app's main thread.

// Returns true if name ends with the suffix and is longer than it.
bool ends(const char* name, const char* with);
// Returns true if the folder that would contain the file exists.
bool placed(const char* name);

#endif  // MOTOLII_ENTRY_CALLS_TIME_H_
