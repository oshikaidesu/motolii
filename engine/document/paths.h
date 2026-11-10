// paths.h: the plane and points of path shapes for doc.h, and the tools that create or convert
// them. Included by doc.h; not self-contained.
// The plane of a path shape as the image shows it: its middle and its two axes. own() converts a
// point of the image to the shape's own coordinates, where the shape is 1 high, measured from its
// middle with y pointing down as in SVG. at() converts a point back.
struct DocPlane {
    // The shape's middle and its x and y axes, in points of the image. The axes are vectors from
    // the middle.
    math::double2 o, ex, ey;
    // Determinant of the two axes. A value near zero means the shape is seen edge on.
    double det;
    // Whether the plane can be inverted, that is, whether the shape is not seen edge on.
    bool seen;
    // Builds the plane of the layer at time `now`.
    DocPlane(Doc& d, int layer, double now) {
        const math::mat4 at = doc_shown_at(d, layer, now);
        o = doc_seen(d, (at * math::double4{0, 0, 0, 1}).xyz), ex = doc_seen(d, (at * math::double4{1, 0, 0, 1}).xyz) - o, ey = doc_seen(d, (at * math::double4{0, 1, 0, 1}).xyz) - o;
        det = ex.x * ey.y - ex.y * ey.x, seen = std::fabs(det) > 1e-9;
    }
    // Converts a point of the image to the shape's own coordinates.
    math::double2 own(double px, double py) const { const double u = px - o.x, v = py - o.y; return {(u * ey.y - v * ey.x) / det, -(ex.x * v - ex.y * u) / det}; }
    // Converts a point in the shape's own coordinates to a point of the image.
    math::double2 at(double fx, double fy) const { return o + ex * fx - ey * fy; }
};
// The sk_svg_* functions read and edit SVG path data with Skia (see
// engine/stage/canvas/skia_path_operations.cpp).
// Writes the path's anchor points to xy as x, y pairs and returns how many there are.
int sk_svg_anchors(const char* data, std::vector<float>& xy);
// Returns how the path ends, using Skia's verbs: 0 not read or empty, 1 a move alone, 2 a line, 3 a
// curve, 4 closed. Writes the first point to fx, fy and the number of stretches to stretches.
int sk_svg_ends(const char* data, float& fx, float& fy, int& stretches);
// Moves the nth anchor by dx, dy, together with its handles, and writes the new path data to out.
// Returns false on failure.
bool sk_svg_move(const char* data, int nth, float dx, float dy, std::string& out);
// Writes the curves' handles to xy as x, y pairs and returns how many there are. If of is given, it
// receives the anchor each handle belongs to.
int sk_svg_handles(const char* data, std::vector<float>& xy, std::vector<float>* of = nullptr);
// Moves the nth handle by dx, dy and writes the new path data to out. Returns false on failure.
bool sk_svg_move_handle(const char* data, int nth, float dx, float dy, std::string& out);
// Edits the path at x, y. A point within reach is removed, and a point on the outline gets a new
// point put there. Writes the new path data to out. Returns 1 if a point was removed, 2 if one was
// put, and 0 if nothing changed.
int sk_svg_edit(const char* data, float x, float y, float reach, std::string& out);
// Returns the number of points of a path shape and writes up to `room` of them to xy as x, y pairs,
// in points of the image from its top left. Returns 0 if the layer is not a path shape. If handles
// is true, writes the curves' handles instead of the points, and, if `of` is given, writes the
// point each handle belongs to (of[2i], of[2i+1]).
static int doc_points(Doc& d, int layer, double now, double* xy, int room, bool handles = false, double* of = nullptr) {
    if (!doc_knows(d, layer) || doc_word(d, layer, "shape") != "path") return 0;
    std::vector<float> own, owner;
    const std::string path = doc_word(d, layer, "path");
    const int n = handles ? sk_svg_handles(path.c_str(), own, &owner) : sk_svg_anchors(path.c_str(), own);
    const DocPlane plane(d, layer, now);
    for (int i = 0; i < n && i < room; ++i) {
        const math::double2 p = plane.at(own[2 * i], own[2 * i + 1]);
        xy[2 * i] = p.x, xy[2 * i + 1] = p.y;
        if (of) { const math::double2 o = plane.at(owner[2 * i], owner[2 * i + 1]); of[2 * i] = o.x, of[2 * i + 1] = o.y; }
    }
    return n;
}
// Adds to the path of a path shape, as a pen tool does. The point goes at x, y in points of the
// image from its top left, and its handle is pulled out by hx, hy in points, where 0, 0 makes a
// corner. The path gets either a line to the point or, as Illustrator's pen makes one, a curve
// through it (SVG's S command: the point before becomes smooth, with its handle turned through).
// Clicking on the first point again closes the path. On a closed path, a click on one of its points
// removes that point, a click on its outline puts a point there, and a click elsewhere begins
// another path, as Illustrator's pen does. With layer 0 a new path shape is begun, with its first
// point, as one undo step. Returns the layer number, or 0 on failure.
static int doc_pen(Doc& d, int layer, double x, double y, double hx, double hy) {
    const double now = d.stage->now;
    doc_act(d);
    // The layer is not a path, so the pen begins one.
    if (layer && (!doc_knows(d, layer) || doc_word(d, layer, "shape") != "path")) layer = 0;
    // If the path is closed, a click on one of its points removes it, and a click on its outline
    // puts a point there. Otherwise the pen begins another path.
    if (const std::string was = layer ? doc_word(d, layer, "path") : ""; [&] { float fx, fy; int n; return sk_svg_ends(was.c_str(), fx, fy, n) == 4; }()) {
        const DocPlane plane(d, layer, now);
        const math::double2 p = plane.own(x, y);
        std::string edited;
        if (plane.seen && sk_svg_edit(was.c_str(), (float)p.x, (float)p.y, (float)(8.0 / std::max(1e-9, length(plane.ex))), edited)) {
            if (!doc_say(d, layer, "path", edited.c_str())) d.act_ok = false;
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
        // Skia's reading of the path (see engine/stage/canvas/skia_path_operations.cpp).
        const int last = sk_svg_ends(path.c_str(), first_x, first_y, stretches);
        const double fx = first_x, fy = first_y;
        const bool smooth = last == 3, handle = hx != 0.0 || hy != 0.0;
        // The click is back on the first point if it is within 8 points of it.
        const bool closes = stretches > 0 && last != 4 && length(o + ex * fx - ey * fy - math::double2{x, y}) < 8.0;
        if (path.empty()) std::snprintf(said, sizeof said, "M%.4f %.4f", p.x, p.y);
        else if (closes) std::snprintf(said, sizeof said, smooth || handle ? " S%.4f %.4f %.4f %.4f Z" : " Z", handle ? own(o.x + ex.x * fx - ey.x * fy - hx, o.y + ex.y * fx - ey.y * fy - hy).x : fx,
                                       handle ? own(o.x + ex.x * fx - ey.x * fy - hx, o.y + ex.y * fx - ey.y * fy - hy).y : fy, fx, fy);
        else if (!smooth && !handle) std::snprintf(said, sizeof said, " L%.4f %.4f", p.x, p.y);
        else std::snprintf(said, sizeof said, " S%.4f %.4f %.4f %.4f", in.x, in.y, p.x, p.y);
        if (!doc_say(d, layer, "path", (path + said).c_str())) layer = 0;
    }
    if (!layer) d.act_ok = false;
    return doc_acted(d) ? layer : 0;
}
// Takes a video's sound out to a layer of its own, as Alight Motion's Extract Audio does. The new
// layer is a hidden copy of the video with " (sound)" added to its name. The copy is still heard,
// because the sound of a hidden video plays (see match.h). The video itself is no longer heard,
// since its volume is set to 0. This is one undo step. Returns the new layer, or 0 on failure.
static int doc_extract_sound(Doc& d, int layer) {
    if (!doc_knows(d, layer) || doc_word(d, layer, "kind") != "video") return d.error = "only a video's sound is taken out", 0;
    doc_act(d);
    const int made = doc_duplicate(d, layer);
    const bool ok = made && doc_set(d, made, "visible", 0) && doc_say(d, made, "name", (doc_name(d, layer) + " (sound)").c_str()) && doc_set(d, layer, "volume", 0);
    return doc_acted(d) && ok ? made : 0;
}
// Creates a path shape from a freehand stroke. `points` is the outline that perfect-freehand makes
// around the user's stroke, as x y pairs in points of the image. perfect-freehand is by Steve Ruiz
// (MIT license), and the app uses its Dart port by Adil Hanney. The outline becomes a closed path,
// with each point joined to the next by a quadratic curve through their midpoint, as perfect-
// freehand's example draws the outline. This is one undo step. Returns the new layer, or 0 on
// failure.
static int doc_freehand(Doc& d, const char* points) {
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
            const math::double2 p = plane.own(xy[2 * i], xy[2 * i + 1]), q = plane.own(xy[2 * ((i + 1) % n)], xy[2 * ((i + 1) % n) + 1]);
            if (!i) std::snprintf(one, sizeof one, "M%.4f %.4f", p.x, p.y), path += one;
            std::snprintf(one, sizeof one, " Q%.4f %.4f %.4f %.4f", p.x, p.y, (p.x + q.x) / 2, (p.y + q.y) / 2);
            path += one;
        }
        if (!doc_say(d, layer, "path", (path + " Z").c_str())) layer = 0;
    }
    if (!layer) d.act_ok = false;
    return doc_acted(d) ? layer : 0;
}
// Creates a path shape from a freehand stroke, fitted with cubic Bezier curves. `said` holds the
// error, then x y pairs of the stroke, in points of the image. The stroke is fitted with the fewest
// cubics that stay within `error` points of it. Sharp turns, those past 70 degrees, are kept as
// corners. Blender's Draw Curve tool fits a stroke in the same way (editcurve_paint.cc,
// curve_fit_cubic_to_points_refit). The app uses an error of 8 screen points.
// The fitting library is curve-fit-nd by Campbell Barton (BSD-3-Clause). A stroke that ends where
// it began becomes a closed path. The anchors and handles are those of an ordinary pen path (M and
// C commands) and can be moved like any other. Returns the new layer, or 0 on failure.
static int doc_curve(Doc& d, const char* said) {
    std::istringstream in(said);
    double error = 0.0;
    in >> error;
    std::vector<double> xy;
    // Skip a point that is within 1% of `error` of the previous one, since curve-fit-nd does not
    // accept a stretch of no length.
    for (double x, y; in >> x >> y;)
        if (xy.empty() || std::hypot(x - xy[xy.size() - 2], y - xy.back()) > 0.01 * error) xy.push_back(x), xy.push_back(y);
    const unsigned n = (unsigned)(xy.size() / 2);
    if (!(error > 0.0) || n < 3) return d.error = "a stroke of fewer than three points", 0;
    // The stroke is closed if it ends within four times `error` of where it began.
    const bool closed = std::hypot(xy[0] - xy[2 * n - 2], xy[1] - xy[2 * n - 1]) < 4 * error;
    double* cubic = nullptr;
    unsigned cubics = 0, *orig = nullptr, *corners = nullptr, cornersLen = 0;
    if (curve_fit_cubic_to_points_refit_db(xy.data(), closed ? n - 1 : n, 2, error, CURVE_FIT_CALC_HIGH_QUALITY | (closed ? CURVE_FIT_CALC_CYCLIC : 0), nullptr, 0, 70.0 * M_PI / 180.0,
                                           &cubic, &cubics, &orig, &corners, &cornersLen) || cubics < 2) {
        free(cubic), free(orig), free(corners);
        return d.error = "the stroke made no curve", 0;
    }
    doc_act(d);
    int layer = doc_add(d, "shape", "path");
    const DocPlane plane(d, layer, d.stage->now);
    if (layer && !plane.seen) d.error = "its plane is seen edge on", layer = 0;
    if (layer) {
        // Formats one point of cubic k as text. part is 0 for its incoming handle, 1 for the
        // anchor, and 2 for its outgoing handle.
        const auto at = [&](unsigned k, int part) { const double* c = cubic + (k * 3 + part) * 2; const math::double2 p = plane.own(c[0], c[1]); char one[64]; std::snprintf(one, sizeof one, "%.4f %.4f", p.x, p.y); return std::string(one); };
        std::string path = "M" + at(0, 1);
        for (unsigned k = 1; k < cubics + (closed ? 1 : 0); ++k) path += " C" + at(k - 1, 2) + " " + at(k % cubics, 0) + " " + at(k % cubics, 1);
        if (closed) path += " Z";
        if (!doc_say(d, layer, "path", path.c_str())) layer = 0;
    }
    free(cubic), free(orig), free(corners);
    if (!layer) d.act_ok = false;
    return doc_acted(d) ? layer : 0;
}
// Creates a path shape from a brush stroke, or adds a stroke to an existing drawing. `said` holds
// the tool, the brush size in points of the image, and then x y pressure for each point. The points
// come from perfect-freehand, each with the pressure its radius comes from.
// The shape keeps the stroke as drawn in its `drawing` property: the tool, the width, and each
// point with its pressure, in the plane's own units. Its outline is generated from that by
// AbsentMotion (absent_drawing, Alight Motion's brush, a band of round pieces). The drawing effects
// apply to it as time goes by (see doc_evaluate).
// The tools are those of AbsentMotion: 0 a pen, as wide all along; 1 a brush, as wide as the
// pressure says; 2 a fill, which fills the area the stroke goes round; 3 an eraser, a stroke added
// to the drawing of layer `into`, which removes what that drawing has drawn, as AbsentMotion's
// eraser clears within its drawing layer. Returns the shape that was made or erased from, or 0 on
// failure.
static int doc_brush(Doc& d, const char* said, int into = 0) {
    std::istringstream in(said);
    int tool = 1;
    double size = 0.0;
    in >> tool >> size;
    tool = std::clamp(tool, 0, 3);
    std::vector<double> xyp;
    for (double v; in >> v;) xyp.push_back(v);
    if (!(size > 0.0) || xyp.size() < 6) return d.error = "a stroke of fewer than two points", 0;
    const std::string was = tool == 3 ? doc_word(d, into, "drawing") : std::string();
    if (tool == 3 && was.empty()) return d.error = "an eraser takes from a drawing: pick one", 0;
    doc_act(d);
    int layer = tool == 3 ? into : doc_add(d, "shape", "path");
    const DocPlane plane(d, layer, d.stage->now);
    if (layer && !plane.seen) d.error = "its plane is seen edge on", layer = 0;
    if (layer) {
        const double wide = length(plane.own(xyp[0] + size, xyp[1]) - plane.own(xyp[0], xyp[1]));
        std::string kept = was.empty() ? "" : was + " ; ";
        char one[96];
        std::snprintf(one, sizeof one, "%d %.5f", tool, wide), kept += one;
        for (size_t i = 0; i + 2 < xyp.size(); i += 3) {
            const math::double2 p = plane.own(xyp[i], xyp[i + 1]);
            std::snprintf(one, sizeof one, " %.5f %.5f %.3f", p.x, p.y, xyp[i + 2]), kept += one;
        }
        const std::string outline = absent_drawing(kept, {}, layer, 0.0, 1000.0, 0.0, true);
        if ((outline.empty() && tool != 3) || !doc_say(d, layer, "drawing", kept.c_str()) || !doc_say(d, layer, "path", outline.c_str())) layer = 0;
    }
    if (!layer) d.act_ok = false;
    return doc_acted(d) ? layer : 0;
}
// Converts a flat shape into a path shape of the outline it shows, as Alight Motion's Convert to
// Outline does. The form is drawn again as it is drawn on screen: flat_path makes it, and ThorVG's
// own path operators in tvg_bend apply the round corners, bloat, zigzag and offset, as cut_at does.
// The points are then stored in the path's own units, 1 high from the middle, with y down as in
// SVG. Those operators are set to 0 afterwards, because they are now part of the path. The fill,
// the edge and everything else stay as they were. Returns false, with d.error set, if the shape
// cannot be converted.
static bool doc_to_path(Doc& d, int layer) {
    const std::string form = doc_word(d, layer, "shape");
    if (doc_word(d, layer, "kind") != "shape" || form.empty() || form == "path" || form == "null" || form == "solid") return d.error = "only a shape of a kind of its own is made a path (not a path, a null or a solid)", false;
    const bool line = form == "line", wave = form == "wave";
    // The shape's height and width in its own units, with the defaults that doc_match uses.
    const double high = line ? 0.04 : wave ? 0.3 : 1.0, wide = doc_number(d, layer, "wide", 0, line ? 25 : wave ? 10 : 1);
    const int h = 1024, w = std::max(2, (int)std::lround(1024.0 * wide));
    Canvas2D made;
    tvg::Shape* shape = tvg::Shape::gen();
    flat_path(&made, shape, form.c_str(), w, h, 0.f, (int)doc_number(d, layer, "points", 0, form == "star" ? 5 : form == "arc" ? 270 : form == "squircle" ? 4 : form == "cog" ? 12 : form == "spiral" ? 3 : wave ? 4 : 6),
              (float)doc_number(d, layer, "inner", 0, form == "cog" ? 0.2 : form == "arc" ? 0.3 : form == "spiral" ? 0.1 : form == "chamfer" ? 0.3 : 0.5), 0.f, 0.f);
    const auto num = [&](const char* name, double usual) { return (float)doc_number(d, layer, name, d.stage->now, usual); };
    tvg_bend(shape, made.plain.data(), (uint32_t)made.plain.size(), made.plainAt.data(), (uint32_t)made.plainAt.size(), line ? 0.f : std::clamp(num("round", 0), 0.f, 0.5f) * made.plainSide,
             100.f * std::clamp(num("bloat", 0), -1.f, 1.f), num("zigzag", 0) * (float)h, (int)std::clamp(num("zigzag_ridges", 5), 0.f, 100.f), num("zigzag_smooth", 0) > 0.5f, num("offset", 0) * (float)h, 0.f);
    const tvg::PathCommand* cmds; const tvg::Point* pts; uint32_t cmdsCnt = 0, ptsCnt = 0;
    shape->path(&cmds, &cmdsCnt, &pts, &ptsCnt);
    std::string path;
    char one[96];
    const auto at = [&](const tvg::Point& p) { std::snprintf(one, sizeof one, "%.5f %.5f", (p.x - 0.5 * w) / h * high, (p.y - 0.5 * h) / h * high); return std::string(one); };
    for (uint32_t c = 0, p = 0; c < cmdsCnt; ++c) switch (cmds[c]) {
        case tvg::PathCommand::MoveTo: path += (path.empty() ? "M" : " M") + at(pts[p++]); break;
        case tvg::PathCommand::LineTo: path += " L" + at(pts[p++]); break;
        case tvg::PathCommand::CubicTo: path += " C" + at(pts[p]) + " " + at(pts[p + 1]) + " " + at(pts[p + 2]), p += 3; break;
        case tvg::PathCommand::Close: path += " Z"; break;
    }
    tvg::Paint::rel(shape);
    if (path.empty()) return d.error = "it has no outline to make a path of", false;
    doc_act(d);
    bool ok = doc_say(d, layer, "shape", "path") && doc_say(d, layer, "path", path.c_str()) && doc_set(d, layer, "wide", wide * high);
    for (const char* name : {"round", "bloat", "zigzag", "offset"}) if (ok && doc_number(d, layer, name, 0, 0) != 0.0) ok = doc_set(d, layer, name, 0.0);
    if (!ok) d.act_ok = false;
    return doc_acted(d) && ok;
}
