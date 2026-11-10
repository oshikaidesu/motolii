// Line ends from AbsentMotion: the start and end shapes of a line (arrow,
// t-line, square, diamond, circle and teardrop, hollow or filled), drawn by
// DrawStrokeEnd in AbsentMotion's styles.cpp. That function matches Alight
// Motion's line start and end. AbsentMotion is Apache-2.0, Copyright 2026 The
// AbsentMotion authors.
//
// styles.cpp is included whole and unchanged so that DrawStrokeEnd, which is
// private to that file, can be called from here. The rest of styles.cpp is
// never called and is removed by the linker (CMakeLists.txt, -dead_strip).
#include <string>

#include "community/absent_motion/absent_motion.h"
#include "include/utils/SkParsePath.h"
#include "styles.cpp"

// See absent_motion.h.
std::string absent_line_end(float x, float y, float dx, float dy, float r,
                            float width, int cap, int join, const char* style) {
  // The same paint that AbsentMotion's StrokePaint makes for a line: round caps
  // and bevel joins unless the line asks for another cap or join.
  SkPaint paint;
  paint.setAntiAlias(true);
  paint.setStrokeWidth(width);
  paint.setStrokeCap(cap == 0   ? SkPaint::kButt_Cap
                     : cap == 2 ? SkPaint::kSquare_Cap
                                : SkPaint::kRound_Cap);
  paint.setStrokeJoin(join == 0   ? SkPaint::kMiter_Join
                      : join == 1 ? SkPaint::kRound_Join
                                  : SkPaint::kBevel_Join);
  return SkParsePath::ToSVGString(
             am::DrawStrokeEnd(nullptr, paint, {x, y}, {dx, dy}, r, style))
      .c_str();
}
