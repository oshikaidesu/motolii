#ifndef MOTOLII_SHELF_SHELF_FOLDERS_H_
#define MOTOLII_SHELF_SHELF_FOLDERS_H_

// The folders the shelves are read from: the library's own and the user's.

#include <atomic>
#include <filesystem>
#include <vector>

namespace motolii {

// Counts how many times a watched file or folder was reported as written, added
// or removed (motolii_files_changed). The watching itself runs in the app
// through the operating system (dart:io, on FSEvents), not here. Anything built
// from files rereads its file only when this count changes.
std::atomic<int>& files_changed();

// Returns engine/<part>, the directory of a part of the engine that is not a
// shelf. Examples are third_party/'s p5.js and anime.js, and Filament's fonts
// and matc. It is found relative to this library, whose out/ directory lies in
// engine/.
std::filesystem::path doc_engine(const char* part);
// Returns the folders that files of one kind are read from, in increasing
// priority.
//
// First comes the library's folder, shelves/<folder>, beside the engine/
// directory whose out/ holds this library. Then come the user's own folders,
// under MOTOLII_OWN, or %APPDATA%/Motolii on Windows, or ~/Library/Application
// Support/Motolii on a Mac. When a file name occurs in several folders, the
// user's file wins.
//
// A shelf is named as the app shows it: Create, Expression, Ease. Before the
// shelves were renamed the user's folders were recipes, animators and ways. A
// folder under an old name is still read, before the folder under the new name,
// so files put there stay on the shelf.
//
// Some folders hold data the engine reads and are not shelves. The library's
// copy of those is in engine/third_party/ with its license. The user's own
// folder of that name still adds to it.
std::vector<std::filesystem::path> doc_folders(const char* folder);
// Returns the files of one kind in those folders. `extension` is one extension
// or several separated by spaces. A file from a later folder replaces one of
// the same name from an earlier folder, so the user's files win over the
// library's.
std::vector<std::filesystem::path> doc_folder_files(const char* folder,
                                                    const char* extension);
// Returns whether a kind of file has to be read again, and updates `seen`. The
// first call with seen == -1 returns true. After that it returns true when the
// app has reported a file put in, removed or overwritten (files_changed). The
// app calls this on every build.
bool doc_folder_moved(int& seen);

}  // namespace motolii

#endif  // MOTOLII_SHELF_SHELF_FOLDERS_H_
