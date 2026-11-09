// hold.h: part of doc.h (a thing held by a hand, carried and let go). Read only through doc.h.
// A thing held by a hand, carried, and let go: the one form of everything a hand drags (a thing on the stage, its bar
// on the timeline, a number). What is carried shows at once and is not the document's until it is let go, and then
// it is one step; let go without keeping, nothing happened. The reckoning is here, once: a shell says where the hand
// is, never what the document is to hold.
//   by "place"  the thing carried on the stage: a, b = how far the hand has gone since it took hold, in points of the
//               picture (to the right, down); the thing stays under the hand at its own depth
//   by "bar"    its bar slid on the timeline: a = how many seconds later (when it comes on)
//   by "head", "tail"  its bar cut at an end: a = how many seconds later that end is (a film cut at its head goes on
//               showing at each moment what it showed there)
//   by "point"  a path shape's point or handle nearest where the hand took hold ("grip" first), moved as far as the
//               hand has gone (a, b: points of the picture); a point's handles with it
//   by "scale"  sized about its pivot as far as the hand has gone from where it took hold ("grip" first); "side" the
//               same, the side or corner across from the hand staying where it is; "even_scale", "even_side" the
//               same, its width and height grown alike (held by a corner, as far as the hand has gone along the way
//               from that corner to the one across or the pivot; by a side's middle, the other way as much)
//   by "turn"   turned round its pivot as far as the hand has gone round it ("grip" first); "even_turn" the same, to
//               the nearest 15°
//   by a value's name  that number carried: a = what it is now
static bool doc_hold(Doc& d, int thing) {
    if (!doc_knows(d, thing)) return false;
    if (d.writing) return d.trouble = "the document is being written as a film: nothing is held until that is done", false;
    if (d.held.thing != thing) d.held = Doc::Held{}, d.held.thing = thing;   // (held already: the same hold goes on)
    return true;
}
// How far its own clock has gone when `by` of its beginning is cut away: a film's at its speed, a thing with a script's as
// the stage's (After Effects' Split Layer and in-point leave a layer's keys where they are, so what it was doing goes on:
// golf_noise.md (115)); 0: it has no clock of its own.
static double doc_own_clock(Doc& d, int t, double by) {
    if (doc_word(d, t, "kind") == "film") return by * std::fabs(doc_number(d, t, "speed", 0, 1));
    return doc_word(d, t, "script").empty() ? 0.0 : by;
}
static bool doc_carry(Doc& d, const char* by, double a, double b) {
    Doc::Held& h = d.held;
    // (its width to its height kept, or turned by 15° at a time: Figma's Shift ("temporarily locks" the aspect ratio,
    //  "snap rotation values to increments of 15"); a corner by the hand's travel along the diagonal, so a corner pulled
    //  through the one across turns it over)
    const bool even = !strncmp(by, "even_", 5);
    if (even) by += 5;
    const auto alike = [](double& k0, double& k1, bool& on0, bool& on1, double g0, double g1, double n0, double n1) {
        if (on0 && on1) k0 = k1 = (n0 * g0 + n1 * g1) / (g0 * g0 + g1 * g1);
        else if (on0) k1 = k0;   // (a side's middle: the other way as much)
        else if (on1) k0 = k1;
        on0 = on1 = on0 || on1;
    };
    if (h.thing < 0) return d.trouble = "nothing is held", false;
    const double now = d.stage->now;
    const auto was = [&](const char* name) {   // (as it was when the hand first carried it)
        auto found = h.from.find(name);
        if (found == h.from.end()) found = h.from.emplace(name, doc_number(d, h.thing, name, now, doc_usual(d, name))).first;
        return found->second;
    };
    const auto tries = [&](const char* name, double is) { return doc_knows(d, h.thing, name, &is) && (h.tried[name] = is, true); };
    bool ok = true;
    if (!strcmp(by, "place")) {
        // (by the working eye the hand's travel is that eye's, the way After Effects' working views move a 3D layer)
        const math::mat3 ways = d.working ? d.stage->camera->getModelMatrix().upperLeft() : math::mat3{};
        if (!h.from.count(" point")) {   // (remembered with the hold: one unit of the stage in points of the picture, where the thing stood)
            const math::double3 at = (doc_above(d, h.thing, now) * math::double4{doc_number(d, h.thing, "x", now, 0), doc_number(d, h.thing, "y", now, 0), doc_number(d, h.thing, "z", now, 0), 1.0}).xyz;
            h.from[" point"] = d.working ? doc_seen(d, at + ways[0]).x - doc_seen(d, at).x : doc_point(d, h.thing, now);
        }
        const double x = was("x"), y = was("y"), z = d.working ? was("z") : 0.0, point = h.from[" point"];
        // (the hand's travel is the stage's; a thing that goes with another is moved in that one's own turned and sized way)
        const math::double3 by = inverse(doc_above(d, h.thing, now).upperLeft()) * (ways * math::double3{a / point, -b / point, 0.0});
        ok = tries("x", x + by.x) && tries("y", y + by.y) && (!d.working || tries("z", z + by.z));
    } else if (!strcmp(by, "grip")) {   // (where on the picture the hand took hold, points from the top left: what scale, turn and pivot reckon from)
        double frame[8];
        if (!doc_frame(d, h.thing, now, frame)) return d.trouble = "it has no frame on the picture", false;
        h.from[" grip x"] = a, h.from[" grip y"] = b, h.from[" pivot x"] = frame[5], h.from[" pivot y"] = frame[6], h.from[" turned"] = frame[4];
        h.from[" middle x"] = frame[0], h.from[" middle y"] = frame[1], h.from[" wide"] = frame[2], h.from[" high"] = frame[3];
        h.from[" point"] = doc_point(d, h.thing, now);
        was("scale_x"), was("scale_y"), was("rotate"), was("anchor_x"), was("anchor_y"), was("x"), was("y");
    } else if (!strcmp(by, "scale") || !strcmp(by, "turn") || !strcmp(by, "pivot")) {   // (a, b: how far the hand has gone since it took hold)
        if (!h.from.count(" grip x")) return d.trouble = "the hand has not said where it took hold (grip)", false;
        const double px = h.from[" pivot x"], py = h.from[" pivot y"], gx = h.from[" grip x"] - px, gy = h.from[" grip y"] - py, hx = gx + a, hy = gy + b;
        const double turned = h.from[" turned"] * (double)TAU / 360.0, c = std::cos(-turned), s = std::sin(-turned);   // (into the thing's own upright: as the picture counts, clockwise)
        if (!strcmp(by, "scale")) {   // (each way as far from the point it turns about as the hand now is, against where it took hold)
            const double g0 = c * gx - s * gy, g1 = s * gx + c * gy, n0 = c * hx - s * hy, n1 = s * hx + c * hy;
            bool on0 = std::fabs(g0) >= 2.0, on1 = std::fabs(g1) >= 2.0;
            double k0 = on0 ? n0 / g0 : 1.0, k1 = on1 ? n1 / g1 : 1.0;
            if (even) alike(k0, k1, on0, on1, g0, g1, n0, n1);
            ok = (!on0 || tries("scale_x", was("scale_x") * k0)) && (!on1 || tries("scale_y", was("scale_y") * k1));
        } else if (!strcmp(by, "turn")) {   // (round the point it turns about as far as the hand has gone round it; the picture counts clockwise, the stage the other way)
            const double by = std::atan2(hy, hx) - std::atan2(gy, gx), to = was("rotate") - by * 360.0 / (double)TAU;
            ok = tries("rotate", even ? std::round(to / 15.0) * 15.0 : to);
        } else {   // (the point it turns about moved under the hand, the thing staying where it is seen: After Effects' Pan Behind)
            float2 half{0.5f};
            doc_half(d, h.thing, &half);
            const double point = h.from[" point"], size = was("size") == 0.0 ? 1.0 : doc_number(d, h.thing, "size", now, 1);
            const double l0 = (c * a - s * b) / point, l1 = -(s * a + c * b) / point;   // (the hand's travel in the thing's own units, y up)
            const double sx = was("scale_x"), sy = was("scale_y");
            ok = tries("anchor_x", was("anchor_x") + l0 / (size * (sx == 0.0 ? 1.0 : sx) * std::max(half.x, 1e-6f))) &&
                 tries("anchor_y", was("anchor_y") + l1 / (size * (sy == 0.0 ? 1.0 : sy) * std::max(half.y, 1e-6f)));
            const math::double3 move = inverse(doc_above(d, h.thing, now).upperLeft()) * math::double3{a / point, -b / point, 0.0};
            ok = ok && tries("x", was("x") + move.x) && tries("y", was("y") + move.y);
        }
    } else if (!strcmp(by, "side")) {   // (sized, the side or corner across from where the hand took hold staying where it is: Figma's and Keynote's handles; "scale" sizes it about its pivot, as with Alt)
        if (!h.from.count(" grip x")) return d.trouble = "the hand has not said where it took hold (grip)", false;
        const double turned = h.from[" turned"] * (double)TAU / 360.0, c = std::cos(-turned), s = std::sin(-turned);
        const auto own = [&](double x, double y) { return math::double2{c * x - s * y, s * x + c * y}; };   // (the picture's way into the thing's own upright, from its middle)
        const double mx = h.from[" middle x"], my = h.from[" middle y"], w = h.from[" wide"], hi = h.from[" high"];
        const math::double2 grip = own(h.from[" grip x"] - mx, h.from[" grip y"] - my);
        const math::double2 o{std::fabs(grip.x) > w / 4.0 ? -std::copysign(w / 2.0, grip.x) : 0.0, std::fabs(grip.y) > hi / 4.0 ? -std::copysign(hi / 2.0, grip.y) : 0.0};   // (the side across, or the corner; an edge's middle: that way unsized)
        const math::double2 pivot = own(h.from[" pivot x"] - mx, h.from[" pivot y"] - my), g = grip - o, n = own(h.from[" grip x"] + a - mx, h.from[" grip y"] + b - my) - o;
        bool on0 = o.x != 0.0 && std::fabs(g.x) >= 2.0, on1 = o.y != 0.0 && std::fabs(g.y) >= 2.0;   // (an edge's middle: that way unsized)
        double k0 = on0 ? n.x / g.x : 1.0, k1 = on1 ? n.y / g.y : 1.0;
        if (even) alike(k0, k1, on0, on1, g.x, g.y, n.x, n.y);   // (a side's middle with it: the other way about the middle)
        ok = (!on0 || tries("scale_x", was("scale_x") * k0)) && (!on1 || tries("scale_y", was("scale_y") * k1));
        const math::double2 back{(1.0 - k0) * (o.x - pivot.x), (1.0 - k1) * (o.y - pivot.y)};   // (sized about its pivot, the side across moved: so much back, in its own upright)
        const double dx = c * back.x + s * back.y, dy = -s * back.x + c * back.y, point = h.from[" point"];
        const math::double3 move = inverse(doc_above(d, h.thing, now).upperLeft()) * math::double3{dx / point, -dy / point, 0.0};
        ok = ok && tries("x", was("x") + move.x) && tries("y", was("y") + move.y);
    } else if (!strcmp(by, "point")) {   // (a path shape's point nearest where the hand took hold (grip), moved as far as the hand has gone: a, b)
        if (!h.from.count(" grip x")) return d.trouble = "the hand has not said where it took hold (grip)", false;
        if (!h.said.count(" path")) {   // (which point, and the path as it was: once, with the hold)
            int nearest = -1;
            double near = 12.0;
            for (const bool handles : {false, true}) {   // (its points first: a handle lying on its point is the point)
                std::vector<double> xy(2048);
                const int n = std::min(1024, doc_points(d, h.thing, now, xy.data(), 1024, handles));
                for (int i = 0; i < n; ++i)
                    if (const double far = std::hypot(xy[2 * i] - h.from[" grip x"], xy[2 * i + 1] - h.from[" grip y"]); far < near - 0.5) near = far, nearest = i, h.from[" handle"] = handles;
            }
            if (nearest < 0) return d.trouble = "no point of its path where the hand took hold", false;
            h.from[" point"] = nearest, h.said[" path"] = doc_word(d, h.thing, "path");
        }
        const DocPlane plane(d, h.thing, now);
        const math::double2 from = plane.own(h.from[" grip x"], h.from[" grip y"]), to = plane.own(h.from[" grip x"] + a, h.from[" grip y"] + b);
        std::string moved;
        if (!plane.seen || !(h.from[" handle"] != 0.0 ? sk_svg_move_handle : sk_svg_move)(h.said[" path"].c_str(), (int)h.from[" point"], (float)(to.x - from.x), (float)(to.y - from.y), moved)) return d.trouble = "its point could not be moved", false;
        h.said["path"] = moved;
        ok = doc_match(d);   // (made again with it now, as a value it is made by)
    } else if (!strcmp(by, "bar")) {
        h.from[" bar"] = 1.0;   // (the whole layer moved in time: its keys go with it when it is let go)
        ok = tries("start", std::max(0.0, was("start") + a));
    } else if (!strcmp(by, "head")) {
        const double start = was("start"), lasts = was("duration"), to = std::clamp(start + a, 0.0, lasts > 0.0 ? start + lasts - 1e-3 : 1e6);
        ok = tries("start", to) && (lasts <= 0.0 || tries("duration", start + lasts - to));
        if (const double on = doc_own_clock(d, h.thing, to - start); ok && on != 0.0) ok = tries("begin", std::max(0.0, was("begin") + on));
    } else if (!strcmp(by, "tail")) {
        const double start = was("start"), lasts = was("duration");
        ok = tries("duration", std::max(1e-3, (lasts > 0.0 ? lasts : doc_seconds(d) - start) + a));
    } else {
        was(by);   // (as it was: whether it comes on or goes off, carried)
        ok = tries(by, doc_macro_own(d, h.thing, by, now, a));   // (the value the hand sees: one a macro turns made its own, expressions.h)
        if (ok && strstr(doc_making, ("'" + std::string(by) + "'").c_str())) ok = doc_match(d);   // (a value it is made by: made again with it now, not when let go)
        else if (ok && strstr(doc_fxing, ("'" + std::string(by) + "'").c_str())) ok = doc_match(d);   // (an effect's: made again only if it now reaches past its room)
    }
    doc_moment(d, now);
    return ok;
}
// An effect file carried on the held thing: drawn last of its effects, as doc_fx_file puts one on at the end, not the
// document's and not on its cards, gone as it is let go: Final Cut Pro's effects browser shows the effect skimmed on the
// clip selected in the viewer, DaVinci Resolve's Live Preview the one the pointer is over. A hand that puts it on lets
// go first and puts it on as a press does (doc_fx_file: a transition's keys and all).
static bool doc_carry_effect(Doc& d, const char* file) {
    Doc::Held& h = d.held;
    if (h.thing < 0) return d.trouble = "nothing is held", false;
    if (doc_word(d, h.thing, "kind") == "camera" && std::filesystem::path(file).extension() != ".am") return d.trouble = "a camera takes motions only (it has no picture of its own)", false;   // (doc_fx_say's rule)
    h.said[" effect"] = file;   // (' ': the hold's own, never said when it is let go)
    return doc_match(d), doc_moment(d, d.stage->now), true;
}
