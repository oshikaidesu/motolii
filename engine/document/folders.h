// folders.h: part of doc.h (a recipe's form, and the folders the shelves are read from). Read only through doc.h.
// Pictures in one call (what Cavalry's tutorials build from a shape, a duplicator and a behaviour or two, each named):
// a file each in create/ (doc_folders: the library's, the maker's own; a file put there is on the shelf at once). Its head:
// "// Name: what it makes", "// make kind file", then a thing's values, one to a line: "set name number",
// "say name words", "key name seconds number", "then kind file" for another thing; its knobs as script.h says.
// Code below the head is the first thing's script.
struct DocRecipe { std::string name, what, path, program; std::vector<std::string> lines; bool code = false; };   // (program: what a closed pack was written for, listed on the Program shelf, not Create; "" one of Create's)
static std::vector<DocRecipe> doc_recipes_read();
// A part of the engine itself, not a shelf (third_party/'s p5.js, anime.js, Filament's fonts and matc): engine/<part>, where this library's out/ is.
static std::filesystem::path doc_engine(const char* part) { Dl_info lib{}; dladdr((const void*)&doc_engine, &lib); std::error_code wrong; return std::filesystem::weakly_canonical(lib.dli_fname ? lib.dli_fname : ".", wrong).parent_path().parent_path() / part; }
// The folders a kind of file is read from: the library's own (shelves/, beside the engine/ whose out/ this library is in), then the maker's
// own, as a maker's scripts and presets are theirs (MOTOLII_OWN, or %APPDATA%/Motolii on Windows, or
// ~/Library/Application Support/Motolii on a Mac), each with a folder of that kind in it. The maker's of a name stands.
// A shelf is named as the window shows it (Create, Expression, Ease); a maker's folder of the name it had before 2026-11-09
// is read too, before the new one (whose file of a name stands), so what they put there stays on the shelf.
// Not a shelf (nothing brought: data the engine reads), the library's copy is in engine/third_party/ with its licence;
// the maker's own folder of that name still adds to it.
static std::vector<std::filesystem::path> doc_folders(const char* folder) {
    static const std::map<std::string, const char*> before{{"create", "recipes"}, {"expressions", "animators"}, {"ease", "ways"}};
    static const std::map<std::string, const char*> engine_kept{{"words", "third_party/wordnet_ja"}, {"fonts", "third_party/noto_sans_jp"}};
    const auto kept = engine_kept.find(folder);
    std::vector<std::filesystem::path> at{kept != engine_kept.end() ? doc_engine(kept->second) : (doc_engine("..") / "shelves" / folder).lexically_normal()};
    std::filesystem::path own;
    if (const char* o = std::getenv("MOTOLII_OWN")) own = o;
    else if (const char* app = std::getenv("APPDATA")) own = std::filesystem::path(app) / "Motolii";
    else if (const char* home = std::getenv("HOME")) own = std::filesystem::path(home) / "Library" / "Application Support" / "Motolii";
    if (own.empty()) return at;
    if (const auto old = before.find(folder); old != before.end()) at.push_back(own / old->second);
    at.push_back(own / folder);
    return at;
}
// The files of that kind in those folders, by their name (the maker's after the library's: theirs of a name stands).
static std::vector<std::filesystem::path> doc_folder_files(const char* folder, const char* extension) {
    std::map<std::string, std::filesystem::path> by; std::error_code wrong;   // (a folder not there, `wrong`: none from it)
    const auto take = [&](const std::filesystem::path& p) { if ((" " + std::string(extension) + " ").find(" " + p.extension().string() + " ") != std::string::npos && p.has_extension()) by[p.filename().string()] = p; };   // (extensions: one, or a few with spaces between)
    for (const auto& dir : doc_folders(folder))   // (effects/ and create/ a folder for what each does or comes from: blur/, shapes/…, read through)
        if (std::string(folder) == "effects" || std::string(folder) == "create") for (const auto& e : std::filesystem::recursive_directory_iterator(dir, wrong)) take(e.path());
        else for (const auto& e : std::filesystem::directory_iterator(dir, wrong)) take(e.path());
    std::vector<std::filesystem::path> files;
    for (const auto& [_, f] : by) files.push_back(f);
    return files;
}
// Whether a kind of file is to be read again: once at first, then after the window says a file was put in, taken out or
// written over (files_changed). A window asks at every build.
static bool doc_folder_moved(int& seen) {
    if (seen == files_changed()) return false;
    seen = files_changed();
    return true;
}
static std::vector<DocRecipe> doc_recipes() {
    static std::vector<DocRecipe> all;
    static int seen = -1;
    if (doc_folder_moved(seen)) all = doc_recipes_read();
    return all;
}
