// The lines that join copies of a layer to each other or to the copies of
// another layer: one matrix per line, stretched along the direction between the
// two and thinner the farther apart they are.
#include "document/evaluate/place.h"
#include "document/evaluate/shown.h"
#include "document/scripts/scripts.h"
namespace motolii {

namespace math = filament::math;
using filament::math::float2;

std::vector<math::mat4> doc_joins(Doc& d, int layer, double now) {
  const int one = (int)doc_number(d, layer, "connect", 0, 0),
            two = (int)doc_number(d, layer, "connect_to", 0, 0);
  if (!one || one == layer || !d.on_stage.shown.count(one) ||
      (two && (two == layer || !d.on_stage.shown.count(two))))
    return {};
  // Returns the position of the middle of each copy of `other`, before the
  // space is applied.
  const auto where = [&](int other) {
    std::vector<math::double3> at((size_t)doc_members(d, other));
    for (size_t i = 0; i < at.size(); ++i)
      at[i] = (doc_place(d, other, now, 1, (int)i, true) *
               math::double4{0.0, 0.0, 0.0, 1.0})
                  .xyz;
    return at;
  };
  const std::vector<math::double3> a = where(one), b = two ? where(two) : a;
  const double reach = doc_number(d, layer, "connect_reach", now, 0);
  std::vector<std::pair<size_t, size_t>> pairs;
  const size_t most = (size_t)doc_members(d, layer);
  if (two)
    for (size_t i = 0; i < std::min(a.size(), b.size()); ++i)
      pairs.push_back({i, i});
  else if (reach <= 0.0)
    for (size_t i = 0; i + 1 < a.size(); ++i) pairs.push_back({i, i + 1});
  else
    for (size_t i = 0; i < a.size() && pairs.size() < most; ++i)
      for (size_t j = i + 1; j < a.size() && pairs.size() < most; ++j)
        if (length(a[i] - a[j]) < reach) pairs.push_back({i, j});
  float2 half{0.5f};
  float deep = 0.f;
  doc_half(d, layer, &half, &deep);
  const auto shown = d.on_stage.shown.find(layer);
  const int space = shown == d.on_stage.shown.end() ? 3 : shown->second.space;
  std::vector<math::mat4> lines;
  for (size_t k = 0; k < pairs.size() && k < most; ++k) {
    const math::double3 from = a[pairs[k].first], to = b[pairs[k].second],
                        mid = (from + to) * 0.5, way = to - from;
    // The width factor never drops below about a third, because thinner lines
    // break up on the screen.
    const double far = length(way),
                 fine = reach > 0.0 && !two ? 0.35 + 0.65 * (1.0 - far / reach)
                                            : 1.0;
    // The line's axes: along the direction between the two copies, however deep
    // it goes; across it, as level as possible and facing the viewer.
    const math::double3 along = far > 1e-9 ? way / far : math::double3{1, 0, 0},
                        flat = cross(along, math::double3{0, 0, 1});
    const math::double3 across = length(flat) > 1e-6 ? normalize(flat)
                                                     : math::double3{0, 1, 0},
                        up = cross(along, across);
    const double wide = doc_number(d, layer, "size", now, 1) * fine;
    math::mat4 line;
    line[0] = math::double4{along * (far / std::max(1e-6, 2.0 * half.x)), 0.0};
    line[1] = math::double4{-across * wide, 0.0};
    line[2] = math::double4{up, 0.0};
    line[3] = math::double4{mid, 1.0};
    lines.push_back(space == 2 ? d.camera.rig * line : line);
  }
  return lines;
}

}  // namespace motolii
