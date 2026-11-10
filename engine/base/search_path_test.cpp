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

TEST(PathWith, EmptyPathGivesJustTheExtraDirectories) {
  EXPECT_EQ("/opt/homebrew/bin:/usr/local/bin", path_with(""));
  EXPECT_EQ("/x", path_with("", {"/x"}));
}

TEST(PathWith, FinderLikePathGetsBothAppended) {
  EXPECT_EQ("/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin", path_with("/usr/bin:/bin"));
}

TEST(PathWith, OnlyTheMissingOneIsAdded) {
  EXPECT_EQ("/usr/bin:/usr/local/bin:/opt/homebrew/bin", path_with("/usr/bin:/usr/local/bin"));
  EXPECT_EQ("/opt/homebrew/bin:/usr/bin:/usr/local/bin", path_with("/opt/homebrew/bin:/usr/bin"));
}

TEST(PathWith, BothPresentLeavesPathUnchanged) {
  const std::string path = "/usr/local/bin:/usr/bin:/opt/homebrew/bin";
  EXPECT_EQ(path, path_with(path));
}

TEST(PathWith, OrderOfMoreIsKept) {
  EXPECT_EQ("/a:/z:/m:/b", path_with("/a", {"/z", "/m", "/b"}));
}

TEST(PathWith, TrailingSlashEntryIsDistinct) {
  EXPECT_EQ("/opt/homebrew/bin/:/opt/homebrew/bin:/usr/local/bin", path_with("/opt/homebrew/bin/"));
}

TEST(PathWith, EmptyMoreReturnsPathUnchanged) {
  EXPECT_EQ("/usr/bin:/bin", path_with("/usr/bin:/bin", {}));
}

TEST(PathWith, CustomMoreIsUsed) {
  EXPECT_EQ("/usr/bin:/custom/bin", path_with("/usr/bin", {"/custom/bin"}));
  EXPECT_EQ("/usr/bin:/custom/bin", path_with("/usr/bin:/custom/bin", {"/custom/bin"}));
}

class AddToPathTest : public ::testing::Test {
 protected:
  void SetUp() override {
    const char* path = std::getenv("PATH");
    had_path_ = path != nullptr;
    if (had_path_) saved_ = path;
  }
  void TearDown() override {
    if (had_path_) ::setenv("PATH", saved_.c_str(), 1);
    else ::unsetenv("PATH");
  }
  static std::string Path() { return std::getenv("PATH"); }

 private:
  bool had_path_ = false;
  std::string saved_;
};

TEST_F(AddToPathTest, UnsetPathCountsAsEmpty) {
  ::unsetenv("PATH");
  add_to_path();
  EXPECT_EQ("/opt/homebrew/bin:/usr/local/bin", Path());
}

TEST_F(AddToPathTest, SetPathGetsTheDirectoriesAppended) {
  ::setenv("PATH", "/usr/bin:/bin", 1);
  add_to_path();
  EXPECT_EQ("/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin", Path());
}

TEST_F(AddToPathTest, CalledTwiceChangesNothingTheSecondTime) {
  ::setenv("PATH", "/usr/bin:/bin", 1);
  add_to_path({"/x", "/y"});
  add_to_path({"/x", "/y"});
  EXPECT_EQ("/usr/bin:/bin:/x:/y", Path());
}

TEST(PathFirst, EmptyPathGivesJustTheDirectory) {
  EXPECT_EQ("/x/bin", path_first("", "/x/bin"));
}

TEST(PathFirst, FinderLikePathGetsTheDirectoryFirst) {
  EXPECT_EQ("/x/bin:/usr/bin:/bin", path_first("/usr/bin:/bin", "/x/bin"));
}

TEST(PathFirst, DirectoryAlreadyFirstLeavesPathUnchanged) {
  EXPECT_EQ("/x/bin:/usr/bin", path_first("/x/bin:/usr/bin", "/x/bin"));
}

TEST(PathFirst, DirectoryFoundLaterIsPlacedFirstAndTheLaterOneKept) {
  EXPECT_EQ("/x/bin:/a:/x/bin", path_first("/a:/x/bin", "/x/bin"));
}

TEST_F(AddToPathTest, AddFirstToUnsetPathCountsAsEmpty) {
  ::unsetenv("PATH");
  add_first_to_path("/x/bin");
  EXPECT_EQ("/x/bin", Path());
}

TEST_F(AddToPathTest, AddFirstToSetPathPlacesItFirst) {
  ::setenv("PATH", "/usr/bin:/bin", 1);
  add_first_to_path("/x/bin");
  EXPECT_EQ("/x/bin:/usr/bin:/bin", Path());
}

TEST_F(AddToPathTest, AddFirstCalledTwiceChangesNothingTheSecondTime) {
  ::setenv("PATH", "/usr/bin:/bin", 1);
  add_first_to_path("/x/bin");
  add_first_to_path("/x/bin");
  EXPECT_EQ("/x/bin:/usr/bin:/bin", Path());
}

}  // namespace
}  // namespace motolii
