#include "document/edit/paths.h"

#include <math/mat4.h>
#include <math/vec4.h>
#include <sqlite3.h>
#include <thorvg.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

extern "C" {
// Fits cubic Bezier curves to points; used by doc_curve to convert a drag path.
// See curve_fit_nd.sh.
#include "curve_fit_nd.h"
}

#include "community/absent_motion/absent_motion.h"
#include "community/css/text.h"
#include "document/cards.h"
#include "document/document.h"
#include "document/edit/layer_edit.h"
#include "document/edit/parent.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/undo.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/canvas/path_operations.h"

namespace motolii {

using filament::math::mat4;
namespace math = filament::math;

DocPlane::DocPlane(Doc& d, int layer, double now) {
  const math::mat4 at = doc_shown_at(d, layer, now);
  o = doc_seen(d, (at * math::double4{0, 0, 0, 1}).xyz),
  ex = doc_seen(d, (at * math::double4{1, 0, 0, 1}).xyz) - o,
  ey = doc_seen(d, (at * math::double4{0, 1, 0, 1}).xyz) - o;
  det = ex.x * ey.y - ex.y * ey.x, seen = std::fabs(det) > 1e-9;
}

int doc_points(Doc& d, int layer, double now, double* xy, int room,
               bool handles, double* of) {
  if (!doc_knows(d, layer) || doc_word(d, layer, "shape") != "path") return 0;
  std::vector<float> own, owner;
  const std::string path = doc_word(d, layer, "path");
  const int n = handles ? sk_svg_handles(path.c_str(), own, &owner)
                        : sk_svg_anchors(path.c_str(), own);
  const DocPlane plane(d, layer, now);
  for (int i = 0; i < n && i < room; ++i) {
    const math::double2 p = plane.at(own[2 * i], own[2 * i + 1]);
    xy[2 * i] = p.x, xy[2 * i + 1] = p.y;
    if (of) {
      const math::double2 o = plane.at(owner[2 * i], owner[2 * i + 1]);
      of[2 * i] = o.x, of[2 * i + 1] = o.y;
    }
  }
  return n;
}

int doc_pen(Doc& d, int layer, double x, double y, double hx, double hy) {
  const double now = d.stage->now;
  doc_act(d);
  // The layer is not a path, so the pen begins one.
  if (layer && (!doc_knows(d, layer) || doc_word(d, layer, "shape") != "path"))
    layer = 0;
  // If the path is closed, a click on one of its points removes it, and a click
  // on its outline puts a point there. Otherwise the pen begins another path.
  if (const std::string was = layer ? doc_word(d, layer, "path") : ""; [&] {
        float fx, fy;
        int n;
        return sk_svg_ends(was.c_str(), fx, fy, n) == 4;
      }()) {
    const DocPlane plane(d, layer, now);
    const math::double2 p = plane.own(x, y);
    std::string edited;
    if (plane.seen &&
        sk_svg_edit(was.c_str(), (float)p.x, (float)p.y,
                    (float)(8.0 / std::max(1e-9, length(plane.ex))), edited)) {
      if (!doc_say(d, layer, "path", edited.c_str())) d.act.ok = false;
      return doc_acted(d) ? layer : 0;
    }
    layer = 0;
  }
  if (!layer) layer = doc_add(d, "shape", "path");
  std::string path = layer ? doc_word(d, layer, "path") : "";
  const DocPlane plane(d, layer, now);
  const math::double2 o = plane.o, ex = plane.ex, ey = plane.ey;
  if (layer && !plane.seen) d.error = "the shape is seen edge on", layer = 0;
  const auto own = [&](double px, double py) { return plane.own(px, py); };
  // The path data to append to the path.
  char said[200] = "";
  if (layer) {
    const math::double2 p = own(x, y), in = own(x - hx, y - hy);
    float first_x = 0.f, first_y = 0.f;
    int stretches = 0;
    // Skia's reading of the path (see
    // engine/stage/canvas/skia_path_operations.cpp).
    const int last = sk_svg_ends(path.c_str(), first_x, first_y, stretches);
    const double fx = first_x, fy = first_y;
    const bool smooth = last == 3, handle = hx != 0.0 || hy != 0.0;
    // The click is back on the first point if it is within 8 points of it.
    const bool closes =
        stretches > 0 && last != 4 &&
        length(o + ex * fx - ey * fy - math::double2{x, y}) < 8.0;
    if (path.empty())
      std::snprintf(said, sizeof said, "M%.4f %.4f", p.x, p.y);
    else if (closes)
      std::snprintf(said, sizeof said,
                    smooth || handle ? " S%.4f %.4f %.4f %.4f Z" : " Z",
                    handle ? own(o.x + ex.x * fx - ey.x * fy - hx,
                                 o.y + ex.y * fx - ey.y * fy - hy)
                                 .x
                           : fx,
                    handle ? own(o.x + ex.x * fx - ey.x * fy - hx,
                                 o.y + ex.y * fx - ey.y * fy - hy)
                                 .y
                           : fy,
                    fx, fy);
    else if (!smooth && !handle)
      std::snprintf(said, sizeof said, " L%.4f %.4f", p.x, p.y);
    else
      std::snprintf(said, sizeof said, " S%.4f %.4f %.4f %.4f", in.x, in.y, p.x,
                    p.y);
    if (!doc_say(d, layer, "path", (path + said).c_str())) layer = 0;
  }
  if (!layer) d.act.ok = false;
  return doc_acted(d) ? layer : 0;
}

int doc_extract_sound(Doc& d, int layer) {
  if (!doc_knows(d, layer) || doc_word(d, layer, "kind") != "video")
    return d.error = "only a video's sound is taken out", 0;
  doc_act(d);
  const int made = doc_duplicate(d, layer);
  const bool ok =
      made && doc_set(d, made, "visible", 0) &&
      doc_say(d, made, "name", (doc_name(d, layer) + " (sound)").c_str()) &&
      doc_set(d, layer, "volume", 0);
  return doc_acted(d) && ok ? made : 0;
}

int doc_freehand(Doc& d, const char* points) {
  std::vector<double> xy;
  std::istringstream said(points);
  for (double v; said >> v;) xy.push_back(v);
  if (xy.size() < 6) return d.error = "a stroke of fewer than three points", 0;
  doc_act(d);
  int layer = doc_add(d, "shape", "path");
  const DocPlane plane(d, layer, d.stage->now);
  if (layer && !plane.seen) d.error = "its plane is seen edge on", layer = 0;
  if (layer) {
    std::string path;
    char one[160];
    const size_t n = xy.size() / 2;
    for (size_t i = 0; i < n; ++i) {
      const math::double2 p = plane.own(xy[2 * i], xy[2 * i + 1]),
                          q = plane.own(xy[2 * ((i + 1) % n)],
                                        xy[2 * ((i + 1) % n) + 1]);
      if (!i)
        std::snprintf(one, sizeof one, "M%.4f %.4f", p.x, p.y), path += one;
      std::snprintf(one, sizeof one, " Q%.4f %.4f %.4f %.4f", p.x, p.y,
                    (p.x + q.x) / 2, (p.y + q.y) / 2);
      path += one;
    }
    if (!doc_say(d, layer, "path", (path + " Z").c_str())) layer = 0;
  }
  if (!layer) d.act.ok = false;
  return doc_acted(d) ? layer : 0;
}

int doc_curve(Doc& d, const char* said) {
  std::istringstream in(said);
  double error = 0.0;
  in >> error;
  std::vector<double> xy;
  // Skip a point that is within 1% of `error` of the previous one, since
  // curve-fit-nd does not accept a stretch of no length.
  for (double x, y; in >> x >> y;)
    if (xy.empty() ||
        std::hypot(x - xy[xy.size() - 2], y - xy.back()) > 0.01 * error)
      xy.push_back(x), xy.push_back(y);
  const unsigned n = (unsigned)(xy.size() / 2);
  if (!(error > 0.0) || n < 3)
    return d.error = "a stroke of fewer than three points", 0;
  // The stroke is closed if it ends within four times `error` of where it
  // began.
  const bool closed =
      std::hypot(xy[0] - xy[2 * n - 2], xy[1] - xy[2 * n - 1]) < 4 * error;
  double* cubic = nullptr;
  unsigned cubics = 0, *orig = nullptr, *corners = nullptr, cornersLen = 0;
  if (curve_fit_cubic_to_points_refit_db(
          xy.data(), closed ? n - 1 : n, 2, error,
          CURVE_FIT_CALC_HIGH_QUALITY | (closed ? CURVE_FIT_CALC_CYCLIC : 0),
          nullptr, 0, 70.0 * M_PI / 180.0, &cubic, &cubics, &orig, &corners,
          &cornersLen) ||
      cubics < 2) {
    free(cubic), free(orig), free(corners);
    return d.error = "the stroke made no curve", 0;
  }
  doc_act(d);
  int layer = doc_add(d, "shape", "path");
  const DocPlane plane(d, layer, d.stage->now);
  if (layer && !plane.seen) d.error = "its plane is seen edge on", layer = 0;
  if (layer) {
    // Formats one point of cubic k as text. part is 0 for its incoming handle,
    // 1 for the anchor, and 2 for its outgoing handle.
    const auto at = [&](unsigned k, int part) {
      const double* c = cubic + (k * 3 + part) * 2;
      const math::double2 p = plane.own(c[0], c[1]);
      char one[64];
      std::snprintf(one, sizeof one, "%.4f %.4f", p.x, p.y);
      return std::string(one);
    };
    std::string path = "M" + at(0, 1);
    for (unsigned k = 1; k < cubics + (closed ? 1 : 0); ++k)
      path += " C" + at(k - 1, 2) + " " + at(k % cubics, 0) + " " +
              at(k % cubics, 1);
    if (closed) path += " Z";
    if (!doc_say(d, layer, "path", path.c_str())) layer = 0;
  }
  free(cubic), free(orig), free(corners);
  if (!layer) d.act.ok = false;
  return doc_acted(d) ? layer : 0;
}

int doc_brush(Doc& d, const char* said, int into) {
  std::istringstream in(said);
  int tool = 1;
  double size = 0.0;
  in >> tool >> size;
  tool = std::clamp(tool, 0, 3);
  std::vector<double> xyp;
  for (double v; in >> v;) xyp.push_back(v);
  if (!(size > 0.0) || xyp.size() < 6)
    return d.error = "a stroke of fewer than two points", 0;
  const std::string was =
      tool == 3 ? doc_word(d, into, "drawing") : std::string();
  if (tool == 3 && was.empty())
    return d.error = "an eraser takes from a drawing: pick one", 0;
  doc_act(d);
  int layer = tool == 3 ? into : doc_add(d, "shape", "path");
  const DocPlane plane(d, layer, d.stage->now);
  if (layer && !plane.seen) d.error = "its plane is seen edge on", layer = 0;
  if (layer) {
    const double wide =
        length(plane.own(xyp[0] + size, xyp[1]) - plane.own(xyp[0], xyp[1]));
    std::string kept = was.empty() ? "" : was + " ; ";
    char one[96];
    std::snprintf(one, sizeof one, "%d %.5f", tool, wide), kept += one;
    for (size_t i = 0; i + 2 < xyp.size(); i += 3) {
      const math::double2 p = plane.own(xyp[i], xyp[i + 1]);
      std::snprintf(one, sizeof one, " %.5f %.5f %.3f", p.x, p.y, xyp[i + 2]),
          kept += one;
    }
    const std::string outline =
        absent_drawing(kept, {}, layer, 0.0, 1000.0, 0.0, true);
    if ((outline.empty() && tool != 3) ||
        !doc_say(d, layer, "drawing", kept.c_str()) ||
        !doc_say(d, layer, "path", outline.c_str()))
      layer = 0;
  }
  if (!layer) d.act.ok = false;
  return doc_acted(d) ? layer : 0;
}

namespace {

struct TextOutlineLayout {
  MotoliiText* text = nullptr;
  std::string words;
  std::string fontFile;
  std::vector<uint8_t> verbs;
  std::vector<float> points;
  std::vector<std::array<float, 5>> lines;
  std::vector<std::array<float, 5>> letters;
  float x0 = 0.f, y0 = 0.f, wide = 0.f, tall = 0.f;
  float ascent = 0.f, descent = 0.f;
  double size = 1.0;
  double pxToStage = 1.0;

  ~TextOutlineLayout() {
    if (text) motolii_text_free(text);
  }
};

std::vector<std::string> utf8_codepoints(const std::string& s) {
  std::vector<std::string> out;
  for (size_t i = 0; i < s.size();) {
    const unsigned char c = (unsigned char)s[i];
    size_t n = c < 0x80         ? 1
               : (c >> 5) == 6  ? 2
               : (c >> 4) == 14 ? 3
               : (c >> 3) == 30 ? 4
                                : 1;
    if (i + n > s.size()) n = s.size() - i;
    out.push_back(s.substr(i, n));
    i += n;
  }
  return out;
}

bool layout_text_for_paths(Doc& d, int layer, TextOutlineLayout& out) {
  if (doc_word(d, layer, "kind") != "text") {
    d.error = "only a text layer can be exploded";
    return false;
  }
  out.fontFile = doc_word(d, layer, "file");
  if (!std::filesystem::is_regular_file(out.fontFile)) {
    d.error = "the text layer's font file is missing";
    return false;
  }
  out.words = doc_word(d, layer, "text");
  if (out.words.empty())
    out.words = std::filesystem::path(out.fontFile).stem().generic_string();
  std::string fonts = out.fontFile;
  if (const std::string fell = type_fallback(out.fontFile, out.words);
      !fell.empty())
    fonts += "\n" + fell;

  const int sw = d.stage && d.stage->w > 0 ? d.stage->w : 1920;
  const int sh = d.stage && d.stage->h > 0 ? d.stage->h : 1080;
  const float fine = 0.12f * (float)std::max(sw, sh);
  constexpr float kPixelsPerPoint = 96.f / 72.f;
  const double now = d.stage ? d.stage->now : 0.0;
  const float lineSpacing = (float)doc_number(d, layer, "line_spacing", now, 1.2);
  const float tracking = (float)doc_number(d, layer, "letter_spacing", now, 0.0);
  const float slant = (float)doc_number(d, layer, "italic", now, 0.0);
  const float align = (float)doc_number(d, layer, "align", now, 0.0);
  const std::string wrapWord = doc_word(d, layer, "wrap");
  const float wrapAt = (float)doc_number(d, layer, "wrap_at", now, 0.0);
  const int breakAll = wrapWord == "anywhere" ? 1 : 0;
  const int vertical = doc_word(d, layer, "writing") == "vertical" ? 1 : 0;
  const std::string kinsoku = doc_word(d, layer, "kinsoku");
  const int hanging = doc_number(d, layer, "hanging", now, 0.0) > 0.5 ? 1 : 0;
  const std::string features = doc_word(d, layer, "font_features");
  const std::string styles = doc_word(d, layer, "text_styles");

  out.text = motolii_text_new(
      out.words.c_str(), styles.c_str(), fonts.c_str(),
      fine * kPixelsPerPoint, lineSpacing, tracking, slant,
      wrapAt > 0.f ? wrapAt * fine : 0.f, breakAll, align, vertical,
      kinsoku.empty() ? "normal" : kinsoku.c_str(), hanging, features.c_str());
  if (!out.text) {
    d.error = "could not lay out text outlines";
    return false;
  }

  const uint8_t* vptr = nullptr;
  const float* pptr = nullptr;
  int32_t vc = 0, pc = 0;
  motolii_text_path(out.text, &vptr, &vc, &pptr, &pc);
  if (vc > 0 && vptr) out.verbs.assign(vptr, vptr + vc);
  if (pc > 0 && pptr) out.points.assign(pptr, pptr + pc * 2);

  const int32_t nl = motolii_text_lines(out.text, nullptr);
  out.lines.resize((size_t)std::max(0, nl));
  if (nl > 0) motolii_text_lines(out.text, out.lines[0].data());

  const int32_t nc = motolii_text_letters(out.text, nullptr);
  out.letters.resize((size_t)std::max(0, nc));
  if (nc > 0) motolii_text_letters(out.text, out.letters[0].data());

  motolii_text_font(out.text, &out.ascent, &out.descent);

  if (out.lines.empty()) {
    d.error = "the text has no lines to convert";
    return false;
  }
  float x0 = out.lines[0][3], x1 = x0;
  float y0 = out.lines[0][0] - out.lines[0][1];
  float y1 = out.lines.back()[0] + out.lines.back()[2];
  for (const auto& l : out.lines)
    x0 = std::min(x0, l[3]), x1 = std::max(x1, l[3] + l[4]);
  for (size_t i = 0; i + 1 < out.points.size(); i += 2) {
    x0 = std::min(x0, out.points[i]);
    x1 = std::max(x1, out.points[i]);
    y0 = std::min(y0, out.points[i + 1]);
    y1 = std::max(y1, out.points[i + 1]);
  }
  out.x0 = x0;
  out.y0 = y0;
  out.wide = x1 - x0;
  out.tall = y1 - y0;
  if (out.wide <= 0.f || out.tall <= 0.f) {
    d.error = "the text has no outline to convert";
    return false;
  }
  out.size = std::max(1e-4, doc_number(d, layer, "size", now, 1.0));
  const float lineH = out.ascent + out.descent;
  out.pxToStage = out.size / (lineH > 0.f ? (double)lineH : (double)out.tall);
  return true;
}

struct SubLoop {
  std::vector<uint8_t> verbs;
  std::vector<float> pts;
  std::vector<std::pair<float, float>> poly;
  float minX = 1e30f, minY = 1e30f, maxX = -1e30f, maxY = -1e30f;
  double absArea = 0.0;
};

bool point_in_poly(float x, float y,
                   const std::vector<std::pair<float, float>>& poly) {
  bool inside = false;
  const size_t n = poly.size();
  for (size_t i = 0, j = n - 1; i < n; j = i++) {
    const float xi = poly[i].first, yi = poly[i].second;
    const float xj = poly[j].first, yj = poly[j].second;
    const bool hit = ((yi > y) != (yj > y)) &&
                     (x < (xj - xi) * (y - yi) / ((yj - yi) + 1e-12f) + xi);
    if (hit) inside = !inside;
  }
  return inside;
}

std::vector<SubLoop> split_text_subloops(const std::vector<uint8_t>& verbs,
                                         const std::vector<float>& pts) {
  std::vector<SubLoop> loops;
  SubLoop cur;
  float cx = 0.f, cy = 0.f;
  size_t pi = 0;

  const auto finish = [&] {
    if (cur.verbs.empty() || cur.poly.size() < 2) {
      cur = SubLoop{};
      return;
    }
    double area2 = 0.0;
    for (size_t i = 0; i < cur.poly.size(); ++i) {
      const auto& a = cur.poly[i];
      const auto& b = cur.poly[(i + 1) % cur.poly.size()];
      area2 += (double)a.first * b.second - (double)b.first * a.second;
      cur.minX = std::min(cur.minX, a.first);
      cur.maxX = std::max(cur.maxX, a.first);
      cur.minY = std::min(cur.minY, a.second);
      cur.maxY = std::max(cur.maxY, a.second);
    }
    cur.absArea = std::fabs(0.5 * area2);
    if (cur.absArea > 1e-4) loops.push_back(std::move(cur));
    cur = SubLoop{};
  };

  for (uint8_t v : verbs) {
    const uint8_t k = v & 3;
    if (k == 0) {
      if (!cur.verbs.empty()) finish();
      if (pi + 1 >= pts.size()) break;
      cx = pts[pi];
      cy = pts[pi + 1];
      pi += 2;
      cur.verbs.push_back(0);
      cur.pts.push_back(cx);
      cur.pts.push_back(cy);
      cur.poly.emplace_back(cx, cy);
    } else if (k == 1) {
      if (pi + 1 >= pts.size()) break;
      cx = pts[pi];
      cy = pts[pi + 1];
      pi += 2;
      cur.verbs.push_back(1);
      cur.pts.push_back(cx);
      cur.pts.push_back(cy);
      cur.poly.emplace_back(cx, cy);
    } else if (k == 2) {
      if (pi + 5 >= pts.size()) break;
      const float x1 = pts[pi], y1 = pts[pi + 1];
      const float x2 = pts[pi + 2], y2 = pts[pi + 3];
      const float x3 = pts[pi + 4], y3 = pts[pi + 5];
      pi += 6;
      cur.verbs.push_back(2);
      for (int j = 0; j < 6; ++j) cur.pts.push_back(pts[pi - 6 + j]);
      for (int s = 1; s <= 8; ++s) {
        const float t = (float)s / 8.f, u = 1.f - t;
        const float px = u * u * u * cx + 3.f * u * u * t * x1 +
                         3.f * u * t * t * x2 + t * t * t * x3;
        const float py = u * u * u * cy + 3.f * u * u * t * y1 +
                         3.f * u * t * t * y2 + t * t * t * y3;
        cur.poly.emplace_back(px, py);
      }
      cx = x3;
      cy = y3;
    } else {
      cur.verbs.push_back(3);
      finish();
    }
  }
  finish();
  return loops;
}

std::string serialize_loops_path(const std::vector<const SubLoop*>& group,
                                 float originX, float originY, double scale) {
  std::string path;
  char one[96];
  const auto fmt = [&](float x, float y) {
    std::snprintf(one, sizeof one, "%.5f %.5f", ((double)x - originX) * scale,
                  ((double)y - originY) * scale);
    return std::string(one);
  };
  for (const SubLoop* loop : group) {
    size_t pi = 0;
    for (uint8_t v : loop->verbs) {
      if (v == 0 && pi + 1 < loop->pts.size()) {
        path += (path.empty() ? "M" : " M") + fmt(loop->pts[pi], loop->pts[pi + 1]);
        pi += 2;
      } else if (v == 1 && pi + 1 < loop->pts.size()) {
        path += " L" + fmt(loop->pts[pi], loop->pts[pi + 1]);
        pi += 2;
      } else if (v == 2 && pi + 5 < loop->pts.size()) {
        path += " C" + fmt(loop->pts[pi], loop->pts[pi + 1]) + " " +
                fmt(loop->pts[pi + 2], loop->pts[pi + 3]) + " " +
                fmt(loop->pts[pi + 4], loop->pts[pi + 5]);
        pi += 6;
      } else if (v == 3) {
        path += " Z";
      }
    }
  }
  return path;
}

}  // namespace

bool doc_to_path(Doc& d, int layer) {
  if (doc_word(d, layer, "kind") == "text") {
    TextOutlineLayout lay;
    if (!layout_text_for_paths(d, layer, lay)) return false;
    const auto loops = split_text_subloops(lay.verbs, lay.points);
    if (loops.empty()) {
      d.error = "the text has no outline to make a path of";
      return false;
    }
    std::vector<const SubLoop*> all;
    all.reserve(loops.size());
    for (const auto& l : loops) all.push_back(&l);
    const float cx = lay.x0 + 0.5f * lay.wide, cy = lay.y0 + 0.5f * lay.tall;
    const std::string path =
        serialize_loops_path(all, cx, cy, 1.0 / std::max((double)lay.tall, 1.0));
    if (path.empty()) return d.error = "it has no outline to make a path of", false;
    const double now = d.stage ? d.stage->now : 0.0;
    const double sx = doc_number(d, layer, "scale_x", now, 1.0) * lay.tall * lay.pxToStage;
    const double sy = doc_number(d, layer, "scale_y", now, 1.0) * lay.tall * lay.pxToStage;
    doc_act(d);
    bool ok = doc_change(
                  d, sqlite3_mprintf(
                         "update keyframe set value = 'shape' where layer = %d "
                         "and name = 'kind'",
                         layer)) &&
              doc_say(d, layer, "shape", "path") &&
              doc_say(d, layer, "path", path.c_str()) &&
              doc_set(d, layer, "scale_x", sx) &&
              doc_set(d, layer, "scale_y", sy);
    if (!ok) d.act.ok = false;
    return doc_acted(d) && ok;
  }
  const std::string form = doc_word(d, layer, "shape");
  if (doc_word(d, layer, "kind") != "shape" || form.empty() || form == "path" ||
      form == "null" || form == "solid")
    return d.error =
               "only a shape of a kind of its own is made a path (not a path, "
               "a null or a solid)",
           false;
  const bool line = form == "line", wave = form == "wave";
  // The shape's height and width in its own units, with the defaults that
  // doc_match uses.
  const double high = line   ? 0.04
                      : wave ? 0.3
                             : 1.0,
               wide = doc_number(d, layer, "wide", 0,
                                 line   ? 25
                                 : wave ? 10
                                        : 1);
  const int h = 1024, w = std::max(2, (int)std::lround(1024.0 * wide));
  Canvas2D made;
  tvg::Shape* shape = tvg::Shape::gen();
  flat_path(&made, shape, form.c_str(), w, h, 0.f,
            (int)doc_number(d, layer, "points", 0,
                            form == "star"       ? 5
                            : form == "rect"     ? 4
                            : form == "arc"      ? 270
                            : form == "squircle" ? 4
                            : form == "cog"      ? 12
                            : form == "spiral"   ? 3
                            : wave               ? 4
                                                 : 6),
            (float)doc_number(d, layer, "inner", 0,
                              form == "cog"       ? 0.2
                              : form == "arc"     ? 0.3
                              : form == "spiral"  ? 0.1
                              : form == "chamfer" ? 0.3
                              : form == "rect"    ? 0.0
                                                  : 0.5),
            0.f, 0.f);
  const auto num = [&](const char* name, double usual) {
    return (float)doc_number(d, layer, name, d.stage->now, usual);
  };
  tvg_bend(shape, made.plain.data(), (uint32_t)made.plain.size(),
           made.plainAt.data(), (uint32_t)made.plainAt.size(),
           line ? 0.f : std::clamp(num("round", 0), 0.f, 0.5f) * made.plainSide,
           100.f * std::clamp(num("bloat", 0), -1.f, 1.f),
           num("zigzag", 0) * (float)h,
           (int)std::clamp(num("zigzag_ridges", 5), 0.f, 100.f),
           num("zigzag_smooth", 0) > 0.5f, num("offset", 0) * (float)h, 0.f);
  const tvg::PathCommand* cmds;
  const tvg::Point* pts;
  uint32_t cmdsCnt = 0, ptsCnt = 0;
  shape->path(&cmds, &cmdsCnt, &pts, &ptsCnt);
  std::string path;
  char one[96];
  const auto at = [&](const tvg::Point& p) {
    std::snprintf(one, sizeof one, "%.5f %.5f", (p.x - 0.5 * w) / h * high,
                  (p.y - 0.5 * h) / h * high);
    return std::string(one);
  };
  for (uint32_t c = 0, p = 0; c < cmdsCnt; ++c) switch (cmds[c]) {
      case tvg::PathCommand::MoveTo:
        path += (path.empty() ? "M" : " M") + at(pts[p++]);
        break;
      case tvg::PathCommand::LineTo:
        path += " L" + at(pts[p++]);
        break;
      case tvg::PathCommand::CubicTo:
        path += " C" + at(pts[p]) + " " + at(pts[p + 1]) + " " + at(pts[p + 2]),
            p += 3;
        break;
      case tvg::PathCommand::Close:
        path += " Z";
        break;
    }
  tvg::Paint::rel(shape);
  if (path.empty())
    return d.error = "it has no outline to make a path of", false;
  doc_act(d);
  bool ok = doc_say(d, layer, "shape", "path") &&
            doc_say(d, layer, "path", path.c_str()) &&
            doc_set(d, layer, "wide", wide * high);
  for (const char* name : {"round", "bloat", "zigzag", "offset"})
    if (ok && doc_number(d, layer, name, 0, 0) != 0.0)
      ok = doc_set(d, layer, name, 0.0);
  if (!ok) d.act.ok = false;
  return doc_acted(d) && ok;
}

int doc_text_explode(Doc& d, int layer, const char* mode) {
  TextOutlineLayout lay;
  if (!layout_text_for_paths(d, layer, lay)) return 0;

  const bool strokesMode = mode && std::string(mode) == "strokes";
  const double now = d.stage ? d.stage->now : 0.0;
  const std::string baseName = doc_word(d, layer, "name").empty()
                                   ? lay.words
                                   : doc_word(d, layer, "name");
  const std::string fill = doc_word(d, layer, "fill");
  const std::string stroke = doc_word(d, layer, "stroke");
  const std::string space = doc_word(d, layer, "space");
  const double strokeWidth = doc_number(d, layer, "stroke_width", now, 0.0);
  const double start = doc_number(d, layer, "start", 0.0, 0.0);
  const double duration = doc_number(d, layer, "duration", 0.0, -1.0);
  const double opacity = doc_number(d, layer, "opacity", now, 1.0);
  const double origParent = doc_number(d, layer, "parent", 0.0, 0.0);
  const float cx = lay.x0 + 0.5f * lay.wide;
  const float cy = lay.y0 + 0.5f * lay.tall;

  doc_act(d);
  const int grp = doc_add(d, "shape", "null");
  bool ok = grp != 0;
  if (ok) {
    const std::string gname =
        baseName + (strokesMode ? " (Strokes)" : " (Letters)");
    // Keep grp at identity while parenting children so doc_parent preserves each
    // child's exact local offset, then apply the original text's transform last.
    ok = doc_say(d, grp, "name", gname.c_str()) &&
         doc_set(d, grp, "start", start) &&
         doc_set(d, grp, "duration", duration);
    if (ok && !space.empty()) ok = doc_say(d, grp, "space", space.c_str());
  }

  const auto cps = utf8_codepoints(lay.words);
  int created = 0;

  if (!strokesMode) {
    // One editable text layer per non-whitespace glyph, placed at its exact
    // Parley layout coordinates relative to the original text box centre.
    const double italic = doc_number(d, layer, "italic", now, 0.0);
    for (size_t i = 0; i < cps.size() && i < lay.letters.size() && ok; ++i) {
      const std::string& ch = cps[i];
      if (ch == " " || ch == "\t" || ch == "\n" || ch == "\r" || ch == "　")
        continue;
      const auto& lt = lay.letters[i];
      const int lineIdx = std::clamp((int)std::lround(lt[4]), 0,
                                     (int)lay.lines.size() - 1);
      const auto& ln = lay.lines[(size_t)lineIdx];
      const float lcx =
          lt[3] > lt[2] ? 0.5f * (lt[2] + lt[3]) : lt[0] + 0.5f * lt[1];
      const float lcy = ln[0] - 0.5f * (ln[1] - ln[2]);
      const int child = doc_add(d, "text", lay.fontFile.c_str());
      if (!child) {
        ok = false;
        break;
      }
      ok = doc_say(d, child, "text", ch.c_str()) &&
           doc_say(d, child, "name", ch.c_str()) &&
           doc_set(d, child, "size", lay.size) &&
           doc_set(d, child, "x", ((double)lcx - cx) * lay.pxToStage) &&
           doc_set(d, child, "y", -((double)lcy - cy) * lay.pxToStage) &&
           doc_set(d, child, "start", start) &&
           doc_set(d, child, "duration", duration) &&
           doc_set(d, child, "opacity", opacity) &&
           doc_parent(d, child, (double)grp);
      if (ok && italic != 0.0) ok = doc_set(d, child, "italic", italic);
      if (ok && !fill.empty()) ok = doc_say(d, child, "fill", fill.c_str());
      if (ok && !stroke.empty())
        ok = doc_say(d, child, "stroke", stroke.c_str()) &&
             doc_set(d, child, "stroke_width", strokeWidth);
      if (ok && !space.empty()) ok = doc_say(d, child, "space", space.c_str());
      if (ok) ++created;
    }
  } else {
    // Classic "gg" decomposition: split all glyph subpaths, pair inner holes
    // with their enclosing outer contours by even-odd nesting depth, and emit
    // one centered path shape per independent stroke/radical part.
    auto loops = split_text_subloops(lay.verbs, lay.points);
    std::sort(loops.begin(), loops.end(), [](const SubLoop& a, const SubLoop& b) {
      return a.absArea > b.absArea;
    });

    struct GgPart {
      std::vector<const SubLoop*> loops;
      float minX = 1e30f, minY = 1e30f, maxX = -1e30f, maxY = -1e30f;
    };
    std::vector<GgPart> parts;
    std::vector<int> owner(loops.size(), -1);
    for (size_t i = 0; i < loops.size(); ++i) {
      const float px = loops[i].poly[0].first, py = loops[i].poly[0].second;
      int depth = 0, nearestOuter = -1;
      for (size_t j = 0; j < i; ++j) {
        if (px < loops[j].minX || px > loops[j].maxX || py < loops[j].minY ||
            py > loops[j].maxY)
          continue;
        if (point_in_poly(px, py, loops[j].poly)) {
          ++depth;
          nearestOuter = (int)j;
        }
      }
      int gi = -1;
      if ((depth % 2) == 1 && nearestOuter >= 0 && owner[(size_t)nearestOuter] >= 0) {
        gi = owner[(size_t)nearestOuter];
      } else {
        gi = (int)parts.size();
        parts.emplace_back();
      }
      owner[i] = gi;
      auto& g = parts[(size_t)gi];
      g.loops.push_back(&loops[i]);
      g.minX = std::min(g.minX, loops[i].minX);
      g.minY = std::min(g.minY, loops[i].minY);
      g.maxX = std::max(g.maxX, loops[i].maxX);
      g.maxY = std::max(g.maxY, loops[i].maxY);
    }

    // Order parts left-to-right, top-to-bottom so stagger flows naturally.
    std::sort(parts.begin(), parts.end(), [](const GgPart& a, const GgPart& b) {
      const float ax = 0.5f * (a.minX + a.maxX), bx = 0.5f * (b.minX + b.maxX);
      const float ay = 0.5f * (a.minY + a.maxY), by = 0.5f * (b.minY + b.maxY);
      if (std::fabs(ax - bx) > 8.f) return ax < bx;
      return ay < by;
    });

    std::vector<int> letterCounts(cps.size(), 0);
    for (size_t pi = 0; pi < parts.size() && ok; ++pi) {
      const auto& part = parts[pi];
      const float pcx = 0.5f * (part.minX + part.maxX);
      const float pcy = 0.5f * (part.minY + part.maxY);
      const float ph = std::max(part.maxY - part.minY, 1.f);
      const std::string path =
          serialize_loops_path(part.loops, pcx, pcy, 1.0 / (double)ph);
      if (path.empty()) continue;

      // Attribute this stroke part to its nearest character for readable naming
      // and character-class rules in panels/expressions.
      int bestChar = -1;
      float bestDist = 1e30f;
      for (size_t li = 0; li < lay.letters.size() && li < cps.size(); ++li) {
        const auto& lt = lay.letters[li];
        const int lidx = std::clamp((int)std::lround(lt[4]), 0,
                                    (int)lay.lines.size() - 1);
        const auto& ln = lay.lines[(size_t)lidx];
        const float lcx =
            lt[3] > lt[2] ? 0.5f * (lt[2] + lt[3]) : lt[0] + 0.5f * lt[1];
        const float lcy = ln[0] - 0.5f * (ln[1] - ln[2]);
        const float dist = std::hypot(pcx - lcx, pcy - lcy);
        if (dist < bestDist) bestDist = dist, bestChar = (int)li;
      }
      std::string partName = "Part " + std::to_string(pi + 1);
      if (bestChar >= 0) {
        const int idx = ++letterCounts[(size_t)bestChar];
        partName = cps[(size_t)bestChar] + " #" + std::to_string(idx);
      }

      const int child = doc_add(d, "shape", "path");
      if (!child) {
        ok = false;
        break;
      }
      const double scale = (double)ph * lay.pxToStage;
      ok = doc_say(d, child, "path", path.c_str()) &&
           doc_say(d, child, "name", partName.c_str()) &&
           doc_set(d, child, "x", ((double)pcx - cx) * lay.pxToStage) &&
           doc_set(d, child, "y", -((double)pcy - cy) * lay.pxToStage) &&
           doc_set(d, child, "scale_x", scale) &&
           doc_set(d, child, "scale_y", scale) &&
           doc_set(d, child, "start", start) &&
           doc_set(d, child, "duration", duration) &&
           doc_set(d, child, "opacity", opacity) &&
           doc_parent(d, child, (double)grp);
      if (ok)
        ok = doc_say(d, child, "fill", fill.empty() ? "ffffff" : fill.c_str());
      if (ok && !stroke.empty())
        ok = doc_say(d, child, "stroke", stroke.c_str()) &&
             doc_set(d, child, "stroke_width", strokeWidth);
      if (ok && !space.empty()) ok = doc_say(d, child, "space", space.c_str());
      if (ok) ++created;
    }
  }

  if (ok && created == 0) {
    d.error = "the text produced no parts";
    ok = false;
  }
  if (ok) {
    ok = doc_set(d, grp, "x", doc_number(d, layer, "x", now, 0.0)) &&
         doc_set(d, grp, "y", doc_number(d, layer, "y", now, 0.0)) &&
         doc_set(d, grp, "z", doc_number(d, layer, "z", now, 0.0)) &&
         doc_set(d, grp, "scale_x", doc_number(d, layer, "scale_x", now, 1.0)) &&
         doc_set(d, grp, "scale_y", doc_number(d, layer, "scale_y", now, 1.0)) &&
         doc_set(d, grp, "rotate", doc_number(d, layer, "rotate", now, 0.0)) &&
         doc_set(d, grp, "rotate_x", doc_number(d, layer, "rotate_x", now, 0.0)) &&
         doc_set(d, grp, "rotate_y", doc_number(d, layer, "rotate_y", now, 0.0));
    if (ok && origParent > 0.5) ok = doc_parent(d, grp, origParent);
  }
  if (ok) ok = doc_set(d, layer, "visible", 0.0);
  if (!ok) d.act.ok = false;
  return doc_acted(d) && ok ? grp : 0;
}

namespace {

// One shape read out of an SVG: its outline, already in the drawing's own
// coordinates (the shape's own transform folded in), and the look it was drawn
// with. The outline is turned into a path string once the whole drawing's box
// is known, so every part shares one frame.
struct SvgPart {
  std::vector<tvg::PathCommand> cmds;
  std::vector<std::pair<float, float>>
      pts;             // the shape's own transform applied
  std::string fill;    // "rrggbb", or "none" for a shape with no fill
  std::string stroke;  // "rrggbb", or "" for no stroke
  float strokeWidth =
      0.f;  // in the SVG's own units, before the drawing is framed
};

}  // namespace

int doc_svg_paths(Doc& d, const char* file) {
  // ThorVG reads no file until it is started (image_pixels.cpp). Reading the
  // outlines needs no canvas: the Accessor walks the scene tree on the CPU.
  tvg::Initializer::init(0);
  tvg::Picture* pic = tvg::Picture::gen();
  if (!pic) return 0;
  if (pic->load(file) != tvg::Result::Success) {
    delete pic;
    return 0;  // not a vector drawing ThorVG can read
  }
  std::vector<SvgPart> parts;
  bool faithless =
      false;  // a transform or gradient this cannot keep as a shape
  float minX = 1e30f, minY = 1e30f, maxX = -1e30f, maxY = -1e30f;
  tvg::Accessor* walk = tvg::Accessor::gen();
  walk->set(
      pic,
      [&](const tvg::Paint* node, void*) {
        // transform() is not const, but nothing is changed here.
        const tvg::Matrix m = const_cast<tvg::Paint*>(node)->transform();
        const bool plain = m.e11 == 1 && m.e12 == 0 && m.e13 == 0 &&
                           m.e21 == 0 && m.e22 == 1 && m.e23 == 0;
        if (node->type() == tvg::Type::Scene) {
          // A <g> transform moves all it holds. This folds in only each
          // shape's own transform, not the chain of its parents, so a moved
          // group is left to the picture path rather than placed wrong.
          if (!plain) faithless = true;
          return true;
        }
        if (node->type() != tvg::Type::Shape) return true;
        const tvg::Shape* sh = static_cast<const tvg::Shape*>(node);
        const tvg::PathCommand* cmds = nullptr;
        const tvg::Point* pts = nullptr;
        uint32_t cc = 0, pc = 0;
        sh->path(&cmds, &cc, &pts, &pc);
        if (cc == 0 || pc == 0) return true;
        SvgPart part;
        part.cmds.assign(cmds, cmds + cc);
        part.pts.reserve(pc);
        for (uint32_t i = 0; i < pc; ++i) {
          const float x = m.e11 * pts[i].x + m.e12 * pts[i].y + m.e13,
                      y = m.e21 * pts[i].x + m.e22 * pts[i].y + m.e23;
          part.pts.emplace_back(x, y);
          minX = std::min(minX, x), maxX = std::max(maxX, x);
          minY = std::min(minY, y), maxY = std::max(maxY, y);
        }
        // The fill. A gradient is a Fill a shape cannot hold, so the whole
        // drawing goes to the picture path rather than drop its look. A shape
        // with no solid fill is drawn hollow ("none").
        uint8_t r = 0, g = 0, b = 0, a = 0;
        char hex[8];
        if (sh->fill() != nullptr)
          faithless = true;
        else if (sh->fill(&r, &g, &b, &a) == tvg::Result::Success && a > 0) {
          std::snprintf(hex, sizeof hex, "%02x%02x%02x", r, g, b);
          part.fill = hex;
        } else
          part.fill = "none";
        // The stroke, if the shape has one.
        const float sw = sh->strokeWidth();
        if (sw > 0.f) {
          if (sh->strokeFill() != nullptr)
            faithless = true;
          else if (sh->strokeFill(&r, &g, &b, &a) == tvg::Result::Success &&
                   a > 0) {
            std::snprintf(hex, sizeof hex, "%02x%02x%02x", r, g, b);
            part.stroke = hex, part.strokeWidth = sw;
          }
        }
        parts.push_back(std::move(part));
        return true;
      },
      nullptr);
  delete walk;
  delete pic;
  const float H = maxY - minY, W = maxX - minX;
  if (parts.empty() || faithless || H <= 0.f || W <= 0.f)
    return 0;  // leave it to the picture path
  // One drawing-height is one unit, framed to the whole drawing and centred, so
  // the outline sits in the same units a drawn shape uses (doc_to_path). y is
  // down, as in SVG.
  const double s = 1.0 / H, cx = 0.5 * (minX + maxX), cy = 0.5 * (minY + maxY);
  char one[96];
  const auto at = [&](const std::pair<float, float>& p) {
    std::snprintf(one, sizeof one, "%.5f %.5f", (p.first - cx) * s,
                  (p.second - cy) * s);
    return std::string(one);
  };
  doc_act(d);
  const std::string stem = std::filesystem::path(file).stem().generic_string();
  const int grp = doc_add(d, "shape", "null");
  bool ok = grp != 0;
  if (ok) doc_say(d, grp, "name", (stem.empty() ? "SVG" : stem).c_str());
  for (const SvgPart& part : parts) {
    if (!ok) break;
    std::string path;
    for (uint32_t c = 0, p = 0; c < (uint32_t)part.cmds.size(); ++c)
      switch (part.cmds[c]) {
        case tvg::PathCommand::MoveTo:
          path += (path.empty() ? "M" : " M") + at(part.pts[p]);
          ++p;
          break;
        case tvg::PathCommand::LineTo:
          path += " L" + at(part.pts[p]);
          ++p;
          break;
        case tvg::PathCommand::CubicTo:
          path += " C" + at(part.pts[p]) + " " + at(part.pts[p + 1]) + " " +
                  at(part.pts[p + 2]);
          p += 3;
          break;
        case tvg::PathCommand::Close:
          path += " Z";
          break;
      }
    if (path.empty()) continue;
    const int lay = doc_add(d, "shape", "path");
    if (!lay) {
      ok = false;
      break;
    }
    ok = doc_say(d, lay, "path", path.c_str()) &&
         doc_say(d, lay, "fill", part.fill.c_str());
    if (ok && !part.stroke.empty())
      // stroke_width is in image points at the scale layers start at, so the
      // stroke's fraction of the drawing's height (strokeWidth * s) is taken
      // back to points of a layer one stage-height tall (match_look.cpp).
      ok = doc_say(d, lay, "stroke", part.stroke.c_str()) &&
           doc_set(d, lay, "stroke_width",
                   part.strokeWidth * s * 0.5 * (double)d.stage->h);
    if (ok) ok = doc_parent(d, lay, (double)grp);
  }
  if (!ok) d.act.ok = false;
  return doc_acted(d) && ok ? grp : 0;
}

}  // namespace motolii
