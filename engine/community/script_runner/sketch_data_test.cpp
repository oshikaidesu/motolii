// A p5.js sketch that reads its data as p5.js sketches are written: loadTable,
// loadJSON and loadStrings in preload(), or fetch(). The files come with the
// sketch, in the folder beside it named as it is (as its pictures do for
// loadImage). Expected values are read from the files below by hand.

#include <gtest/gtest.h>

#include <filesystem>
#include <fstream>
#include <string>

#include "community/script_runner/script_runner.h"

namespace motolii {
namespace {

namespace fs = std::filesystem;

std::string P5() {
  return (fs::path(__FILE__).parent_path().parent_path().parent_path() /
          "third_party" / "js" / "p5" / "p5.min.js")
      .string();
}

TEST(SketchData, LoadTableLoadJsonAndFetchReadTheFilesThatCameWithIt) {
  const fs::path dir = fs::temp_directory_path() / "motolii_sketch_data",
                 file = dir / "bars.js";
  fs::create_directories(dir / "bars");
  std::ofstream(dir / "bars" / "rows.csv") << "name,height\na,30\nb,50\nc,70\n";
  std::ofstream(dir / "bars" / "look.json") << R"({"name": "bars", "gap": 10})";
  std::ofstream(dir / "bars" / "words.txt") << "one\ntwo\n";
  std::ofstream(file) << R"(let rows, look, said = '';
function preload() {
  rows = loadTable('rows.csv', 'csv', 'header');
  look = loadJSON('data/look.json');
}
function setup() {
  createCanvas(200, 100);
  fetch('words.txt').then(r => r.text()).then(t => said = t.trim());
}
function draw() {
  background(0);
  for (let r = 0; r < rows.getRowCount(); r++) rect(r * 50, 0, 40, rows.getNum(r, 'height'));
})";
  Script s(file.string(), P5());
  ASSERT_TRUE(s.ok()) << s.trouble();
  s.said("__to(2)");
  EXPECT_EQ(s.said("rows.getRowCount()+','+rows.getNum(2,'height')"), "3,70");
  EXPECT_EQ(s.said("look.name+','+look.gap"), "bars,10");
  EXPECT_EQ(s.said("said"), "one\ntwo");
  fs::remove_all(dir);
}

}  // namespace
}  // namespace motolii
