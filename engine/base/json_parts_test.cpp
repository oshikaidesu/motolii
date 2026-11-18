// Tests for base/json_parts.h. The expected values follow the contract written
// there and docs/app/BRIDGE.md: a reader is handed only the parts newer than
// the version it has, a part that did not differ keeps its version, and a part
// that is gone is handed over once as null. The same texts are what
// app/test/bridge/snapshot_parts_test.dart reads on the app's side.

#include "base/json_parts.h"

#include <gtest/gtest.h>

#include <string>

namespace motolii {
namespace {

TEST(JsonParts, AReaderWithNothingIsHandedEveryPart) {
  JsonParts parts;
  EXPECT_TRUE(json_parts_keep(
      parts, R"({"moving":"x y","value":{"x":1.5},"keys":[0,2]})", 1, true));
  EXPECT_EQ(R"("keys":[0,2],"moving":"x y","value":{"x":1.5})",
            json_parts_newer(parts, -1));
}

TEST(JsonParts, OnlyThePartThatDifferedTakesTheNewVersion) {
  JsonParts parts;
  json_parts_keep(parts, R"({"moving":"x y","value":{"x":1.5}})", 1, true);
  EXPECT_TRUE(
      json_parts_keep(parts, R"({"moving":"x y","value":{"x":2}})", 2, true));
  EXPECT_EQ(R"("value":{"x":2})", json_parts_newer(parts, 1));
  EXPECT_EQ("", json_parts_newer(parts, 2));
  EXPECT_EQ(1, parts["moving"].version);
}

TEST(JsonParts, TheSameObjectAgainDiffersInNothing) {
  JsonParts parts;
  const std::string same = R"({"moving":"x y","value":{"x":1.5}})";
  json_parts_keep(parts, same, 1, true);
  EXPECT_FALSE(json_parts_keep(parts, same, 2, true));
  EXPECT_EQ("", json_parts_newer(parts, 1));
}

TEST(JsonParts, APartThatIsGoneIsHandedOverOnceAsNull) {
  JsonParts parts;
  json_parts_keep(parts, R"({"keys":[0,2],"lasts":5})", 1, true);
  EXPECT_TRUE(json_parts_keep(parts, R"({"lasts":5})", 2, true));
  EXPECT_EQ(R"("keys":null)", json_parts_newer(parts, 1));
  EXPECT_FALSE(json_parts_keep(parts, R"({"lasts":5})", 3, true));
  EXPECT_EQ("", json_parts_newer(parts, 2));
}

TEST(JsonParts, APartThatCameBackIsHandedOverAgain) {
  JsonParts parts;
  json_parts_keep(parts, R"({"keys":[0,2]})", 1, true);
  json_parts_keep(parts, R"({})", 2, true);
  EXPECT_TRUE(json_parts_keep(parts, R"({"keys":[0,2]})", 3, true));
  EXPECT_EQ(R"("keys":[0,2])", json_parts_newer(parts, 2));
}

TEST(JsonParts, NotWholeLeavesThePartsOfAnotherObjectAlone) {
  JsonParts parts;
  json_parts_keep(parts, R"({"seconds":30})", 1, false);
  EXPECT_TRUE(json_parts_keep(parts, R"({"usual":{"x":0}})", 1, false));
  EXPECT_FALSE(json_parts_keep(parts, R"({"seconds":30})", 2, false));
  EXPECT_EQ(R"("seconds":30,"usual":{"x":0})", json_parts_newer(parts, 0));
}

TEST(JsonParts, TextThatIsNotAnObjectKeepsNothing) {
  JsonParts parts;
  EXPECT_FALSE(json_parts_keep(parts, "[1,2]", 1, true));
  EXPECT_FALSE(json_parts_keep(parts, "{\"keys\":", 1, true));
  EXPECT_TRUE(parts.empty());
}

TEST(JsonParts, TextOutsideAsciiComesBackAsItWent) {
  JsonParts parts;
  json_parts_keep(parts, "{\"word\":{\"name\":\"レイヤー \\\"1\\\"\"}}", 1,
                  true);
  EXPECT_EQ("\"word\":{\"name\":\"レイヤー \\\"1\\\"\"}",
            json_parts_newer(parts, 0));
}

}  // namespace
}  // namespace motolii
