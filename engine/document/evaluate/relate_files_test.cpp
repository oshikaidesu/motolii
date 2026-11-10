// Runs the relations Row, Around, Group, Push and Follow
// (shelves/relations/*.js) through the document's own evaluation: doc_literal
// asks the value of a layer, which goes to doc_related, doc_related_all, the
// script's relate() and, for a leader, layerValue() back into the document.
//
// The expected numbers are worked out by hand from each file's header and from
// Cavalry's Radial and Linear distributions, not read from the engine:
//   Row    x = centre + gap * (n - (count - 1) / 2), y = centre.
//   Around x = centre + radius * sin(2 pi (offset + n / count)), y with cos.
//   Group  every layer is moved by js_x and js_y from where it is.
//   Push   a layer within radius of the leader goes to leader + direction *
//          radius * (0.6 + 0.4 * distance / radius).
//   Follow every layer adds the leader's x at t - lag * (n + 1).
//   Orient rotate = degrees(atan2(dy, dx)) of the way the layer is going.
//   Gravity (force world, 60 frames a second) y falls g / 3600 * n (n + 1) / 2
//          after n frames; the floor stops it or throws it up by Bounce.
// Scale_Assist.js and Field.js are expressions (each()); they are run with
// Script::copies, the call the document makes, and the formulas are in the
// files.
//
// A Doc cannot be made by doc_open or changed by doc_add, doc_set or doc_relate
// here: each of them ends in doc_match, which builds the stage in Filament, and
// open_stage needs a Metal device (stage/render/render_stage.cpp). So the
// project's rows are written into an in-memory SQLite file with the same
// keyframe table as doc_open makes, laid out as doc_relate lays out a relation
// (kind, file, script, members, under, from, and x_by and y_by on each member).
// Everything that evaluates them is the engine's own.

#include <gtest/gtest.h>
#include <math/vec3.h>
#include <sqlite3.h>

#include <cmath>
#include <filesystem>
#include <map>
#include <sstream>
#include <string>
#include <vector>

#include "community/script_runner/script_runner.h"
#include "document/document.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/value_at.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;
namespace math = filament::math;

constexpr double kNear = 1e-3;

// Returns a file on the shelf: `folder` is relations or expressions. This file
// is engine/document/evaluate/<name>.
std::string Shelf(const char* folder, const char* name) {
  return (fs::path(__FILE__)
              .parent_path()
              .parent_path()
              .parent_path()
              .parent_path() /
          "shelves" / folder / name)
      .string();
}

// A project in memory.
class Project {
 public:
  // The Doc is not freed, as the engine never frees one either.
  Project() : d(new Doc) {
    sqlite3_open(":memory:", &d->file);
    sqlite3_exec(d->file,
                 "create table keyframe(layer integer, name text, at numeric, "
                 "value, easing text, primary key(layer, name, at)) without "
                 "rowid;",
                 nullptr, nullptr, nullptr);
  }
  void Put(int layer, const char* name, double is, double at = 0.0) {
    Run(
        sqlite3_mprintf("insert into keyframe(layer, name, at, value) "
                        "values(%d, %Q, %!.17g, %!.17g)",
                        layer, name, at, is));
  }
  void Say(int layer, const char* name, const std::string& word) {
    Run(
        sqlite3_mprintf("insert into keyframe(layer, name, at, value) "
                        "values(%d, %Q, 0.0, %Q)",
                        layer, name, word.c_str()));
  }
  // Adds a layer standing at (x, y) and returns its number.
  int Layer(double x, double y) {
    const int layer = next_++;
    Say(layer, "kind", "shape");
    Put(layer, "x", x), Put(layer, "y", y);
    return layer;
  }
  // Adds a relation written as the shelf file `file`, as doc_relate leaves one:
  // the members in order, each having come from where it stands (unless
  // `knowsFrom` is false), with x and y connected to the relation.
  int Relation(const char* file, const std::vector<int>& members,
               bool knowsFrom = true) {
    const int by = next_++;
    Say(by, "kind", "behaviour"), Say(by, "file", "relate");
    Say(by, "script", Shelf("relations", file));
    Put(by, "strength", 1.0);
    std::ostringstream order, under, from;
    from.precision(17);
    for (size_t i = 0; i < members.size(); ++i) {
      const char* gap = i ? " " : "";
      order << gap << members[i], under << gap << 0;
      from << gap << Value(members[i], "x") << ' ' << Value(members[i], "y");
      Put(members[i], "x_by", by), Put(members[i], "y_by", by);
    }
    Say(by, "members", order.str()), Say(by, "under", under.str());
    if (knowsFrom) Say(by, "from", from.str());
    return by;
  }
  // The value of the layer as it is stored, with no relation.
  double Value(int layer, const char* name) {
    double is = 0;
    sqlite3_stmt* q = nullptr;
    sqlite3_prepare_v2(d->file,
                       "select value from keyframe where layer = ? and name = "
                       "? and at = 0",
                       -1, &q, nullptr);
    sqlite3_bind_int(q, 1, layer), sqlite3_bind_text(q, 2, name, -1, nullptr);
    if (sqlite3_step(q) == SQLITE_ROW) is = sqlite3_column_double(q, 0);
    sqlite3_finalize(q);
    return is;
  }
  // What the engine says the layer shows at time t.
  double X(int layer, double t = 0) {
    doc_forget(*d);
    return doc_literal(*d, layer, "x", t, 0.0);
  }
  double Y(int layer, double t = 0) {
    doc_forget(*d);
    return doc_literal(*d, layer, "y", t, 0.0);
  }
  double Turn(int layer, double t = 0) {
    doc_forget(*d);
    return doc_literal(*d, layer, "rotate", t, 0.0);
  }

 private:
  void Run(char* sql) {
    EXPECT_EQ(sqlite3_exec(d->file, sql, nullptr, nullptr, nullptr), SQLITE_OK)
        << sqlite3_errmsg(d->file);
    sqlite3_free(sql);
  }
  Doc* d;
  int next_ = 1;
};

// Expects the layer to show (x, y) at time t.
void At(Project& p, int layer, double x, double y, double t = 0.0) {
  EXPECT_NEAR(p.X(layer, t), x, kNear) << "x of layer " << layer;
  EXPECT_NEAR(p.Y(layer, t), y, kNear) << "y of layer " << layer;
}

TEST(RelateFiles, RowLaysThreeLayersGapApartAboutTheCentre) {
  Project p;
  const int a = p.Layer(0, 0), b = p.Layer(0, 0), c = p.Layer(0, 0),
            outside = p.Layer(3, 4);
  p.Relation("Row.js", {a, b, c});
  At(p, a, -0.2, 0), At(p, b, 0, 0), At(p, c, 0.2, 0);
  At(p, outside, 3, 4);
}

TEST(RelateFiles, RowWithoutWhereTheyJoinedPutsThemAtTheirPlaces) {
  Project p;
  const int a = p.Layer(7, 7), b = p.Layer(7, 7), c = p.Layer(7, 7);
  p.Relation("Row.js", {a, b, c}, /*knowsFrom=*/false);
  At(p, a, -0.2, 0), At(p, b, 0, 0), At(p, c, 0.2, 0);
}

TEST(RelateFiles, RowWithALeaderCentresOnIt) {
  Project p;
  const int a = p.Layer(0, 0), b = p.Layer(0, 0), c = p.Layer(0, 0),
            leader = p.Layer(1, 2), outside = p.Layer(3, 4);
  p.Put(p.Relation("Row.js", {a, b, c}), "js_leader", leader);
  At(p, a, 0.8, 2), At(p, b, 1, 2), At(p, c, 1.2, 2);
  At(p, leader, 1, 2), At(p, outside, 3, 4);
}

TEST(RelateFiles, AroundPutsFourLayersOnACircleStartingAtTheTop) {
  Project p;
  const int a = p.Layer(0, 0), b = p.Layer(0, 0), c = p.Layer(0, 0),
            d = p.Layer(0, 0), outside = p.Layer(3, 4);
  p.Relation("Around.js", {a, b, c, d});
  At(p, a, 0, 0.5), At(p, b, 0.5, 0), At(p, c, 0, -0.5), At(p, d, -0.5, 0);
  At(p, outside, 3, 4);
}

TEST(RelateFiles, GroupMovesEachLayerByXFromWhereItIs) {
  Project p;
  const int a = p.Layer(-1, 0), b = p.Layer(0, 0), c = p.Layer(1, 0),
            outside = p.Layer(3, 4);
  p.Put(p.Relation("Group.js", {a, b, c}), "js_x", 0.3);
  At(p, a, -0.7, 0), At(p, b, 0.3, 0), At(p, c, 1.3, 0);
  At(p, outside, 3, 4);
}

TEST(RelateFiles, PushSendsALayerInsideTheRadiusOutToItsEdge) {
  Project p;
  const int inside = p.Layer(0.5, 0), beyond = p.Layer(3, 0),
            leader = p.Layer(0, 0), outside = p.Layer(3, 4);
  const int push = p.Relation("Push.js", {inside, beyond});
  p.Put(push, "js_leader", leader), p.Put(push, "js_radius", 1.0);
  // 1 * (0.6 + 0.4 * 0.5 / 1) along the line from the leader.
  At(p, inside, 0.8, 0), At(p, beyond, 3, 0);
  At(p, leader, 0, 0), At(p, outside, 3, 4);
}

TEST(RelateFiles, FollowAddsTheLeadersXFromLagSecondsAgo) {
  Project p;
  const int first = p.Layer(5, 0), second = p.Layer(6, 0),
            leader = p.Layer(0, 0), outside = p.Layer(3, 4);
  // The leader's x is 2 t: 0 at 0 (written by Layer) and 2 at 1 second.
  p.Put(leader, "x", 2.0, 1.0);
  const int follow = p.Relation("Follow.js", {first, second});
  p.Put(follow, "js_leader", leader), p.Put(follow, "js_lag", 0.1);
  // At t = 1 the first goes by the leader at 0.9, the second at 0.8.
  At(p, first, 6.8, 0, 1), At(p, second, 7.6, 0, 1);
  At(p, leader, 2, 0, 1), At(p, outside, 3, 4, 1);
}

TEST(RelateFiles, ALeaderThatTheSameRelationMovesEndsAndShowsWhereItStands) {
  // The Row reads its leader's x, which is the Row's own result for the leader.
  // Asked for again while it is being worked out, the Row gives nothing, so the
  // leader reads as it stands (0) and the call returns.
  Project p;
  const int a = p.Layer(0, 0), b = p.Layer(0, 0);
  p.Put(p.Relation("Row.js", {a, b}), "js_leader", a);
  At(p, a, -0.1, 0), At(p, b, 0.1, 0);
}

TEST(RelateFiles, TwoRelationsThatLeadFromEachOthersLayersEnd) {
  // Row one is led by l, which Row two moves. Row two is led by m, which Row
  // one moves. Whatever the numbers are, asking ends and they are numbers.
  Project p;
  const int m = p.Layer(0, 0), q = p.Layer(0, 0), l = p.Layer(0, 0),
            r = p.Layer(0, 0), outside = p.Layer(3, 4);
  const int one = p.Relation("Row.js", {m, q}),
            two = p.Relation("Row.js", {l, r});
  p.Put(one, "js_leader", l), p.Put(two, "js_leader", m);
  for (const int layer : {m, q, l, r}) {
    EXPECT_LT(std::fabs(p.X(layer)), 10.0) << layer;  // (false for NaN too)
    EXPECT_LT(std::fabs(p.Y(layer)), 10.0) << layer;
  }
  At(p, outside, 3, 4);
}

// Expects the layer to turn by `degrees` at time t.
void Turns(Project& p, int layer, double degrees, double t = 1.0) {
  EXPECT_NEAR(p.Turn(layer, t), degrees, kNear) << "rotate of layer " << layer;
}

TEST(RelateFiles, OrientTurnsEachLayerTheWayItIsGoing) {
  // rotate = degrees(atan2(dy, dx)) of the way it moves, as look.js turns to
  // face: along +x is 0, along +y is 90, along -x is 180, up and right is 45.
  Project p;
  const int right = p.Layer(0, 0), up = p.Layer(0, 0), diagonal = p.Layer(0, 0),
            left = p.Layer(0, 0), still = p.Layer(1, 1),
            outside = p.Layer(3, 4);
  p.Put(right, "x", 2.0, 2.0), p.Put(right, "rotate", 10.0);
  p.Put(up, "y", 2.0, 2.0);
  p.Put(diagonal, "x", 2.0, 2.0), p.Put(diagonal, "y", 2.0, 2.0);
  p.Put(left, "x", -2.0, 2.0);
  p.Put(still, "rotate", 30.0);
  const int orient =
      p.Relation("Orient.js", {right, up, diagonal, left, still});
  for (const int layer : {right, up, diagonal, left, still})
    p.Put(layer, "rotate_by", orient);
  Turns(p, right, 10), Turns(p, up, 90), Turns(p, diagonal, 45);
  Turns(p, left, 180);
  Turns(p, still, 30);  // it does not move, so it keeps its own turn
  Turns(p, outside, 0);
  // Where they are is not changed by turning them.
  EXPECT_NEAR(p.X(diagonal, 1.0), 1.0, kNear);
  EXPECT_NEAR(p.Y(up, 1.0), 1.0, kNear);
}

TEST(RelateFiles, GravityPullsALayerDownBy60thsOfASecondSteps) {
  // 60 frames a second, a speed in units a frame: the speed after frame n is
  // n * g / 3600 and the layer has fallen g / 3600 * n (n + 1) / 2, so after
  // 30 frames 9.81 * 465 / 3600 = 1.267125, after 60 frames 9.81 * 1830 / 3600
  // = 4.98675.
  Project p;
  const int a = p.Layer(0, 5), outside = p.Layer(3, 4);
  p.Put(p.Relation("Gravity.js", {a}), "js_floor", -100.0);
  At(p, a, 0, 5 - 1.267125, 0.5);
  At(p, a, 0, 5 - 4.98675, 1.0);
  At(p, outside, 3, 4, 1.0);
}

TEST(RelateFiles, GravityStopsALayerAtTheFloorWhenItDoesNotBounce) {
  // It reaches the floor (0) after about a second and stays on it. Before that
  // it falls as it would without a floor.
  Project p;
  const int a = p.Layer(0, 5), outside = p.Layer(3, 4);
  const int gravity = p.Relation("Gravity.js", {a});
  p.Put(gravity, "js_floor", 0.0), p.Put(gravity, "js_bounce", 0.0);
  At(p, a, 0, 5 - 1.267125, 0.5);
  At(p, a, 0, 0, 3.0);
  At(p, outside, 3, 4, 3.0);
}

TEST(RelateFiles, GravityBouncesALayerUpFromTheFloorAndNeverBelowIt) {
  Project p;
  const int a = p.Layer(0, 5);
  const int gravity = p.Relation("Gravity.js", {a});
  p.Put(gravity, "js_floor", 0.0), p.Put(gravity, "js_bounce", 0.5);
  // About 0.2 seconds after it hit the floor (frame 61) it is on its way up.
  EXPECT_GT(p.Y(a, 1.2), 0.1);
  for (const double t : {1.0, 1.1, 1.2, 1.5, 2.0, 3.0})
    EXPECT_GE(p.Y(a, t), -1e-6) << t;
}

// The copies a script file lays: runs each() of an expression as the document
// does (doc_expressions_lay). The document's own call cannot be used here, it
// reads the stage's size.
std::vector<ScriptCopy> Lay(const char* file,
                            const std::map<std::string, double>& numbers,
                            const std::map<std::string, std::string>& words,
                            const std::vector<math::double3>& at) {
  Script script(Shelf("expressions", file));
  EXPECT_TRUE(script.ok()) << script.trouble();
  std::vector<ScriptCopy> before(at.size());
  for (size_t i = 0; i < at.size(); ++i)
    before[i].x = at[i].x, before[i].y = at[i].y, before[i].z = at[i].z;
  return script.copies((int)at.size(), 0.0, numbers, words, 1.0, before);
}

TEST(RelateFiles, ScaleAssistGrowsOneWayAloneOrBothWaysKeepingBulk) {
  const std::vector<math::double3> one{{0, 0, 0}};
  // X alone and Y alone multiply that axis only.
  auto c = Lay("Scale_Assist.js", {{"assist_amount", 2}, {"assist_damp", 1}},
               {{"assist_way", "x"}}, one);
  EXPECT_NEAR(c[0].scale_x, 2.0, kNear);
  EXPECT_NEAR(c[0].scale_y, 1.0, kNear);
  c = Lay("Scale_Assist.js", {{"assist_amount", 3}, {"assist_damp", 1}},
          {{"assist_way", "y"}}, one);
  EXPECT_NEAR(c[0].scale_x, 1.0, kNear);
  EXPECT_NEAR(c[0].scale_y, 3.0, kNear);
  // Both: scale_x = amount, scale_y = 1 / (amount^1.71 * damp^(1 + 2.75 *
  // (damp - 1)^1.93)). Amount 2, damp 1: 2^-1.71 = 0.305660. Damp 2:
  // 2^-(1.71 + 1 + 2.75) = 2^-5.46 = 0.022718.
  c = Lay("Scale_Assist.js", {{"assist_amount", 2}, {"assist_damp", 1}},
          {{"assist_way", "both"}}, one);
  EXPECT_NEAR(c[0].scale_x, 2.0, kNear);
  EXPECT_NEAR(c[0].scale_y, 0.305660, kNear);
  c = Lay("Scale_Assist.js", {{"assist_amount", 2}, {"assist_damp", 2}},
          {{"assist_way", "both"}}, one);
  EXPECT_NEAR(c[0].scale_y, 0.022718, kNear);
}

TEST(RelateFiles, FieldChangesCopiesInsideItsRadiusAndNotOutside) {
  // Radius 1, Grow 1, Turn 90, Push 0.6, round (no ring). With r the distance
  // from the middle, s = near^2 (3 - 2 near) and near = 1 - r / radius:
  //   r = 0:   s = 1,   size 2,   turn 90, no push (nowhere to go).
  //   r = 0.5: s = 0.5, size 1.5, turn 45, x = 0.5 * 0.5 *
  //            (sqrt(0.25 + 0.36) - 0.5) / 0.5 = 0.140513.
  //   r = 5:   outside, nothing.
  const std::map<std::string, double> field{
      {"field_x", 0},       {"field_y", 0},     {"field_z", 0},
      {"field_radius", 1},  {"field_band", 0},  {"field_size", 1},
      {"field_rotate", 90}, {"field_push", 0.6}};
  auto c = Lay("Field.js", field, {}, {{0, 0, 0}, {0.5, 0, 0}, {5, 0, 0}});
  EXPECT_NEAR(c[0].size, 2.0, kNear);
  EXPECT_NEAR(c[0].rotate, 90.0, kNear);
  EXPECT_NEAR(c[0].x, 0.0, kNear);
  EXPECT_NEAR(c[1].size, 1.5, kNear);
  EXPECT_NEAR(c[1].rotate, 45.0, kNear);
  EXPECT_NEAR(c[1].x, 0.140513, kNear);
  EXPECT_NEAR(c[2].size, 1.0, kNear);
  EXPECT_NEAR(c[2].rotate, 0.0, kNear);
  EXPECT_NEAR(c[2].x, 0.0, kNear);
  // A ring 0.5 wide at radius 1: strongest at r = 1 (size 2), half way to the
  // edge of the band at r = 1.25 (near 0.5, s 0.5, size 1.5), none at the
  // middle.
  std::map<std::string, double> ring = field;
  ring["field_band"] = 0.5, ring["field_push"] = 0;
  c = Lay("Field.js", ring, {}, {{1, 0, 0}, {1.25, 0, 0}, {0, 0, 0}});
  EXPECT_NEAR(c[0].size, 2.0, kNear);
  EXPECT_NEAR(c[1].size, 1.5, kNear);
  EXPECT_NEAR(c[2].size, 1.0, kNear);
  // A radius of 0 is no field.
  ring["field_radius"] = 0;
  c = Lay("Field.js", ring, {}, {{0, 0, 0}});
  EXPECT_NEAR(c[0].size, 1.0, kNear);
  EXPECT_NEAR(c[0].rotate, 0.0, kNear);
}

}  // namespace
}  // namespace motolii
