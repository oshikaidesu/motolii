// Tests for script_files() in community/quickjs/script.h, which splits a
// layer's list of files.
//
// The expected values come from the comment on script_files(): a word with a
// "/" is a path that may hold spaces, and it runs on until a word ends as a
// file of a known kind does. A .css file is such a file: a layer's effect list
// takes one as an expression (doc_expression, document/scripts/expressions.cpp).

#include <string>
#include <vector>

#include <gtest/gtest.h>

#include "community/quickjs/script.h"

namespace motolii {
namespace {

// (paths that do not exist: script_shelf_file returns them unchanged)
TEST(ScriptFiles, APathWithSpacesRunsToTheEndOfItsFile) {
  EXPECT_EQ(script_files("/no where/Bad TV.fs /no where/b.js"),
            (std::vector<std::string>{"/no where/Bad TV.fs", "/no where/b.js"}));
}

TEST(ScriptFiles, ACssFileEndsItsPathSoTheNextFileIsItsOwn) {
  EXPECT_EQ(script_files("/nowhere/a.css /nowhere/b.js"),
            (std::vector<std::string>{"/nowhere/a.css", "/nowhere/b.js"}));
}

}  // namespace
}  // namespace motolii
