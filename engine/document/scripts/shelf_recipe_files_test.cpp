// Tests that every file named by a file on the shelves exists, so that moving
// or renaming a file can never quietly break a recipe, a script or an effect.
//
// These tests read the real shelves/ folder of this repository. The expected
// value is always the same and comes from outside the engine: the named file
// is there. Which lines name a file, and where each path is looked for, come
// from the documents of the readers of those lines:
//   - A recipe's "say script <shelf>/<file>", "say script <recipe's name>" and
//     "make <kind> <file>": document/scripts/folders.h (the head of a recipe)
//     and script_shelf_file() in community/quickjs/script.h.
//   - import and require in a .js or .mjs: from the file's own folder, as
//     QuickJS's module loader resolves a relative name
//     (https://github.com/quickjs-ng/quickjs, quickjs.c,
//     js_default_module_normalize_name). A bare module name must be one the
//     engine itself gives.
//   - "// --image@name:file" in an effect and "PATH": "file" in an ISF shader:
//     beside the effect (stage/effects/screen_fx.h; ISF's IMPORTED,
//     https://github.com/mrRay/ISF_Spec).
//   - A quoted "./..." or "../..." in a .sh: from where the script's
//     cd "$(dirname "$0")/..." went.
//   - shelves/..., engine/..., app/... and docs/... anywhere in a line: from
//     the repository's root.
// The last four rules are those of rule P in .githooks/path_check.py, whose
// shelf half this file takes over. What may lead nowhere on purpose (a file
// fetched or made at build time, a module the engine gives) is listed, each
// with its reason, in .githooks/path_check_allow.txt, which is read here too.
//
// Not covered here: a preset (.motolii) naming "{motolii}/..." files, because
// reading one needs SQLite, which the test binary does not link.

#include <fnmatch.h>
#include <gtest/gtest.h>

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <regex>
#include <sstream>
#include <string>
#include <vector>

#include "community/quickjs/script.h"
#include "document/scripts/folders.h"
#include "document/scripts/recipes.h"
#include "shelf/shelf_folders.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;

// Returns the repository's root. This file is engine/document/scripts/<name>.
fs::path Root() {
  return fs::path(__FILE__)
      .parent_path()
      .parent_path()
      .parent_path()
      .parent_path();
}

// Returns a path as it is written from the repository's root.
std::string FromRoot(const fs::path& path) {
  return path.lexically_normal().lexically_relative(Root()).generic_string();
}

// Returns "file:line" for a failure message.
std::string Where(const fs::path& file, int line) {
  return FromRoot(file) + ":" + std::to_string(line);
}

// Returns the shelf files whose extension is one of `extensions`, a list
// separated by spaces. The AviUtl2 packages are left out: their scripts find
// their files by AviUtl2's own package.path.
std::vector<fs::path> ShelfFiles(const std::string& extensions) {
  std::vector<fs::path> files;
  std::error_code wrong;
  for (fs::recursive_directory_iterator at(Root() / "shelves", wrong), end;
       at != end; at.increment(wrong)) {
    if (at.depth() == 0 && at->path().filename() == "aviutl_scripts") {
      at.disable_recursion_pending();
      continue;
    }
    const std::string extension = at->path().extension().string();
    if (at->is_regular_file(wrong) && !extension.empty() &&
        (" " + extensions + " ").find(" " + extension + " ") !=
            std::string::npos)
      files.push_back(at->path());
  }
  std::sort(files.begin(), files.end());
  return files;
}

// Returns the lines of a file.
std::vector<std::string> LinesOf(const fs::path& file) {
  std::vector<std::string> lines;
  std::ifstream in(file);
  for (std::string line; std::getline(in, line);) lines.push_back(line);
  return lines;
}

// Returns true if a path may lead nowhere on purpose: `written` or `resolved`
// matches a pattern of .githooks/path_check_allow.txt. Each line of that file
// is a shell pattern, then "#" and the reason.
bool Allowed(const std::string& written, const std::string& resolved) {
  static const std::vector<std::string> patterns = [] {
    std::vector<std::string> read;
    for (std::string line :
         LinesOf(Root() / ".githooks" / "path_check_allow.txt")) {
      line = line.substr(0, line.find('#'));
      line.erase(0, line.find_first_not_of(" \t"));
      line.erase(line.find_last_not_of(" \t\r") + 1);
      if (!line.empty()) read.push_back(line);
    }
    return read;
  }();
  for (const std::string& pattern : patterns) {
    if (fnmatch(pattern.c_str(), written.c_str(), 0) == 0 ||
        fnmatch(pattern.c_str(), resolved.c_str(), 0) == 0)
      return true;
  }
  return false;
}

// Returns the recipes of the library's shelves alone. While they are read,
// MOTOLII_OWN, which says where the user's own shelves are
// (shelf/shelf_folders.h), names a folder that does not exist.
std::vector<DocRecipe> LibraryRecipes() {
  const char* own = std::getenv("MOTOLII_OWN");
  const bool had_own = own != nullptr;
  const std::string kept = had_own ? own : "";
  const fs::path nowhere = fs::path(testing::TempDir()) / "motolii_no_shelves";
  setenv("MOTOLII_OWN", nowhere.c_str(), 1);
  std::vector<DocRecipe> recipes = doc_recipes_read();
  if (had_own)
    setenv("MOTOLII_OWN", kept.c_str(), 1);
  else
    unsetenv("MOTOLII_OWN");
  return recipes;
}

// Splits a recipe's command line as doc_make() reads it: the call, its first
// word, and the rest of the line.
void Split(const std::string& line, std::string* call, std::string* word,
           std::string* rest) {
  std::istringstream words(line);
  words >> *call >> *word;
  std::getline(words, *rest);
  rest->erase(0, rest->find_first_not_of(' '));
}

// Returns the paths a line names from the repository's root: a word that
// starts with shelves/, engine/, app/ or docs/, is not the tail of a longer
// word or path, and ends in a letter, a digit or "_".
std::vector<std::string> RootPathsIn(const std::string& line) {
  const auto word = [](char c) {
    return std::isalnum(static_cast<unsigned char>(c)) || c == '_';
  };
  std::vector<std::string> paths;
  for (size_t at = 0; at < line.size(); ++at) {
    if (at > 0 && (word(line[at - 1]) || std::strchr("/.$~@-", line[at - 1])))
      continue;
    for (const char* top : {"shelves/", "engine/", "app/", "docs/"}) {
      const size_t begin = at + std::strlen(top);
      if (line.compare(at, std::strlen(top), top) != 0) continue;
      size_t end = begin;
      while (end < line.size() &&
             (word(line[end]) || std::strchr("./@+-", line[end])))
        ++end;
      while (end > begin && !word(line[end - 1])) --end;
      if (end == begin) continue;
      paths.push_back(line.substr(at, end - at));
      at = end - 1;
      break;
    }
  }
  return paths;
}

// ---- Where the shelves and the list of allowed paths are.

TEST(ShelfFiles, LibraryShelvesAreBesideTheEngine) {
  // shelf_folders.h: the library's folder comes first and is
  // shelves/<folder>, beside the engine/ directory whose out/ holds the
  // library.
  ASSERT_TRUE(fs::is_directory(Root() / "shelves" / "create"))
      << Root() << " is not the repository's root";
  ASSERT_FALSE(doc_folders("create").empty());
  EXPECT_EQ(fs::weakly_canonical(doc_folders("create").front()),
            fs::weakly_canonical(Root() / "shelves" / "create"));
}

TEST(ShelfFiles, ListOfAllowedPathsIsThere) {
  EXPECT_TRUE(
      fs::is_regular_file(Root() / ".githooks" / "path_check_allow.txt"));
  // The first line of that list: a module the engine gives, not a file.
  EXPECT_TRUE(Allowed("playcanvas", "playcanvas"));
  EXPECT_FALSE(Allowed("shelves/no_such_file.js", "shelves/no_such_file.js"));
}

// ---- What a recipe names (shelves/create/).

TEST(ShelfFiles, EveryScriptARecipeSaysExists) {
  const std::vector<DocRecipe> recipes = LibraryRecipes();
  int said = 0;
  for (const DocRecipe& recipe : recipes) {
    for (const std::string& line : recipe.lines) {
      std::string call, word, script;
      Split(line, &call, &word, &script);
      // "this" is the recipe's own code.
      if (call != "say" || word != "script" || script == "this") continue;
      ++said;
      if (script.find('/') == std::string::npos) {
        // The name of another recipe, whose code is run.
        const bool found = std::any_of(
            recipes.begin(), recipes.end(), [&](const DocRecipe& other) {
              return other.code && other.name == script;
            });
        EXPECT_TRUE(found) << FromRoot(recipe.path) << " says the script "
                           << script << ", but no recipe with code has "
                           << "that name";
      } else {
        // A shelf and a file name, such as expressions/wave.js.
        EXPECT_TRUE(fs::is_regular_file(script_shelf_file(script)))
            << FromRoot(recipe.path) << " says the script " << script
            << ", which is not on the shelves";
      }
    }
  }
  EXPECT_GT(said, 0) << "no recipe says a script: the recipes were not read";
}

TEST(ShelfFiles, EveryFileARecipeMakesALayerFromExists) {
  const std::vector<DocRecipe> recipes = LibraryRecipes();
  int made = 0;
  for (const DocRecipe& recipe : recipes) {
    for (const std::string& line : recipe.lines) {
      std::string call, kind, file;
      Split(line, &call, &kind, &file);
      if (call != "make" && call != "then") continue;
      ++made;
      // "make shape circle" names a shape. A word with a "/" is a file, for
      // example the font of "make text <font file>".
      if (file.find('/') == std::string::npos) continue;
      const fs::path named =
          fs::path(file).is_absolute() ? fs::path(file) : Root() / file;
      EXPECT_TRUE(fs::exists(named))
          << FromRoot(recipe.path) << " makes a " << kind << " from " << file
          << ", which does not exist";
    }
  }
  EXPECT_GT(made, 0) << "no recipe makes a layer: the recipes were not read";
}

// ---- What any shelf file names (rule P of .githooks/path_check.py).

TEST(ShelfFiles, EveryImportOfAScriptExists) {
  // import ... from '<path>', export ... from '<path>', import '<path>',
  // import('<path>') and require('<path>').
  static const std::regex imported(
      R"re((?:\bimport\b[^'"`;]*?\bfrom|\bexport\b[^'"`;]*?\bfrom|)re"
      R"re(\bimport\s*\(?|\brequire\s*\()\s*(['"])([^'"\n]+)\1)re");
  int imports = 0;
  for (const fs::path& file : ShelfFiles(".js .mjs")) {
    int number = 0;
    for (const std::string& line : LinesOf(file)) {
      ++number;
      if (line.find("import") == std::string::npos &&
          line.find("export") == std::string::npos &&
          line.find("require") == std::string::npos)
        continue;
      for (std::sregex_iterator found(line.begin(), line.end(), imported), end;
           found != end; ++found) {
        const std::string written = (*found)[2];
        ++imports;
        if (written.rfind("./", 0) == 0 || written.rfind("../", 0) == 0 ||
            written.rfind("/", 0) == 0) {
          const fs::path target = file.parent_path() / written;
          EXPECT_TRUE(fs::is_regular_file(target) ||
                      Allowed(written, FromRoot(target)))
              << Where(file, number) << " imports " << written
              << ", which is not a file";
        } else {
          EXPECT_TRUE(Allowed(written, written))
              << Where(file, number) << " imports the module " << written
              << ", which is neither a path nor a module the engine gives "
              << "(.githooks/path_check_allow.txt)";
        }
      }
    }
  }
  EXPECT_GT(imports, 0) << "no script imports: the shelves were not read";
}

TEST(ShelfFiles, EveryImageAnEffectNamesIsBesideIt) {
  static const std::regex image(R"re(--image@[^:\s]+:([^\s]+))re");
  static const std::regex isf_path(R"re("PATH"\s*:\s*"([^"]+)")re");
  int images = 0;
  for (const fs::path& file :
       ShelfFiles(".js .mjs .wgsl .fs .am .way .sh .py")) {
    const bool isf = file.extension() == ".fs";
    int number = 0;
    for (const std::string& line : LinesOf(file)) {
      ++number;
      std::vector<std::string> named;
      if (line.find("--image@") != std::string::npos) {
        for (std::sregex_iterator found(line.begin(), line.end(), image), end;
             found != end; ++found)
          named.push_back((*found)[1]);
      }
      if (isf && line.find("\"PATH\"") != std::string::npos) {
        for (std::sregex_iterator found(line.begin(), line.end(), isf_path),
             end;
             found != end; ++found)
          named.push_back((*found)[1]);
      }
      for (const std::string& written : named) {
        ++images;
        const fs::path target = file.parent_path() / written;
        EXPECT_TRUE(fs::is_regular_file(target) ||
                    Allowed(written, FromRoot(target)))
            << Where(file, number) << " names the image " << written
            << ", which is not beside it";
      }
    }
  }
  EXPECT_GT(images, 0) << "no effect names an image: the shelves were not read";
}

TEST(ShelfFiles, EveryRelativePathInAShellScriptExists) {
  static const std::regex cd(
      R"re(^\s*cd\s+"\$\(dirname\s+"\$0"\)(/[^"]*)?")re");
  static const std::regex relative(R"re((['"])(\.\.?/[^'"\s$`{]*)\1)re");
  const std::vector<fs::path> scripts = ShelfFiles(".sh");
  for (const fs::path& file : scripts) {
    // Relative paths are read from the script's folder until it changes to
    // another with cd "$(dirname "$0")/...".
    fs::path base = file.parent_path();
    int number = 0;
    for (const std::string& line : LinesOf(file)) {
      ++number;
      std::smatch went;
      // went[1] is what follows the script's folder: "/..." or nothing.
      if (std::regex_search(line, went, cd))
        base = fs::path(file.parent_path().string() + went[1].str());
      for (std::sregex_iterator found(line.begin(), line.end(), relative), end;
           found != end; ++found) {
        const std::string written = (*found)[2];
        const fs::path target = base / written;
        EXPECT_TRUE(fs::exists(target) || Allowed(written, FromRoot(target)))
            << Where(file, number) << " names " << written << ", but "
            << FromRoot(target) << " does not exist";
      }
    }
  }
  EXPECT_FALSE(scripts.empty()) << "no .sh: the shelves were not read";
}

TEST(ShelfFiles, EveryPathFromTheRepositorysRootExists) {
  int paths = 0;
  for (const fs::path& file :
       ShelfFiles(".js .mjs .wgsl .fs .am .way .sh .py")) {
    int number = 0;
    for (const std::string& line : LinesOf(file)) {
      ++number;
      for (const std::string& written : RootPathsIn(line)) {
        ++paths;
        EXPECT_TRUE(fs::exists(Root() / written) || Allowed(written, written))
            << Where(file, number) << " names " << written
            << ", which does not exist";
      }
    }
  }
  EXPECT_GT(paths, 0) << "no path was found: the shelves were not read";
}

}  // namespace
}  // namespace motolii
