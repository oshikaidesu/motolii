// Recipe files and the folders the shelves are read from. Included by doc.h; not self-contained.
//
// A recipe creates several layers in one call. It is what Cavalry's tutorials build from a shape,
// a duplicator and one or two behaviours, each named. Each recipe is one file in create/, either
// in the library's folder or in the user's own folder (see doc_folders). A file put there shows
// up on the shelf at once.
//
// The head of a recipe file is:
//   // Name: what it makes
//   // make kind file
// followed by the first layer's values, one per line:
//   set name number
//   say name words
//   key name seconds number
// and "then kind file" to add another layer. Parameters are written as script.h describes. Any
// code below the head is the first layer's script.
// `program` is the program a closed pack was written for. Such a recipe is listed on the Program
// shelf instead of Create; it is "" for the recipes of Create.
struct DocRecipe { std::string name, what, path, program; std::vector<std::string> lines; bool code = false; };
static std::vector<DocRecipe> doc_recipes_read();
// Returns engine/<part>, the directory of a part of the engine that is not a shelf. Examples are
// third_party/'s p5.js and anime.js, and Filament's fonts and matc. It is found relative to this
// library, whose out/ directory lies in engine/.
static std::filesystem::path doc_engine(const char* part) { Dl_info lib{}; dladdr((const void*)&doc_engine, &lib); std::error_code wrong; return std::filesystem::weakly_canonical(lib.dli_fname ? lib.dli_fname : ".", wrong).parent_path().parent_path() / part; }
// Returns the folders that files of one kind are read from, in increasing priority.
//
// First comes the library's folder, shelves/<folder>, beside the engine/ directory whose out/
// holds this library. Then come the user's own folders, under MOTOLII_OWN, or %APPDATA%/Motolii on
// Windows, or ~/Library/Application Support/Motolii on a Mac. When a file name occurs in several
// folders, the user's file wins.
//
// A shelf is named as the app shows it: Create, Expression, Ease. Before the shelves were renamed
// the user's folders were recipes, animators and ways. A folder under an old name is still read,
// before the folder under the new name, so files put there stay on the shelf.
//
// Some folders hold data the engine reads and are not shelves. The library's copy of those is in
// engine/third_party/ with its license. The user's own folder of that name still adds to it.
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
// Returns the files of one kind in those folders. `extension` is one extension or several
// separated by spaces. A file from a later folder replaces one of the same name from an earlier
// folder, so the user's files win over the library's.
static std::vector<std::filesystem::path> doc_folder_files(const char* folder, const char* extension) {
    // `wrong` receives filesystem errors. A folder that does not exist yields no files.
    std::map<std::string, std::filesystem::path> by; std::error_code wrong;
    const auto take = [&](const std::filesystem::path& p) { if ((" " + std::string(extension) + " ").find(" " + p.extension().string() + " ") != std::string::npos && p.has_extension()) by[p.filename().string()] = p; };
    // effects/ and create/ keep one subfolder per origin or purpose, such as blur/ or shapes/,
    // and are read recursively.
    for (const auto& dir : doc_folders(folder))
        if (std::string(folder) == "effects" || std::string(folder) == "create") for (const auto& e : std::filesystem::recursive_directory_iterator(dir, wrong)) take(e.path());
        else for (const auto& e : std::filesystem::directory_iterator(dir, wrong)) take(e.path());
    std::vector<std::filesystem::path> files;
    for (const auto& [_, f] : by) files.push_back(f);
    return files;
}
// Returns whether a kind of file has to be read again, and updates `seen`. The first call with
// seen == -1 returns true. After that it returns true when the app has reported a file put in,
// removed or overwritten (files_changed). The app calls this on every build.
static bool doc_folder_moved(int& seen) {
    if (seen == files_changed()) return false;
    seen = files_changed();
    return true;
}
// Returns all recipes, rereading the files only when they have changed.
static std::vector<DocRecipe> doc_recipes() {
    static std::vector<DocRecipe> all;
    static int seen = -1;
    if (doc_folder_moved(seen)) all = doc_recipes_read();
    return all;
}
