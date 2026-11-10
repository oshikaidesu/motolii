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
//
// A Doc cannot be made by doc_open or changed by doc_add, doc_set or doc_relate
// here: each of them ends in doc_match, which builds the stage in Filament, and
// open_stage needs a Metal device (stage/render/render_stage.cpp). So the
// project's rows are written into an in-memory SQLite file with the same
// keyframe table as doc_open makes, laid out as doc_relate lays out a relation
// (kind, file, script, members, under, from, and x_by and y_by on each member).
// Everything that evaluates them is the engine's own.

#include <gtest/gtest.h>
#include <sqlite3.h>

#include <cmath>
#include <filesystem>
#include <sstream>
#include <string>
#include <vector>

#include "document/document.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/value_at.h"
#include "physics/physics.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;

constexpr double kNear = 1e-3;

// Returns the file of a relation on the shelf. This file is
// engine/document/evaluate/<name>.
std::string Shelf(const char* name) {
  return (fs::path(__FILE__)
              .parent_path()
              .parent_path()
              .parent_path()
              .parent_path() /
          "shelves" / "relations" / name)
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
    Say(by, "script", Shelf(file));
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

}  // namespace
}  // namespace motolii
