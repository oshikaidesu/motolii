// Tests for path_with() and add_to_path() in base/search_path.h. The expected
// values come from the contract written there: extra directories go last, an
// existing entry (exact match) is not added again, an empty PATH never gets a
// leading ':', and "/dir/" is a different entry from "/dir".

#include "base/search_path.h"

#include <gtest/gtest.h>

#include <cstdlib>
#include <string>

namespace motolii {
namespace {

// A PATH written as on the Mac, with the separator of this OS (base/posix.h's
// path_separator).
std::string P(std::string path) {
  for (char& c : path)
    if (c == ':') c = path_separator;
  return path;
}

TEST(PathWith, EmptyPathGivesJustTheExtraDirectories) {
  EXPECT_EQ(P("/opt/homebrew/bin:/usr/local/bin"), path_with(""));
  EXPECT_EQ("/x", path_with("", {"/x"}));
}

TEST(PathWith, FinderLikePathGetsBothAppended) {
  EXPECT_EQ(P("/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin"),
            path_with(P("/usr/bin:/bin")));
}

TEST(PathWith, OnlyTheMissingOneIsAdded) {
  EXPECT_EQ(P("/usr/bin:/usr/local/bin:/opt/homebrew/bin"),
            path_with(P("/usr/bin:/usr/local/bin")));
  EXPECT_EQ(P("/opt/homebrew/bin:/usr/bin:/usr/local/bin"),
            path_with(P("/opt/homebrew/bin:/usr/bin")));
}

TEST(PathWith, BothPresentLeavesPathUnchanged) {
  const std::string path = P("/usr/local/bin:/usr/bin:/opt/homebrew/bin");
  EXPECT_EQ(path, path_with(path));
}

TEST(PathWith, OrderOfMoreIsKept) {
  EXPECT_EQ(P("/a:/z:/m:/b"), path_with("/a", {"/z", "/m", "/b"}));
}

TEST(PathWith, TrailingSlashEntryIsDistinct) {
  EXPECT_EQ(P("/opt/homebrew/bin/:/opt/homebrew/bin:/usr/local/bin"),
            path_with("/opt/homebrew/bin/"));
}

TEST(PathWith, EmptyMoreReturnsPathUnchanged) {
  EXPECT_EQ(P("/usr/bin:/bin"), path_with(P("/usr/bin:/bin"), {}));
}

TEST(PathWith, CustomMoreIsUsed) {
  EXPECT_EQ(P("/usr/bin:/custom/bin"), path_with("/usr/bin", {"/custom/bin"}));
  EXPECT_EQ(P("/usr/bin:/custom/bin"),
            path_with(P("/usr/bin:/custom/bin"), {"/custom/bin"}));
}

class AddToPathTest : public ::testing::Test {
 protected:
  void SetUp() override {
    const char* path = std::getenv("PATH");
    had_path_ = path != nullptr;
    if (had_path_) saved_ = path;
  }
  void TearDown() override {
    if (had_path_)
      ::setenv("PATH", saved_.c_str(), 1);
    else
      ::unsetenv("PATH");
  }
  static std::string Path() { return std::getenv("PATH"); }

 private:
  bool had_path_ = false;
  std::string saved_;
};

TEST_F(AddToPathTest, UnsetPathCountsAsEmpty) {
  ::unsetenv("PATH");
  add_to_path();
  EXPECT_EQ(P("/opt/homebrew/bin:/usr/local/bin"), Path());
}

TEST_F(AddToPathTest, SetPathGetsTheDirectoriesAppended) {
  ::setenv("PATH", P("/usr/bin:/bin").c_str(), 1);
  add_to_path();
  EXPECT_EQ(P("/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin"), Path());
}

TEST_F(AddToPathTest, CalledTwiceChangesNothingTheSecondTime) {
  ::setenv("PATH", P("/usr/bin:/bin").c_str(), 1);
  add_to_path({"/x", "/y"});
  add_to_path({"/x", "/y"});
  EXPECT_EQ(P("/usr/bin:/bin:/x:/y"), Path());
}

TEST(PathFirst, EmptyPathGivesJustTheDirectory) {
  EXPECT_EQ("/x/bin", path_first("", "/x/bin"));
}

TEST(PathFirst, FinderLikePathGetsTheDirectoryFirst) {
  EXPECT_EQ(P("/x/bin:/usr/bin:/bin"),
            path_first(P("/usr/bin:/bin"), "/x/bin"));
}

TEST(PathFirst, DirectoryAlreadyFirstLeavesPathUnchanged) {
  EXPECT_EQ(P("/x/bin:/usr/bin"), path_first(P("/x/bin:/usr/bin"), "/x/bin"));
}

TEST(PathFirst, DirectoryFoundLaterIsPlacedFirstAndTheLaterOneKept) {
  EXPECT_EQ(P("/x/bin:/a:/x/bin"), path_first(P("/a:/x/bin"), "/x/bin"));
}

TEST_F(AddToPathTest, AddFirstToUnsetPathCountsAsEmpty) {
  ::unsetenv("PATH");
  add_first_to_path("/x/bin");
  EXPECT_EQ("/x/bin", Path());
}

TEST_F(AddToPathTest, AddFirstToSetPathPlacesItFirst) {
  ::setenv("PATH", P("/usr/bin:/bin").c_str(), 1);
  add_first_to_path("/x/bin");
  EXPECT_EQ(P("/x/bin:/usr/bin:/bin"), Path());
}

TEST_F(AddToPathTest, AddFirstCalledTwiceChangesNothingTheSecondTime) {
  ::setenv("PATH", P("/usr/bin:/bin").c_str(), 1);
  add_first_to_path("/x/bin");
  add_first_to_path("/x/bin");
  EXPECT_EQ(P("/x/bin:/usr/bin:/bin"), Path());
}

}  // namespace
}  // namespace motolii
