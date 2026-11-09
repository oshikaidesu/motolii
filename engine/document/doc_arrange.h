// doc_arrange.h: part of doc.h (a thing moved, lined up and fitted on the picture; a value as it comes). Read only through doc.h.
// What of a thing is seen at a moment: the upright box of its outline on the picture (its own points where they are at
// hand, else its box's corners), left, top, right, bottom in points of the picture. false: it is not shown.
static bool doc_seen_box(Doc& d, int thing, double now, double* box) {
    double around[128], cover[4];
    if (!d.shown[thing].in) return false;
    const int n = doc_outline(d, thing, now, around);
    if (n > 2) {
        box[0] = box[2] = around[0], box[1] = box[3] = around[1];
        for (int i = 1; i < n; ++i) box[0] = std::min(box[0], around[2 * i]), box[2] = std::max(box[2], around[2 * i]), box[1] = std::min(box[1], around[2 * i + 1]), box[3] = std::max(box[3], around[2 * i + 1]);
        return true;
    }
    if (!doc_covers(d, thing, now, cover)) return false;
    box[0] = cover[0], box[1] = cover[1], box[2] = cover[0] + cover[2], box[3] = cover[1] + cover[3];
    return true;
}
// A value changed by so much where it is said, every key of it too (moved or sized, its own way of moving kept): its
// value as it comes, if none is said, changed so and said.
static bool doc_value_by(Doc& d, int thing, const char* name, double add, double times) {
    int rows = 0;
    doc_rows(d, sqlite3_mprintf("select count(*) from fact where thing = %d and name = %Q", thing, name), [&](sqlite3_stmt* q) { rows = sqlite3_column_int(q, 0); });
    if (!rows) return doc_set(d, thing, name, doc_usual(d, name) * times + add);
    return doc_change(d, sqlite3_mprintf("update fact set value = value * %!.17g + %!.17g where thing = %d and name = %Q", times, add, thing, name));
}
// A thing moved by so many points of the picture (as a hand carries it): its x and y in the plane it hangs in.
static bool doc_move_seen(Doc& d, int thing, double dx, double dy, double now) {
    const math::mat4 above = doc_above(d, thing, now);
    const math::double2 o = doc_seen(d, (above * math::double4{0, 0, 0, 1}).xyz), ex = doc_seen(d, (above * math::double4{1, 0, 0, 1}).xyz) - o, ey = doc_seen(d, (above * math::double4{0, 1, 0, 1}).xyz) - o;
    const double det = ex.x * ey.y - ex.y * ey.x;
    if (std::fabs(det) < 1e-12) return d.trouble = "it is seen edge on", false;
    return doc_value_by(d, thing, "x", (dx * ey.y - dy * ey.x) / det, 1) && doc_value_by(d, thing, "y", (ex.x * dy - ex.y * dx) / det, 1);
}
// Things lined up on the picture as Keynote and Figma line them up (Arrange > Align): one against the picture, more
// against the box round them all; left, centre, right, top, middle, bottom; across and down spread three or more so
// the gaps between them are even. One step.
static bool doc_align(Doc& d, const std::vector<int>& things, const std::string& how) {
    const double now = d.stage->now;
    std::vector<std::array<double, 4>> boxes;
    for (const int t : things) {
        std::array<double, 4> b{};
        if (!doc_seen_box(d, t, now, b.data())) return d.trouble = "a thing not seen now", false;
        boxes.push_back(b);
    }
    if (boxes.empty()) return d.trouble = "nothing to line up", false;
    std::array<double, 4> all = things.size() == 1 ? std::array<double, 4>{0, 0, (double)d.stage->w, (double)d.stage->h} : boxes[0];
    for (const auto& b : boxes) if (things.size() > 1) all = {std::min(all[0], b[0]), std::min(all[1], b[1]), std::max(all[2], b[2]), std::max(all[3], b[3])};
    std::vector<std::pair<double, double>> by(things.size(), {0.0, 0.0});
    if (how == "across" || how == "down") {   // (in the order they lie along the way: the first and last stay, the gaps between made even)
        const int a = how == "across" ? 0 : 1;
        if (things.size() < 3) return d.trouble = "three or more are spread", false;
        std::vector<size_t> order(things.size());
        for (size_t i = 0; i < order.size(); ++i) order[i] = i;
        std::sort(order.begin(), order.end(), [&](size_t p, size_t q) { return boxes[p][a] + boxes[p][a + 2] < boxes[q][a] + boxes[q][a + 2]; });
        double sizes = 0;
        for (const auto& b : boxes) sizes += b[a + 2] - b[a];
        const double gap = (boxes[order.back()][a + 2] - boxes[order.front()][a] - sizes) / (double)(things.size() - 1);
        double at = boxes[order.front()][a];
        for (const size_t i : order) {
            (a ? by[i].second : by[i].first) = at - boxes[i][a];
            at += boxes[i][a + 2] - boxes[i][a] + gap;
        }
    } else
        for (size_t i = 0; i < things.size(); ++i) {
            const auto& b = boxes[i];
            if (how == "left") by[i].first = all[0] - b[0];
            else if (how == "centre") by[i].first = (all[0] + all[2] - b[0] - b[2]) / 2;
            else if (how == "right") by[i].first = all[2] - b[2];
            else if (how == "top") by[i].second = all[1] - b[1];
            else if (how == "middle") by[i].second = (all[1] + all[3] - b[1] - b[3]) / 2;
            else if (how == "bottom") by[i].second = all[3] - b[3];
            else return d.trouble = "lined up left, centre, right, top, middle, bottom, across or down", false;
        }
    doc_act(d);
    bool ok = true;
    for (size_t i = 0; i < things.size() && ok; ++i) ok = doc_move_seen(d, things[i], by[i].first, by[i].second, now);
    if (!ok) d.act_ok = false;
    return doc_acted(d) && ok;
}
// A thing made to the picture (Alight Motion's Fit, Fill and Stretch): as large as it can be inside it, or covering it,
// or stretched to it; then its middle at the picture's. One step.
static bool doc_fit(Doc& d, int thing, const std::string& how) {
    const double now = d.stage->now;
    double b[4];
    if (d.act && d.act_unmatched) {   // (within a larger act, what it has made so far shown first, as its end does (doc_acted): a picture placed and fitted in one step, golf ㊱)
        d.act_unmatched = false;
        doc_forget(d);
        if (d.act_ok && !doc_match(d)) d.act_ok = false;
    }
    const bool eye = d.eyeAsked;   // (the film's picture is what it fills, by whichever eye the window looks: After Effects' Fit to Comp; the camera taken as picture_update takes it)
    if (eye) d.eyeAsked = false, doc_moment(d, now);
    const auto back = [&](bool ok) { if (eye) d.eyeAsked = true, doc_moment(d, now); return ok; };
    if (!doc_seen_box(d, thing, now, b) || b[2] - b[0] < 1e-6 || b[3] - b[1] < 1e-6) return d.trouble = "it is not seen now", back(false);
    const double wx = (double)d.stage->w / (b[2] - b[0]), wy = (double)d.stage->h / (b[3] - b[1]);
    if (how != "fit" && how != "fill" && how != "stretch") return d.trouble = "made to fit, fill or stretch", back(false);
    doc_act(d);
    bool ok = how == "stretch" ? doc_value_by(d, thing, "scale_x", 0, wx) && doc_value_by(d, thing, "scale_y", 0, wy) : doc_value_by(d, thing, "size", 0, how == "fit" ? std::min(wx, wy) : std::max(wx, wy));
    if (ok) {
        doc_moment(d, now);   // (seen as it is now, to put its middle at the picture's)
        ok = doc_seen_box(d, thing, now, b) && doc_move_seen(d, thing, d.stage->w / 2.0 - (b[0] + b[2]) / 2, d.stage->h / 2.0 - (b[1] + b[3]) / 2, now);
    }
    if (!ok) d.act_ok = false;
    return back(doc_acted(d) && ok);
}
// The upright box of the picture a thing covers at a moment, however it is turned or leans: left, top, wide, high.
static bool doc_covers(Doc& d, int thing, double now, double* box) {
    float2 half{0.f};
    float deep = 0.f;
    if (!doc_half(d, thing, &half, &deep)) return false;
    const math::mat4 place = doc_shown_at(d, thing, now);
    math::double2 low{1e12}, high{-1e12};
    for (int corner = 0; corner < 8; ++corner) {
        const math::double2 at = doc_seen(d, (place * math::double4{corner & 1 ? half.x : -half.x, corner & 2 ? half.y : -half.y, corner & 4 ? deep : -deep, 1.0}).xyz);
        low = min(low, at), high = max(high, at);
    }
    box[0] = low.x, box[1] = low.y, box[2] = high.x - low.x, box[3] = high.y - low.y;
    return true;
}

// A thing's outline on the picture at a moment: its own points as the stage's eye sees them (a shape the kit made:
// a ball, a gem, a ring), or else the corners of its box (a file's, a flat thing's), and the polygon round them all
// (a convex hull, Andrew's way): a ball's round edge, a cube's own outline, a flat thing's tilted four corners; nothing
// of it lies outside. Points of the picture from the top left, in order round it; how many (0: not shown).
static int doc_outline(Doc& d, int thing, double now, double* xy) {
    float2 half{0.f};
    float deep = 0.f;
    if (!doc_half(d, thing, &half, &deep) || !d.shown[thing].in) return 0;
    const math::mat4 place = doc_shown_at(d, thing, now);
    std::vector<math::double2> p;
    if (const Mesh* shape = d.shown[thing].shape; shape && !shape->pos.empty()) {   // (a shape whose points are at hand, the kit's: its own points as seen, every so many)
        const size_t step = std::max<size_t>(1, shape->pos.size() / 600);
        for (size_t i = 0; i < shape->pos.size(); i += step) p.push_back(doc_seen(d, (place * math::double4{math::double3(shape->pos[i]), 1.0}).xyz));
    } else
        for (int corner = 0; corner < (deep > 0.f ? 8 : 4); ++corner)
            p.push_back(doc_seen(d, (place * math::double4{corner & 1 ? half.x : -half.x, corner & 2 ? half.y : -half.y, corner & 4 ? deep : -deep, 1.0}).xyz));
    std::sort(p.begin(), p.end(), [](const math::double2& a, const math::double2& b) { return a.x < b.x || (a.x == b.x && a.y < b.y); });
    const auto turn = [](const math::double2& o, const math::double2& a, const math::double2& b) { return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x); };
    std::vector<math::double2> hull(2 * p.size());
    size_t k = 0;
    for (size_t i = 0; i < p.size(); ++i) { while (k >= 2 && turn(hull[k - 2], hull[k - 1], p[i]) <= 0) --k; hull[k++] = p[i]; }
    for (size_t i = p.size() - 1, t = k + 1; i > 0; --i) { while (k >= t && turn(hull[k - 2], hull[k - 1], p[i - 1]) <= 0) --k; hull[k++] = p[i - 1]; }
    const size_t all = k > 0 ? k - 1 : 0;
    const int n = (int)std::min<size_t>(all, 64);   // (64 at most, evenly among them: round enough)
    for (int i = 0; i < n; ++i) { const size_t j = (size_t)i * all / (size_t)n; xy[2 * i] = hull[j].x, xy[2 * i + 1] = hull[j].y; }
    return n;
}

static double doc_usual(Doc& d, const char* name) {
    if (!strncmp(name, "js_", 3))   // (a knob of a script: as its head says it comes)
        for (const auto& [file, sc] : doc_scripts(d))
            for (size_t i = 0; i < sc.names.size(); ++i)
                if (sc.names[i] == name) return sc.knobs[i].usual;
    return doc_among("parent_rotate parent_size scale_x scale_y scale_z size speed volume opacity wide tall visible distance zoom copies blur_levelletter_spacing line_spacing contrast saturation vibrance environment gradient_scale wave_speed slope power strength spread", name) ? 1.0 : !strcmp(name, "duration") ? -1.0
         : !strcmp(name, "radius") ? 0.5 : !strcmp(name, "gap") ? 0.2   // (a relation as it comes: what it works by when nothing is said)
         : !strcmp(name, "metallic") || doc_among("bevel_metallic side_metallic back_metallic", name) ? 0.08 : !strcmp(name, "roughness") || doc_among("bevel_roughness side_roughness back_roughness", name) ? 0.6 : !strcmp(name, "reflectance") ? 0.5 : !strcmp(name, "thickness") ? 0.5 : !strcmp(name, "sun_size") ? 1.09 : !strcmp(name, "sun_halo") ? 10.0   // (a solid's surface as it comes)
         : !strcmp(name, "intensity") ? 1.0 : !strcmp(name, "falloff") ? 10.0 : !strcmp(name, "cone") ? 30.0   // (a light as it comes)
         : !strcmp(name, "fog_near") ? 2.0   // (where fog begins, as it came before it could be said)
         : !strcmp(name, "bounce") ? 0.3 : !strcmp(name, "friction") ? 0.5 : !strcmp(name, "gravity") ? 9.81   // (what falls and strikes, as it comes)
         : !strcmp(name, "ior") ? 1.5 : !strcmp(name, "dispersion") ? 0.1 : !strcmp(name, "swim") ? 0.5 : !strcmp(name, "dark") ? 4.0 : !strcmp(name, "vivid") ? 1.3 : 0.0;   // (the kit's glass as it comes)
}
// What it is when nothing is said of it on this thing: a flat thing has no thickness (doc_fx_list), a solid is as deep as it is.
static double doc_usual_on(Doc& d, int thing, const char* name) { return !strcmp(name, "scale_z") && doc_word(d, thing, "kind") != "solid" ? 0.0 : !strcmp(name, "points") ? (doc_word(d, thing, "shape") == "star" ? 5.0 : 6.0) : !strcmp(name, "inner") ? 0.5 : doc_usual(d, name); }
static bool doc_value(Doc& d, int thing, const char* name, double at, double* is) { return doc_knows(d, thing, name) && (*is = doc_number(d, thing, name, at, doc_usual_on(d, thing, name)), true); }
