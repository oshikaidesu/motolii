// Shown state for the app: the layers there are, how long each is on, the times of keyframes, and
// where a layer appears in the preview. Included by doc.h; not self-contained.

// Returns the layers in the order they lie, the one furthest back first.
static std::vector<int> doc_layers(Doc& d) { return doc_laid(d); }
// Returns how long the layer is on, in seconds, or -1 when it never ends.
static double doc_lasts(Doc& d, int layer) {
    const double lasts = doc_number(d, layer, "duration", 0, -1);
    return lasts > 0.0 ? lasts : -1.0;
}
// Returns the times of the keyframes of a property. A property with one keyframe has none.
static std::vector<double> doc_key_times(Doc& d, int layer, const char* name) {
    // This is asked for again and again between changes, so the document is asked only once.
    const auto known = d.keyed.find({layer, name});
    if (known != d.keyed.end()) return known->second;
    std::vector<double>& at = d.keyed[{layer, name}];
    doc_rows(d, sqlite3_mprintf("select at from keyframe where layer = %d and name = %Q and " DOC_KEYED " order by at", layer, name, layer, name),
             [&](sqlite3_stmt* row) { at.push_back(sqlite3_column_double(row, 0)); });
    return at;
}

// Computes what doc_half caches.
static bool doc_half_now(Doc& d, int layer, float2* half, float* deep);
// Returns half of the width and height of a layer at size 1, before it is placed, in `half`. A
// sheet gives the size of the sheet, and a solid the size of its bounding box. The app draws the
// bounds of a layer from this. `deep`, which may be null, receives half of how far the layer
// reaches towards the camera and away, and is 0 for a flat layer. Returns false when the layer is
// not shown. The result is cached.
static bool doc_half(Doc& d, int layer, float2* half, float* deep) {
    if (const auto kept = d.halves.find(layer); kept != d.halves.end()) return *half = kept->second.first, deep ? *deep = kept->second.second : 0.f, true;
    float far = 0.f;
    if (!doc_half_now(d, layer, half, &far)) return false;
    d.halves[layer] = {*half, far};
    if (deep) *deep = far;
    return true;
}
static bool doc_half_now(Doc& d, int layer, float2* half, float* deep) {
    const auto shown = d.shown.find(layer);
    if (shown == d.shown.end()) return false;
    const Doc::Shown& t = shown->second;
    if (t.solid) {
        const Aabb box = t.solid->asset->getBoundingBox();
        const float tall = std::max(box.max.y - box.min.y, 1e-6f);
        if (deep) *deep = 0.5f * (box.max.z - box.min.z) / tall;
        return *half = float2{0.5f * (box.max.x - box.min.x) / tall, 0.5f}, true;
    }
    const Mesh* m = t.video ? t.video->sheet : t.drawn ? t.drawn->sheet : t.shape;
    if (!m || m->pos.empty()) return false;
    float3 most{0.f};
    for (const float3& p : m->pos) most = max(most, abs(p));
    if (deep) *deep = most.z;
    return *half = most.xy, true;
}

// Returns where point `p` of the stage appears in the preview, as the stage's camera sees it. The
// result is in points from the top left.
static math::double2 doc_seen(Doc& d, math::double3 p) {
    Stage& s = *d.stage;
    const math::double4 c = s.camera->getProjectionMatrix() * s.camera->getViewMatrix() * math::double4{p, 1.0};
    // A point at or behind the camera, such as the far corners of a floor, lands far away on that
    // side and not at an undefined number.
    const double w = std::max(c.w, 1e-6);
    return math::double2{(0.5 + 0.5 * c.x / w) * s.w, (0.5 - 0.5 * c.y / w) * s.h};
}
// Returns the points that draw a camera layer as the working camera sees it, as numbers separated
// by spaces. They are x and y in the preview for the four corners of its frame, the point it looks
// at, and where it is. The frame is the rectangle of the preview at the point it looks at, as large
// as the lens takes in there. This follows the CameraFrame of AbsentMotion and the point of
// interest and camera of After Effects. A point behind the working camera is written "x x". Returns
// an empty text when there is no working camera or the layer is not a camera.
static std::string doc_gizmo(Doc& d, int layer, double now) {
    if (!d.working || doc_word(d, layer, "kind") != "camera") return "";
    Stage& s = *d.stage;
    const DocViewCamera e = doc_view_camera_of(d, layer, now);
    const double high = 6.0 * e.far * std::tan(0.5 * e.fov), wide = high * double(s.w) / double(s.h);
    const math::double3 x = (e.round * math::double4{wide, 0, 0, 0}).xyz, y = (e.round * math::double4{0, high, 0, 0}).xyz;
    std::string said;
    for (const math::double3 p : {e.look - x + y, e.look + x + y, e.look + x - y, e.look - x - y, e.look, e.eye}) {
        const math::double4 c = s.camera->getProjectionMatrix() * s.camera->getViewMatrix() * math::double4{p, 1.0};
        const math::double2 at = doc_seen(d, p);
        said += c.w <= 0.0 ? "x x " : std::to_string(at.x) + " " + std::to_string(at.y) + " ";
    }
    return said;
}
// Returns how many points of the preview one unit of the stage is, at the depth where the layer
// stands.
static double doc_point(Doc& d, int layer, double now) {
    const math::double3 at = (doc_above(d, layer, now) * math::double4{doc_number(d, layer, "x", now, 0), doc_number(d, layer, "y", now, 0), doc_number(d, layer, "z", now, 0), 1.0}).xyz;
    return doc_seen(d, at + math::double3{1, 0, 0}).x - doc_seen(d, at).x;
}
// Returns where a layer is at time `now`, as the stage places it. A layer on its own that an
// expression moves, or that is delayed, is placed as the member of its copies that it is drawn as.
static math::mat4 doc_shown_at(Doc& d, int layer, double now) { return doc_place(d, layer, now, 0, 0, doc_members(d, layer) == 1 && doc_staggered(d, layer, now)); }
// Computes the bounds of a layer in the preview at time `now`, as the stage's camera sees it.
// `frame` receives eight numbers, in points from the top left: the middle x and y, the width, the
// height, the rotation in degrees clockwise as seen, the pivot x and y, and the depth. Returns
// false when the layer is not shown.
static bool doc_frame(Doc& d, int layer, double now, double* frame) {
    float2 half{0.f};
    float deep = 0.f;
    // A layer that is not on, or is set aside, has no bounds, because the user cannot grab what is
    // not seen.
    if (!doc_half(d, layer, &half, &deep) || !d.shown[layer].in) return false;
    const double size = doc_number(d, layer, "size", now, 1), point = doc_point(d, layer, now);
    // The layer's own middle, wherever its anchor is.
    const math::double2 middle = doc_seen(d, (doc_shown_at(d, layer, now) * math::double4{0, 0, 0, 1}).xyz);
    const double sx = doc_number(d, layer, "scale_x", now, 1), sy = doc_number(d, layer, "scale_y", now, 1), sz = doc_number(d, layer, "scale_z", now, 1);
    frame[0] = middle.x, frame[1] = middle.y, frame[2] = 2.0 * half.x * size * std::fabs(sx) * point, frame[3] = 2.0 * half.y * size * std::fabs(sy) * point;
    frame[4] = -doc_number(d, layer, "rotate", now, 0) - doc_heading(d, layer, now) * 360.0 / (double)TAU;
    const math::double3 anchor{doc_number(d, layer, "anchor_x", now, 0) * half.x, doc_number(d, layer, "anchor_y", now, 0) * half.y, 0.0};
    // The point it rotates about.
    const math::double2 pivot = doc_seen(d, (doc_shown_at(d, layer, now) * math::double4{anchor, 1.0}).xyz);
    // The last number is the depth of the layer in points, 0 for a flat layer.
    frame[5] = pivot.x, frame[6] = pivot.y, frame[7] = 2.0 * deep * size * std::fabs(sz) * point;
    // A layer that is rotated about an axis other than the camera's, or that has a parent, gets the
    // upright box of what it covers as its bounds.
    double box[4];
    if (doc_number(d, layer, "rotate_x", now, 0) != 0.0 || doc_number(d, layer, "rotate_y", now, 0) != 0.0 || doc_number(d, layer, "parent", 0, 0) != 0.0) {
        // Pairs of x and y that outline what the layer covers, taken from its own points where they
        // are at hand, see doc_outline.
        double around[128];
        const int n = doc_outline(d, layer, now, around);
        if (n > 2) {
            double x0 = around[0], x1 = x0, y0 = around[1], y1 = y0;
            for (int i = 1; i < n; ++i) x0 = std::min(x0, around[2 * i]), x1 = std::max(x1, around[2 * i]), y0 = std::min(y0, around[2 * i + 1]), y1 = std::max(y1, around[2 * i + 1]);
            // The middle stays the layer's own. The bounds reach as far each way as the outline
            // goes on its farther side.
            frame[2] = 2.0 * std::max(frame[0] - x0, x1 - frame[0]), frame[3] = 2.0 * std::max(frame[1] - y0, y1 - frame[1]), frame[4] = 0.0;
        } else if (doc_covers(d, layer, now, box)) frame[2] = box[2], frame[3] = box[3], frame[4] = 0.0;
    }
    return true;
}
