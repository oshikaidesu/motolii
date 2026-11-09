// doc_paths.h: part of doc.h (a path shape's plane and points). Read only through doc.h.
// A path shape's own plane as the picture shows it: its middle and its two ways, seen; a point of the picture on it
// (own: its height 1, from its middle, down as SVG goes) and back (at).
struct DocPlane {
    math::double2 o, ex, ey;
    double det;
    bool seen;
    DocPlane(Doc& d, int thing, double now) {
        const math::mat4 at = doc_shown_at(d, thing, now);
        o = doc_seen(d, (at * math::double4{0, 0, 0, 1}).xyz), ex = doc_seen(d, (at * math::double4{1, 0, 0, 1}).xyz) - o, ey = doc_seen(d, (at * math::double4{0, 1, 0, 1}).xyz) - o;
        det = ex.x * ey.y - ex.y * ey.x, seen = std::fabs(det) > 1e-9;
    }
    math::double2 own(double px, double py) const { const double u = px - o.x, v = py - o.y; return {(u * ey.y - v * ey.x) / det, -(ex.x * v - ex.y * u) / det}; }
    math::double2 at(double fx, double fy) const { return o + ex * fx - ey * fy; }
};
int sk_svg_anchors(const char* data, std::vector<float>& xy);
int sk_svg_ends(const char* data, float& fx, float& fy, int& stretches);
bool sk_svg_move(const char* data, int nth, float dx, float dy, std::string& out);
int sk_svg_handles(const char* data, std::vector<float>& xy, std::vector<float>* of = nullptr);
bool sk_svg_move_handle(const char* data, int nth, float dx, float dy, std::string& out);
int sk_svg_edit(const char* data, float x, float y, float reach, std::string& out);
// A path shape's points as the picture shows them (x, y two a point, points of the picture from the top left; its handles not).
// handles: its curves' handles instead; of: and the point each is the handle of (of[2i], of[2i+1]).
static int doc_points(Doc& d, int thing, double now, double* xy, int room, bool handles = false, double* of = nullptr) {
    if (!doc_knows(d, thing) || doc_word(d, thing, "shape") != "path") return 0;
    std::vector<float> own, owner;
    const std::string path = doc_word(d, thing, "path");
    const int n = handles ? sk_svg_handles(path.c_str(), own, &owner) : sk_svg_anchors(path.c_str(), own);
    const DocPlane plane(d, thing, now);
    for (int i = 0; i < n && i < room; ++i) {
        const math::double2 p = plane.at(own[2 * i], own[2 * i + 1]);
        xy[2 * i] = p.x, xy[2 * i + 1] = p.y;
        if (of) { const math::double2 o = plane.at(owner[2 * i], owner[2 * i + 1]); of[2 * i] = o.x, of[2 * i + 1] = o.y; }
    }
    return n;
}
// A pen on the stage: a point put where the hand is (x, y: points of the picture from its top left), its handle drawn
// out by hx, hy (points; 0, 0: a corner), on a path shape's own path (its `path`, SVG's path data): a line to it, or a
// curve through it as Illustrator's pen makes one (SVG's S: the point before smooth, its handle turned through). On
// its first point again: closed; then on one of its points that point is taken away, on its outline a point is put
// there, elsewhere another is begun (Illustrator's pen adds and deletes so). thing 0: a new path shape, begun there, one step with its
// first point. Its number (0: not).
static int doc_pen(Doc& d, int thing, double x, double y, double hx, double hy) {
    const double now = d.stage->now;
    doc_act(d);
    if (thing && (!doc_knows(d, thing) || doc_word(d, thing, "shape") != "path")) thing = 0;   // (not a path: the pen begins one)
    if (const std::string was = thing ? doc_word(d, thing, "path") : ""; [&] { float fx, fy; int n; return sk_svg_ends(was.c_str(), fx, fy, n) == 4; }()) {   // (closed: on one of its points, it is taken away; on its outline, one is put there; else the pen begins another)
        const DocPlane plane(d, thing, now);
        const math::double2 p = plane.own(x, y);
        std::string edited;
        if (plane.seen && sk_svg_edit(was.c_str(), (float)p.x, (float)p.y, (float)(8.0 / std::max(1e-9, length(plane.ex))), edited)) {
            if (!doc_say(d, thing, "path", edited.c_str())) d.act_ok = false;
            return doc_acted(d) ? thing : 0;
        }
        thing = 0;
    }
    if (!thing) thing = doc_add(d, "shape", "path");
    std::string path = thing ? doc_word(d, thing, "path") : "";
    const DocPlane plane(d, thing, now);
    const math::double2 o = plane.o, ex = plane.ex, ey = plane.ey;
    if (thing && !plane.seen) d.trouble = "the shape is seen edge on", thing = 0;
    const auto own = [&](double px, double py) { return plane.own(px, py); };
    char said[200] = "";
    if (thing) {
        const math::double2 p = own(x, y), in = own(x - hx, y - hy);
        float first_x = 0.f, first_y = 0.f;
        int stretches = 0;
        const int last = sk_svg_ends(path.c_str(), first_x, first_y, stretches);   // (Skia's reading of it: skia_path_operations.cpp)
        const double fx = first_x, fy = first_y;
        const bool smooth = last == 3, handle = hx != 0.0 || hy != 0.0;
        const bool closes = stretches > 0 && last != 4 && length(o + ex * fx - ey * fy - math::double2{x, y}) < 8.0;   // (back on its first point, as the hand sees it)
        if (path.empty()) std::snprintf(said, sizeof said, "M%.4f %.4f", p.x, p.y);
        else if (closes) std::snprintf(said, sizeof said, smooth || handle ? " S%.4f %.4f %.4f %.4f Z" : " Z", handle ? own(o.x + ex.x * fx - ey.x * fy - hx, o.y + ex.y * fx - ey.y * fy - hy).x : fx,
                                       handle ? own(o.x + ex.x * fx - ey.x * fy - hx, o.y + ex.y * fx - ey.y * fy - hy).y : fy, fx, fy);
        else if (!smooth && !handle) std::snprintf(said, sizeof said, " L%.4f %.4f", p.x, p.y);
        else std::snprintf(said, sizeof said, " S%.4f %.4f %.4f %.4f", in.x, in.y, p.x, p.y);
        if (!doc_say(d, thing, "path", (path + said).c_str())) thing = 0;
    }
    if (!thing) d.act_ok = false;
    return doc_acted(d) ? thing : 0;
}
// A film's sound taken out to a thing of its own (Alight Motion's Extract Audio): a copy of it, hidden, that is heard
// (a hidden film's sound is: doc_match.h sounding), named so; the film itself no longer heard (volume 0). One step; the
// answer is the copy.
static int doc_extract_sound(Doc& d, int thing) {
    if (!doc_knows(d, thing) || doc_word(d, thing, "kind") != "film") return d.trouble = "only a film's sound is taken out", 0;
    doc_act(d);
    const int made = doc_duplicate(d, thing);
    const bool ok = made && doc_set(d, made, "visible", 0) && doc_say(d, made, "name", (doc_name(d, thing) + " (sound)").c_str()) && doc_set(d, thing, "volume", 0);
    return doc_acted(d) && ok ? made : 0;
}
// A path drawn by hand: the outline perfect-freehand makes round the hand's way (MIT, Steve Ruiz; its Dart port, Adil
// Hanney: the window's), in points of the picture, made a closed path of its own, each point to the next by a quadratic
// curve through their middle, as its example draws the outline. One step; the answer is the new shape.
static int doc_freehand(Doc& d, const char* points) {
    std::vector<double> xy;
    std::istringstream said(points);
    for (double v; said >> v;) xy.push_back(v);
    if (xy.size() < 6) return d.trouble = "a stroke of fewer than three points", 0;
    doc_act(d);
    int thing = doc_add(d, "shape", "path");
    const DocPlane plane(d, thing, d.stage->now);
    if (thing && !plane.seen) d.trouble = "its plane is seen edge on", thing = 0;
    if (thing) {
        std::string path;
        char one[160];
        const size_t n = xy.size() / 2;
        for (size_t i = 0; i < n; ++i) {
            const math::double2 p = plane.own(xy[2 * i], xy[2 * i + 1]), q = plane.own(xy[2 * ((i + 1) % n)], xy[2 * ((i + 1) % n) + 1]);
            if (!i) std::snprintf(one, sizeof one, "M%.4f %.4f", p.x, p.y), path += one;
            std::snprintf(one, sizeof one, " Q%.4f %.4f %.4f %.4f", p.x, p.y, (p.x + q.x) / 2, (p.y + q.y) / 2);
            path += one;
        }
        if (!doc_say(d, thing, "path", (path + " Z").c_str())) thing = 0;
    }
    if (!thing) d.act_ok = false;
    return doc_acted(d) ? thing : 0;
}
// A path the pen drew by hand, its wobbles let go: the hand's points (of the picture) made the fewest cubic Béziers
// that keep within `error` points of them, its sharp turns kept as corners, as Blender's Draw Curve tool makes a curve
// of a stroke (editcurve_paint.cc: curve_fit_cubic_to_points_refit, its corners past 70°; its error 8 of the screen's
// points, the window's tolerance here), by curve-fit-nd (Campbell Barton, BSD-3-Clause). Ended where it began: closed.
// Its anchors and handles then a pen path's own (M, C), moved as any. word: error, then x y each. The new shape.
static int doc_curve(Doc& d, const char* said) {
    std::istringstream in(said);
    double error = 0.0;
    in >> error;
    std::vector<double> xy;
    for (double x, y; in >> x >> y;)
        if (xy.empty() || std::hypot(x - xy[xy.size() - 2], y - xy.back()) > 0.01 * error) xy.push_back(x), xy.push_back(y);   // (a hand held still: its points one, as curve-fit-nd takes no stretch of no length)
    const unsigned n = (unsigned)(xy.size() / 2);
    if (!(error > 0.0) || n < 3) return d.trouble = "a stroke of fewer than three points", 0;
    const bool closed = std::hypot(xy[0] - xy[2 * n - 2], xy[1] - xy[2 * n - 1]) < 4 * error;   // (back where it began, as the hand sees it)
    double* cubic = nullptr;
    unsigned cubics = 0, *orig = nullptr, *corners = nullptr, cornersLen = 0;
    if (curve_fit_cubic_to_points_refit_db(xy.data(), closed ? n - 1 : n, 2, error, CURVE_FIT_CALC_HIGH_QUALITY | (closed ? CURVE_FIT_CALC_CYCLIC : 0), nullptr, 0, 70.0 * M_PI / 180.0,
                                           &cubic, &cubics, &orig, &corners, &cornersLen) || cubics < 2) {
        free(cubic), free(orig), free(corners);
        return d.trouble = "the stroke made no curve", 0;
    }
    doc_act(d);
    int thing = doc_add(d, "shape", "path");
    const DocPlane plane(d, thing, d.stage->now);
    if (thing && !plane.seen) d.trouble = "its plane is seen edge on", thing = 0;
    if (thing) {
        const auto at = [&](unsigned k, int part) { const double* c = cubic + (k * 3 + part) * 2; const math::double2 p = plane.own(c[0], c[1]); char one[64]; std::snprintf(one, sizeof one, "%.4f %.4f", p.x, p.y); return std::string(one); };   // (part: 0 its handle in, 1 the anchor, 2 its handle out)
        std::string path = "M" + at(0, 1);
        for (unsigned k = 1; k < cubics + (closed ? 1 : 0); ++k) path += " C" + at(k - 1, 2) + " " + at(k % cubics, 0) + " " + at(k % cubics, 1);
        if (closed) path += " Z";
        if (!doc_say(d, thing, "path", path.c_str())) thing = 0;
    }
    free(cubic), free(orig), free(corners);
    if (!thing) d.act_ok = false;
    return doc_acted(d) ? thing : 0;
}
// A brush's stroke as the window drew it (perfect-freehand's points, each with the pressure its radius comes from): a
// path shape whose stroke is kept as drawn (`drawing`: brush, how wide, each point and its pressure, in the plane's own
// units) and whose outline AbsentMotion makes of it (absent_drawing: Alight Motion's brush, a band of round pieces, its
// drawing effects on it as time goes: doc_moment). tool: AbsentMotion's (0 a pen, as wide all along; 1 a brush, as its
// pressure says; 2 a fill, the way gone round filled; 3 an eraser: a stroke of `into`'s own, taking from what it has
// drawn, as AbsentMotion's eraser clears within its drawing layer); size: how wide, in points of the picture; then x y
// pressure each. The shape it made or took from.
static int doc_brush(Doc& d, const char* said, int into = 0) {
    std::istringstream in(said);
    int tool = 1;
    double size = 0.0;
    in >> tool >> size;
    tool = std::clamp(tool, 0, 3);
    std::vector<double> xyp;
    for (double v; in >> v;) xyp.push_back(v);
    if (!(size > 0.0) || xyp.size() < 6) return d.trouble = "a stroke of fewer than two points", 0;
    const std::string was = tool == 3 ? doc_word(d, into, "drawing") : std::string();
    if (tool == 3 && was.empty()) return d.trouble = "an eraser takes from a drawing: pick one", 0;
    doc_act(d);
    int thing = tool == 3 ? into : doc_add(d, "shape", "path");
    const DocPlane plane(d, thing, d.stage->now);
    if (thing && !plane.seen) d.trouble = "its plane is seen edge on", thing = 0;
    if (thing) {
        const double wide = length(plane.own(xyp[0] + size, xyp[1]) - plane.own(xyp[0], xyp[1]));
        std::string kept = was.empty() ? "" : was + " ; ";
        char one[96];
        std::snprintf(one, sizeof one, "%d %.5f", tool, wide), kept += one;
        for (size_t i = 0; i + 2 < xyp.size(); i += 3) {
            const math::double2 p = plane.own(xyp[i], xyp[i + 1]);
            std::snprintf(one, sizeof one, " %.5f %.5f %.3f", p.x, p.y, xyp[i + 2]), kept += one;
        }
        const std::string outline = absent_drawing(kept, {}, thing, 0.0, 1000.0, 0.0, true);
        if ((outline.empty() && tool != 3) || !doc_say(d, thing, "drawing", kept.c_str()) || !doc_say(d, thing, "path", outline.c_str())) thing = 0;
    }
    if (!thing) d.act_ok = false;
    return doc_acted(d) ? thing : 0;
}
// A flat shape made a path shape of the outline it shows (Alight Motion's Convert to Outline): its form drawn again as
// it is drawn (flat_path, its corners rounded, puckered, zigzagged and offset by ThorVG's own path operators: tvg_bend,
// as cut_at bends it), its points then its own, in its height from its middle (SVG's way down); those operators then
// none, made part of its path. Its fill, edge and all else as they were.
static bool doc_to_path(Doc& d, int thing) {
    const std::string form = doc_word(d, thing, "shape");
    if (doc_word(d, thing, "kind") != "shape" || form.empty() || form == "path" || form == "null" || form == "solid") return d.trouble = "only a shape of a kind of its own is made a path (not a path, a null or a solid)", false;
    const bool line = form == "line", wave = form == "wave";
    const double high = line ? 0.04 : wave ? 0.3 : 1.0, wide = doc_number(d, thing, "wide", 0, line ? 25 : wave ? 10 : 1);   // (as doc_match makes it)
    const int h = 1024, w = std::max(2, (int)std::lround(1024.0 * wide));
    Drawn made;
    tvg::Shape* shape = tvg::Shape::gen();
    flat_path(&made, shape, form.c_str(), w, h, 0.f, (int)doc_number(d, thing, "points", 0, form == "star" ? 5 : form == "arc" ? 270 : form == "squircle" ? 4 : form == "cog" ? 12 : form == "spiral" ? 3 : wave ? 4 : 6),
              (float)doc_number(d, thing, "inner", 0, form == "cog" ? 0.2 : form == "arc" ? 0.3 : form == "spiral" ? 0.1 : form == "chamfer" ? 0.3 : 0.5), 0.f, 0.f);
    const auto num = [&](const char* name, double usual) { return (float)doc_number(d, thing, name, d.stage->now, usual); };
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
    if (path.empty()) return d.trouble = "it has no outline to make a path of", false;
    doc_act(d);
    bool ok = doc_say(d, thing, "shape", "path") && doc_say(d, thing, "path", path.c_str()) && doc_set(d, thing, "wide", wide * high);
    for (const char* name : {"round", "bloat", "zigzag", "offset"}) if (ok && doc_number(d, thing, name, 0, 0) != 0.0) ok = doc_set(d, thing, name, 0.0);
    if (!ok) d.act_ok = false;
    return doc_acted(d) && ok;
}
