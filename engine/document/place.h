// place.h: part of doc.h (where a layer and its copies lie, and what joins them). Read only through doc.h.
// How much deeper it is drawn: a flat layer's thickness keyed through 0 has none, not a place that cannot be turned back.
static double doc_scale_z(Doc& d, int layer, double now) {
    const double z = doc_literal(d, layer, "scale_z", now, 1);
    return z == 0 && doc_word(d, layer, "kind") != "solid" ? 1e-3 : z;
}
// Where a recipe, or a MIDI file's notes, lay copy `copy` of `n` of a layer (by 0: neither; 1: a MIDI file's note, 2: a recipe's each()): its place, turn and size.
// Asked first, so that what a falloff weighs is where the copy lies.
struct DocLaid { ScriptCopy c; int by = 0; };
// What lays a layer's copies, and AbsentMotion's motions on it: the same for each copy, so while a moment is told
// (d.telling: the document does not change meanwhile) asked once for the layer, as its talls are; else asked as it is.
static std::vector<DocScript*> doc_placing_scs(Doc& d, int layer) {
    const auto ask = [&] { return doc_literal_word(d, layer, "shape") != "sketch" ? doc_expressions_on(d, layer) : std::vector<DocScript*>{}; };
    if (!d.evaluating) return ask();
    Doc::Placing& kept = d.placing[layer];
    if (!kept.laid) kept.laid = true, kept.scs = ask(), kept.from = kept.scs.empty() ? "" : doc_expressions_said(d, layer);
    return kept.scs;
}
static std::vector<AbsentEffect> doc_placing_absent(Doc& d, int layer, double said) {
    if (!d.evaluating) return doc_absent_on(d, layer, said);
    Doc::Placing& kept = d.placing[layer];
    if (kept.absentAt != said) kept.absentAt = said, kept.absent = doc_absent_on(d, layer, said);
    return kept.absent;
}
static DocLaid doc_laid(Doc& d, int layer, int copy, int n, double said) {
    DocLaid out;
    if (const std::string notes = doc_literal_word(d, layer, "script"); std::filesystem::path(notes).extension() == ".mid") {   // (a MIDI file's notes, copies: midi_notes.h)
        Doc::Scripted& kept = d.scripted[layer];
        if (kept.at != said || (int)kept.copies.size() != n)   // (its speed: the file's beats faster or slower, as a film's)
        {   // (its highest row where the roll of the same file at the same speed has it, put at the same place: midi_roll.cpp, its top row the file's highest note)
            const double speed = doc_literal(d, layer, "speed", 0, 1);
            std::string why;
            double w = 0, h = 0;
            midi_roll_box(midi_roll_file(notes, speed == 1.0 ? 0.0 : midi_bpm(notes.c_str()) * speed, why), w, h);
            kept.at = said, kept.copies = midi_copies(midi_of(notes), n, (said - doc_literal(d, layer, "start", 0, 0)) * speed, doc_number(d, 0, "high", 0, 1080) / 1080.0 * (double)d.stage->h / std::max(1.0, doc_number(d, 0, "high", 0, 1080) * doc_point(d, layer, said)), h);
        }
        const ScriptCopy c = copy < n ? kept.copies[(size_t)copy] : ScriptCopy{};
        out.c = c, out.by = 1;
    } else   // (a recipe as code: each copy where the layer's script and its expressions say, on top of what its copies' values say)
        if (const std::vector<DocScript*> scs = doc_placing_scs(d, layer); !scs.empty()) {   // (a sketch's own mesh has no copies to place: sketch.h)
            Doc::Scripted& kept = d.scripted[layer];
            const double gone = doc_literal(d, layer, "begin", 0, 0), begins = doc_literal(d, layer, "start", 0, 0) - gone, clock = doc_own_time(d, layer, said, said - begins);   // (a part after a cut goes on from where it was: doc_own_clock)
            if (const std::string from = d.evaluating ? d.placing[layer].from : doc_expressions_said(d, layer); kept.at != said || kept.own != clock || kept.made != doc_scripts_made(d) || (int)kept.copies.size() != n || kept.from != from) {   // (every copy at once, the knobs read once)
                kept.at = said, kept.own = clock, kept.made = doc_scripts_made(d), kept.from = from;
                kept.copies = doc_expressions_lay(d, layer, scs, n, said, clock, gone);
            }
            const ScriptCopy c = copy < n ? kept.copies[(size_t)copy] : ScriptCopy{};
            out.c = c, out.by = 2;
        }
    return out;
}
static math::mat4 doc_place(Doc& d, int layer, double now, int deeper, int copy, bool member) {
    const double said = now;   // (the moment itself: what lays its copies is asked at it, whatever the copy's delay)
    struct Placing { Doc& d; int copy, n; bool hasAt; math::double3 at; ~Placing() { d.ctxCopy = copy, d.ctxN = n, d.ctxHasAt = hasAt, d.ctxAt = at; } } was{d, d.ctxCopy, d.ctxN, d.ctxHasAt, d.ctxAt};   // (which copy, as it was before: told back after)
    {
        const int many = member ? doc_members(d, layer) : 1;
        d.ctxCopy = member ? copy : 0, d.ctxN = many, d.ctxHasAt = false;
    }
    if (member) now -= doc_delay(d, layer, copy);   // (a member of its copies: as it was so much earlier)
    const auto turned = [&](const char* name, math::double3 about) { return math::mat4::rotation(doc_literal(d, layer, name, now, 0) * (double)TAU / 360.0, about); };
    float2 half{0.5f};
    float deep = 0.f;
    doc_half(d, layer, &half, &deep);
    const math::double3 anchor{doc_literal(d, layer, "anchor_x", now, 0) * half.x, doc_literal(d, layer, "anchor_y", now, 0) * half.y, doc_literal(d, layer, "anchor_z", now, 0) * deep};
    // A member of its copies is moved in units of the stage (so a larger layer is not further apart), laid where
    // its recipe or its MIDI file's notes say (doc_laid) about the layer's own place; then turned and sized as they
    // say, about its anchor.
    const int n = member ? doc_members(d, layer) : 1;
    const DocLaid laid = member ? doc_laid(d, layer, copy, n, said) : DocLaid{};
    math::double3 shift{0.0};
    math::mat4 own;
    if (member) {
        shift += math::double3{laid.c.x, laid.c.y, laid.c.z};   // (where its recipe, or its MIDI file's notes, lay this copy: first, so a falloff reads where it lies)
        if (doc_connects(d, layer)) {   // (where this copy lies, as its recipe lays it, on the stage: what a falloff weighs; its own values, unconnected)
            d.ctxAt = (doc_above(d, layer, now, deeper) * math::double4{doc_number(d, layer, "x", now, 0) + shift.x, doc_number(d, layer, "y", now, 0) + shift.y, doc_number(d, layer, "z", now, 0) + shift.z, 1.0}).xyz;
            d.ctxHasAt = true;
        }
    }
    if (const std::string file = doc_literal_word(d, layer, "file"); std::filesystem::path(file).extension() == ".mid") {   // (a MIDI file's roll going by: its start at the layer at its first moment, 300 points a second, ALMaMPlayer's track.gd)
        const double speed = doc_literal(d, layer, "speed", 0, 1), point = doc_point(d, layer, said);
        std::string why;
        double w = 0, h = 0;
        if (point > 0 && midi_roll_box(midi_roll_file(file, speed == 1.0 ? 0.0 : midi_bpm(file.c_str()) * speed, why), w, h))
            shift.x += (0.5 * w - 300.0 * (said - doc_literal(d, layer, "start", 0, 0))) / point;
    }
    if (laid.by == 1) own = own * math::mat4::scaling(laid.c.size);   // (a MIDI file's note: as large as it is told)
    else if (laid.by == 2)   // (a recipe's copy turned and sized as its script and its expressions say)
        own = own * math::mat4::rotation(laid.c.rotate * (double)TAU / 360.0, math::double3{0, 0, 1}) * math::mat4::rotation(laid.c.rotate_y * (double)TAU / 360.0, math::double3{0, 1, 0}) *
                  math::mat4::rotation(laid.c.rotate_x * (double)TAU / 360.0, math::double3{1, 0, 0}) * math::mat4::scaling(math::double3{laid.c.size * laid.c.scale_x, laid.c.size * laid.c.scale_y, laid.c.size * laid.c.scale_z});
    if (const std::vector<AbsentEffect> moving = doc_placing_absent(d, layer, said); !moving.empty()) {   // (AbsentMotion's own motion, its stack in order, as AbsentMotion moves a layer: absent_motion.h)
        const double begins = doc_literal(d, layer, "start", 0, 0), lasts = doc_literal(d, layer, "duration", 0, -1);
        const AbsentMoved m = absent_motion(moving, layer, 1000.0 * begins, 1000.0 * (begins + (lasts > 0 ? lasts : doc_seconds(d))), 1000.0 * said);
        const double pixel = (double)d.stage->h / std::max(1.0, doc_number(d, 0, "high", 0, 1080) * doc_point(d, layer, said));   // (a pixel of the document where the layer stands, as a script's copies are told)
        shift += math::double3{m.x * pixel, -m.y * pixel, m.z * pixel};   // (its y down, the stage's up)
        own = own * math::mat4::rotation(-m.rotate * (double)TAU / 360.0, math::double3{0, 0, 1}) * math::mat4::scaling(math::double3{m.scale_x, m.scale_y, 1.0});   // (its turn clockwise)
        if (const std::vector<AbsentCopy>& copies = doc_absent_copies(d, layer, said); member && copy < (int)copies.size()) {   // (each copy where AbsentMotion's repeat lays it)
            const AbsentCopy& c = copies[(size_t)copy];
            shift += math::double3{c.x * pixel, -c.y * pixel, 0.0};
            own = own * math::mat4::rotation(-c.rotate * (double)TAU / 360.0, math::double3{0, 0, 1}) * math::mat4::scaling(c.scale);
        }
    }
    double tall = doc_literal(d, layer, "tall", now, 1);   // (taller, its anchor staying: a copy as its number in copy_tall says too)
    if (member) {
        auto found = d.talls.find(layer);
        if (found == d.talls.end()) {   // (read once a moment)
            std::istringstream said(doc_literal_word(d, layer, "copy_tall"));
            std::vector<double> all;
            for (std::string one; said >> one && one != "none";) all.push_back(std::atof(one.c_str()));
            found = d.talls.emplace(layer, std::move(all)).first;
        }
        const std::vector<double>& each = found->second;
        if (!each.empty()) tall *= each[(size_t)copy % each.size()];
    }
    own = own * math::mat4::scaling(math::double3{1.0, tall, 1.0});
    if (member)   // (a split text's letter turns and grows about its own middle, not the whole line's)
        if (const double middle = doc_letter_middle(d, layer, copy); middle != 0.0) own = math::mat4::translation(math::double3{middle, 0, 0}) * own * math::mat4::translation(math::double3{-middle, 0, 0});
    if (!d.phys_keyed && !deeper) {   // (a layer that falls and strikes, or a letter of one: where the world has its middle, turned as it has it)
        PhysPose pose;
        if (doc_physics(d, layer, now, &pose, member ? copy : -1)) {
            const math::quat q{pose.turn[3], pose.turn[0], pose.turn[1], pose.turn[2]};
            return math::mat4::translation(math::double3{pose.at[0], pose.at[1], pose.at[2]}) * math::mat4(math::mat3(math::quat(q))) *
                   math::mat4::scaling(doc_literal(d, layer, "size", now, 1)) *
                   math::mat4::scaling(math::double3{doc_literal(d, layer, "scale_x", now, 1), doc_literal(d, layer, "scale_y", now, 1), doc_scale_z(d, layer, now)}) *
                   math::mat4::translation(math::double3{-doc_letter_middle(d, layer, member ? copy : -1), 0, 0});
        }
    }
    const math::mat4 heading = math::mat4::rotation(doc_heading(d, layer, now), math::double3{0, 0, 1});
    if (member)   // (laid on another shape's outline, evenly, each turned the way it goes there, as Cavalry's Duplicator on a shape)
        if (const int on = (int)doc_literal(d, layer, "copy_on", 0, 0); on && on != layer && doc_number(d, on, "copy_on", 0, 0) == 0.0) {
            const auto found = d.shown.find(on);
            const Canvas2D* b = found == d.shown.end() ? nullptr : found->second.drawn;
            if (b && b->cut && b->outline) {
                const tvg::PathCommand* cmds; const tvg::Point* pts; uint32_t cmdsCnt = 0, ptsCnt = 0;
                b->outline->path(&cmds, &cmdsCnt, &pts, &ptsCnt);
                const double from = doc_literal(d, layer, "copy_on_offset", said, 0);
                Doc::Along& kept = d.along[layer];
                const double key = (double)ptsCnt + (ptsCnt ? pts[0].x * 1e-3 + pts[ptsCnt - 1].y * 1e-6 : 0.0) + n * 1e3 + from;
                if (kept.at != said || kept.key != key || kept.of != b) kept.at = said, kept.key = key, kept.of = b, sk_along(cmds, cmdsCnt, pts, n, (float)from, kept.each);
                if ((size_t)copy * 3 + 2 < kept.each.size()) {
                    const float* e = &kept.each[(size_t)copy * 3];
                    const math::mat4 there = doc_place(d, on, now);   // (its outline's place on the stage: as shape_cut lays it)
                    const math::double4 world = there * math::double4{(e[0] - 0.5 * b->cutW) / b->plainHigh * b->sheetHigh, (0.5 * b->plainHigh - e[1]) / b->plainHigh * b->sheetHigh, 0.0, 1.0};
                    const math::double3 way = there.upperLeft() * math::double3{std::cos(e[2]), -std::sin(e[2]), 0.0};
                    const math::mat4 frame = doc_above(d, layer, now, deeper) * math::mat4::translation(math::double3{doc_literal(d, layer, "x", now, 0), doc_literal(d, layer, "y", now, 0), doc_literal(d, layer, "z", now, 0)}) *
                                             heading * turned("rotate", {0, 0, 1}) * turned("rotate_y", {0, 1, 0}) * turned("rotate_x", {1, 0, 0});
                    const math::mat4 back = inverse(frame);
                    shift = (back * world).xyz;   // (where it lies, in the layer's own turned frame: its rows and scatter left out)
                    const math::double3 w = back.upperLeft() * way;
                    own = math::mat4::rotation(std::atan2(w.y, w.x), math::double3{0, 0, 1}) * own;
                }
            }
        }
    const math::mat4 above = doc_above(d, layer, now, deeper), there = above * math::mat4::translation(math::double3{doc_literal(d, layer, "x", now, 0), doc_literal(d, layer, "y", now, 0), doc_literal(d, layer, "z", now, 0)});
    math::mat4 helped;   // (Alight Motion's Parenting Helper, as bevy_alight_motion works it (MIT/Apache-2.0, src/animation/parenthelper.rs): its parent's turn and size taken by their weights, and a wheel's roll)
    if (const double wr = doc_literal(d, layer, "parent_rotate", now, 1), ws = doc_literal(d, layer, "parent_size", now, 1); doc_literal(d, layer, "parent", 0, 0) != 0.0 && (wr != 1.0 || ws != 1.0)) {
        const math::double3 ax = above[0].xyz;
        const double turn = std::atan2(ax.y, ax.x), size = std::max(1e-9, length(ax));
        helped = math::mat4::rotation(turn * (wr - 1.0), math::double3{0, 0, 1}) * math::mat4::scaling((1.0 + (size - 1.0) * ws) / size);
    }
    if (const std::string roll = doc_literal_word(d, layer, "roll"); roll == "x" || roll == "y") {   // (the way gone along over the wheel's round, in turns: x to the right turns it clockwise)
        float2 half{0.5f};
        float deep = 0.f;
        doc_half(d, layer, &half, &deep);
        const math::double3 at = (there * math::double4{0, 0, 0, 1}).xyz;
        const double r = std::min(half.x, half.y) * doc_literal(d, layer, "size", now, 1) + doc_literal(d, layer, "roll_radius", now, 0);
        if (std::fabs(r) > 1e-6) helped = helped * math::mat4::rotation(-(roll == "x" ? at.x : -at.y) / r, math::double3{0, 0, 1});
    }
    math::double2 assisted{doc_literal(d, layer, "scale_x", now, 1), doc_literal(d, layer, "scale_y", now, 1)};
    if (const std::string assist = doc_literal_word(d, layer, "scale_assist"); !assist.empty()) {   // (Alight Motion's Scale Assist, as bevy_alight_motion works it (MIT/Apache-2.0, src/animation/parenthelper.rs
        const double k = doc_literal(d, layer, "scale_assist_amount", now, 1), damp = std::max(1.0, doc_literal(d, layer, "scale_assist_damp", now, 1));   //  resolve_parenthelper_visual_scale): its axis 1 y, 2 x, 3 both)
        if (assist == "y") assisted.y *= k;
        else if (assist == "x") assisted.x *= k;
        else if (assist == "both") assisted.x *= k, assisted.y /= std::max(1e-9, std::pow(k, 1.71) * std::pow(damp, 1.0 + 2.75 * std::pow(damp - 1.0, 1.93)));
    }
    math::mat4 place = there * helped *
                       heading * turned("rotate", {0, 0, 1}) * turned("rotate_y", {0, 1, 0}) * turned("rotate_x", {1, 0, 0}) * math::mat4::translation(shift) * math::mat4::scaling(doc_literal(d, layer, "size", now, 1)) *
                       math::mat4::scaling(math::double3{assisted.x, assisted.y, doc_scale_z(d, layer, now)}) *
                       own * math::mat4::translation(-anchor);
    const double reach = member ? doc_literal(d, layer, "field_radius", said, 0) : 0.0;
    if (reach > 0.0) {   // (within the field: larger and turned about where it is seen, its picture's middle, as near the field's middle as it is)
        const math::double3 at = (place * math::double4{0.0, 0.0, 0.0, 1.0}).xyz;
        const math::double3 middle{doc_literal(d, layer, "field_x", said, 0), doc_literal(d, layer, "field_y", said, 0), doc_literal(d, layer, "field_z", said, 0)};   // (a ball: near and far measured too)
        const double from = length(at - middle), band = doc_literal(d, layer, "field_band", said, 0);
        const double near = std::clamp(band > 0.0 ? 1.0 - std::fabs(from - reach) / band : 1.0 - from / reach, 0.0, 1.0), k = near * near * (3.0 - 2.0 * near);
        const math::double3 away = at - middle;
        const double r = length(away), by = doc_literal(d, layer, "field_push", said, 0);   // (pushed out as if from a hole that wide: the nearest ones all end about as far out, the hole round however they lay)
        const math::double3 push = r > 1e-9 ? normalize(away) * (by > 0.0 ? k * (std::sqrt(r * r + by * by) - r) : k * by) : math::double3{0.0};
        place = math::mat4::translation(push) * math::mat4::translation(at) * math::mat4::rotation(k * doc_literal(d, layer, "field_rotate", said, 0) * (double)TAU / 360.0, math::double3{0, 0, 1}) *
                math::mat4::scaling(std::max(0.0, 1.0 + k * doc_literal(d, layer, "field_size", said, 0))) * math::mat4::translation(-at) * place;
    }
    // (the user's three tags: 2D sticks to the camera; 2.5D stays in the world, smaller far, but keeps the angle it
    //  was given on the screen; 3D, and a solid, is filmed as it is)
    const auto shown = d.shown.find(layer);
    if (deeper || shown == d.shown.end() || shown->second.space == 3) return place;
    if (shown->second.space == 2) return d.rig * place;
    const math::double3 at = (place * math::double4{anchor, 1.0}).xyz;   // (where it stands)
    return math::mat4::translation(at) * d.facing * math::mat4::translation(-at) * place;
}
// Where a joining layer's copies lie (its connect): one from each copy of the layer it joins to another, stretched
// along the way between them and as fine as they are far apart; those left over shown nowhere. Only where its copies
// are placed, as any layer's: the lines are its own copies, in its own fill.
static std::vector<math::mat4> doc_joins(Doc& d, int layer, double now) {
    const int one = (int)doc_number(d, layer, "connect", 0, 0), two = (int)doc_number(d, layer, "connect_to", 0, 0);
    if (!one || one == layer || !d.shown.count(one) || (two && (two == layer || !d.shown.count(two)))) return {};
    const auto where = [&](int other) {   // (where each copy of it is seen, its picture's middle, before its space is taken into account)
        std::vector<math::double3> at((size_t)doc_members(d, other));
        for (size_t i = 0; i < at.size(); ++i) at[i] = (doc_place(d, other, now, 1, (int)i, true) * math::double4{0.0, 0.0, 0.0, 1.0}).xyz;
        return at;
    };
    const std::vector<math::double3> a = where(one), b = two ? where(two) : a;
    const double reach = doc_number(d, layer, "connect_reach", now, 0);
    std::vector<std::pair<size_t, size_t>> pairs;
    const size_t most = (size_t)doc_members(d, layer);
    if (two) for (size_t i = 0; i < std::min(a.size(), b.size()); ++i) pairs.push_back({i, i});
    else if (reach <= 0.0) for (size_t i = 0; i + 1 < a.size(); ++i) pairs.push_back({i, i + 1});
    else for (size_t i = 0; i < a.size() && pairs.size() < most; ++i) for (size_t j = i + 1; j < a.size() && pairs.size() < most; ++j) if (length(a[i] - a[j]) < reach) pairs.push_back({i, j});
    float2 half{0.5f};
    float deep = 0.f;
    doc_half(d, layer, &half, &deep);
    const auto shown = d.shown.find(layer);
    const int space = shown == d.shown.end() ? 3 : shown->second.space;
    std::vector<math::mat4> lines;
    for (size_t k = 0; k < pairs.size() && k < most; ++k) {
        const math::double3 from = a[pairs[k].first], to = b[pairs[k].second], mid = (from + to) * 0.5, way = to - from;
        const double far = length(way), fine = reach > 0.0 && !two ? 0.35 + 0.65 * (1.0 - far / reach) : 1.0;   // (never finer than about a third: thinner than a dot of the screen it breaks up)
        // (along the way between them however deep it goes; its width across, as level as it can lie, facing the eye)
        const math::double3 along = far > 1e-9 ? way / far : math::double3{1, 0, 0}, flat = cross(along, math::double3{0, 0, 1});
        const math::double3 across = length(flat) > 1e-6 ? normalize(flat) : math::double3{0, 1, 0}, up = cross(along, across);
        const double wide = doc_number(d, layer, "size", now, 1) * fine;
        math::mat4 line;
        line[0] = math::double4{along * (far / std::max(1e-6, 2.0 * half.x)), 0.0};
        line[1] = math::double4{-across * wide, 0.0};
        line[2] = math::double4{up, 0.0};
        line[3] = math::double4{mid, 1.0};
        lines.push_back(space == 2 ? d.rig * line : line);
    }
    return lines;
}

// The shapes the kit's mattes are cut by that `which` names, taken out of their matte's scene and done away with,
// their looks too (a look holds the picture it reads: Filament will not let that picture go while a look holds it).
static void doc_unshape(Stage& s, const std::function<bool(const Stage::Renderable&)>& which) {
    auto& faces = s.engine->getRenderableManager();
    for (size_t i = s.renderables.size(); i-- > 0;) {
        if (!s.renderables[i].matte || !which(s.renderables[i])) continue;
        const utils::Entity e = s.renderables[i].thing;
        MaterialInstance* look = faces.getMaterialInstanceAt(faces.getInstance(e), 0);
        for (Stage::Matte& mt : s.mattes) mt.scene->remove(e);
        s.engine->destroy(e);
        s.engine->destroy(look);
        s.renderables.erase(s.renderables.begin() + (long)i);
    }
}
// Every layer told its moment: whether it is on (from its start, for its duration if it has one), what of itself it
// shows (it goes round when it comes to its end), and where it is.
// The stage's own looks, Filament's, as the document says them (layer 0): its grade made again only when it is told
// otherwise; the glow, flare, darkened corners and fog on the stage's own view; the room's light and the colour behind.
static bool doc_knows(Doc& d, int layer, const char* name, const double* number, const char* word, bool key);
static bool doc_frame(Doc& d, int layer, double now, double* frame);
// An ISF audio input's values now (screen_fx.h sounds): the sound of the layer its knob names (by number, on the card as
// a picture's is), at that layer's own moment as its film shows it (from its start, from where it begins, at its
// speed: motolii_loudness_over's way), read once aside (sound_level.h); none named, or not read yet: none (silence).
static std::vector<float> doc_sound_now(Doc& d, int layer, const std::string& file, const std::string& name, bool fft, int wide) {
    std::lock_guard<std::recursive_timed_mutex> hold(d.lock);   // (asked while the picture is drawn)
    const double now = d.stage->now;
    if (name == "aviutl.audiobuffer") {   // (the scene's whole sound, as AviUtl2's "audiobuffer" is every item's mixed: each film heard now, each at its own moment as below; the waves added, the bands the loudest)
        std::vector<float> all;
        for (const int t : doc_laid(d)) {
            if (doc_word(d, t, "kind") != "video" || doc_number(d, t, "volume", now, 1) <= 0) continue;
            const double start = doc_number(d, t, "start", 0, 0), lasts = doc_number(d, t, "duration", 0, -1);
            if (now < start || (lasts > 0 && now >= start + lasts)) continue;
            const std::string heard = doc_word(d, t, "file");
            const SoundRead* read = heard.empty() ? nullptr : sound_of(heard);
            if (!read) continue;
            const std::vector<float> one = sound_at(read, fft, wide, doc_number(d, t, "begin", 0, 0) + (now - start) * doc_number(d, t, "speed", 0, 1));
            if (all.empty()) all = one;
            else for (size_t i = 0; i < all.size() && i < one.size(); ++i) all[i] = fft ? std::max(all[i], one[i]) : std::clamp(all[i] + one[i] - 0.5f, 0.f, 1.f);
        }
        return all;
    }
    const int t = (int)doc_number(d, layer, doc_screen_parameter(file, name).c_str(), now, 0);
    if (t <= 0 || !doc_knows(d, t, nullptr, nullptr, nullptr, false)) return {};
    const std::string heard = doc_word(d, t, "file");
    if (heard.empty()) return {};
    const SoundRead* read = sound_of(heard);
    if (!read) return {};
    const double start = doc_number(d, t, "start", 0, 0), begin = doc_number(d, t, "begin", 0, 0), speed = doc_number(d, t, "speed", 0, 1);
    return sound_at(read, fft, wide, now < start ? -1.0 : begin + (now - start) * speed);
}
