// doc_cards_of: which cards the inspector shows for a layer, and the cards a layer can be given besides (`more`).
//
// The expected cards are read off engine/document/card_table.h by hand, not taken from the engine: a card shows while the
// property it names reads one of the words it lists, and a card marked "added" shows only once one of its values is set.
//
// A Doc cannot be made by doc_open here (it builds the stage in Filament, which needs a Metal device), so the layers are rows
// of an in-memory SQLite file with the same keyframe table doc_open makes.

#include <gtest/gtest.h>
#include <sqlite3.h>

#include <string>

#include "document/cards.h"
#include "document/document.h"
#include "document/evaluate/value_at.h"

namespace motolii {
namespace {

class Layer {
 public:
  Layer(const char* kind) : d(new Doc) {  // (not freed, as the engine never frees one either)
    sqlite3_open(":memory:", &d->file);
    sqlite3_exec(d->file,
                 "create table keyframe(layer integer, name text, at numeric, value, easing text, primary key(layer, name, at)) "
                 "without rowid;",
                 nullptr, nullptr, nullptr);
    Say("kind", kind);
  }
  void Say(const char* name, const char* word) {
    sqlite3_exec(d->file,
                 sqlite3_mprintf("insert or replace into keyframe(layer, name, at, value) values(1, %Q, 0.0, %Q)", name, word),
                 nullptr, nullptr, nullptr);
  }
  void Put(const char* name, double is) {
    sqlite3_exec(d->file,
                 sqlite3_mprintf("insert or replace into keyframe(layer, name, at, value) values(1, %Q, 0.0, %!.17g)", name, is),
                 nullptr, nullptr, nullptr);
  }
  // The cards shown, and the cards that could be added.
  std::string Cards() {
    doc_forget(*d);
    more.clear();
    return doc_cards_of(*d, 1, &more);
  }
  std::string more;
  Doc* d;
};

bool Has(const std::string& cards, const char* title) { return cards.find(std::string(title) + ":") != std::string::npos; }

// Surface is an "added" card: until a value of it is set it is only on offer (`more`).
TEST(Cards, ASolidIsOfferedTheLitSurfaceWithNoMaterialSaid) {
  Layer solid("solid");
  solid.Cards();
  EXPECT_TRUE(Has(solid.more, "Surface")) << solid.more;
  EXPECT_FALSE(Has(solid.more, "Glass")) << solid.more;
}

TEST(Cards, AMaterialSaidShowsItsOwnCardOnly) {
  for (const auto& [shading, card] : {std::pair{"glass", "Glass"}, {"filament_glass", "Glass"}, {"lacquer", "Lacquer"},
                                      {"bubble", "Bubble"}, {"cloth", "Surface"}, {"subsurface", "Surface"}}) {
    Layer solid("solid");
    solid.Say("shading", shading);
    const std::string cards = solid.Cards();
    EXPECT_TRUE(Has(cards, card)) << shading << ": " << cards;
    for (const char* other : {"Surface", "Glass", "Lacquer", "Bubble"})
      if (std::string(other) != card) EXPECT_FALSE(Has(cards, other)) << shading << " shows " << other;
  }
}

TEST(Cards, AFlatLayerIsOfferedNoSurfaceUntilItIsPlacedInDepth) {
  Layer image("image");
  image.Cards();
  EXPECT_FALSE(Has(image.more, "Surface")) << image.more;
  image.Say("space", "3d");
  image.Cards();
  EXPECT_TRUE(Has(image.more, "Surface")) << image.more;
}

TEST(Cards, TrimPathsShowsOnceTheShapeTrims) {
  Layer shape("shape");
  EXPECT_FALSE(Has(shape.Cards(), "Trim Paths"));
  shape.Put("trim", 0.5);
  const std::string cards = shape.Cards();
  EXPECT_TRUE(Has(cards, "Trim Paths")) << cards;
  EXPECT_NE(cards.find("trim trim_begin trim_offset"), std::string::npos) << cards;
}

// These cards are chosen by what the layer has set, not by a condition of their own: until then they are on offer.
TEST(Cards, TrimPathsAndTheOtherAddedCardsAreOnOfferBeforeTheyAreSet) {
  Layer shape("shape");
  shape.Cards();
  EXPECT_TRUE(Has(shape.more, "Trim Paths")) << shape.more;
  Layer video("video");
  video.Cards();
  EXPECT_TRUE(Has(video.more, "Datamosh")) << video.more;
  Layer solid("solid");
  solid.Cards();
  EXPECT_TRUE(Has(solid.more, "Points")) << solid.more;
}

TEST(Cards, ATimeRemapIsShownOnceSet) {
  Layer image("image");
  image.Say("file", "a.js");
  image.Put("time_remap", 2.0);
  EXPECT_TRUE(Has(image.Cards(), "Time Remap"));
}

TEST(Cards, AGradientShowsWhenItsValuesAreSet) {
  Layer shape("shape");
  shape.Say("fill", "ff0000 0000ff");
  shape.Put("gradient_angle", 45.0);
  EXPECT_TRUE(Has(shape.Cards(), "Gradient"));
}

}  // namespace
}  // namespace motolii
