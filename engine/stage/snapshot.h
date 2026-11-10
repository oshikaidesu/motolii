// Builds the two JSON snapshots that the app reads (see docs/app/BRIDGE.md). The app reads only
// these, never the document while it is being built.
//
// The render thread builds both while it holds the document, as JSON written with rapidjson (the
// copy that Filament's assimp ships). Each snapshot is stored whole, and the app is notified
// through its single listener which snapshot is new.
//   Document snapshot: rebuilt when the document changes. It holds every layer's text values,
//     resting numbers, ranges, and keyframes.
//   Time snapshot: rebuilt with each frame. It holds where each layer is and what moves, at the
//     time that was drawn.
// Included by motolii.mm, which reads it at the end, after every call it uses.
#pragma once
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/stringbuffer.h"
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/writer.h"

// A rapidjson writer that never emits a non-finite number.
struct SnapshotWriter : rapidjson::Writer<rapidjson::StringBuffer> {
    using rapidjson::Writer<rapidjson::StringBuffer>::Writer;
    // rapidjson writes nothing for NaN or infinity, which produces invalid JSON such as
    // "[,619,,]" that the app cannot parse. Write 0 instead.
    bool Double(double v) { return rapidjson::Writer<rapidjson::StringBuffer>::Double(std::isfinite(v) ? v : 0.0); }
};

// Splits a space-separated list into words. A null list gives an empty vector.
static std::vector<std::string> snapshot_words(const char* said) {
    std::vector<std::string> all;
    std::istringstream in(said ? said : "");
    for (std::string w; in >> w;) all.push_back(w);
    return all;
}

// Returns every property name of a layer: the values it has, those of its effect cards, a fixed
// set of always-present names, and every name that has a keyframe.
static std::vector<std::string> snapshot_names(Motolii* m, int layer) {
    std::set<std::string> all;
    for (const std::string& n : snapshot_words(motolii_values(m, layer))) all.insert(n);
    for (std::string n : snapshot_words(motolii_cards(m, layer))) {
        if (!n.empty() && n.back() == ';') n.pop_back();
        // A card's own name ends in ':'.
        if (n.empty() || n.back() == ':' || !std::islower((unsigned char)n[0])) continue;
        all.insert(n);
    }
    for (const char* n : {"kind", "name", "file", "fill", "blend", "text", "shape", "path", "parent", "space", "stroke", "fx", "script", "mosh"}) all.insert(n);
    // Includes properties that only exist as keyframes, such as a relation's own, for example x_by.
    doc_rows(*m->d, sqlite3_mprintf("select distinct name from keyframe where layer = %d", layer), [&](sqlite3_stmt* row) { all.insert((const char*)sqlite3_column_text(row, 0)); });
    return {all.begin(), all.end()};
}

// Writes one layer's part of the document snapshot as a JSON object.
static void snapshot_layer(Motolii* m, int layer, SnapshotWriter& w) {
    w.StartObject();
    w.Key("lasts"), w.Double(motolii_lasts(m, layer));
    w.Key("values"), w.String(motolii_values(m, layer));
    w.Key("moving"), w.String(motolii_moving(m, layer));
    w.Key("cards"), w.String(motolii_cards(m, layer));
    w.Key("more"), w.String(motolii_cards_more(m, layer));
    w.Key("fx"), w.String(motolii_fx_titles(m, layer));
    w.Key("stretches"), w.String(motolii_layer_stretches(m, layer));
    {
        double at[512];
        const int n = std::min(motolii_layer_key_times(m, layer, at, 512), 512);
        w.Key("keys"), w.StartArray();
        for (int i = 0; i < n; ++i) w.Double(at[i]);
        w.EndArray();
    }
    const std::vector<std::string> names = snapshot_names(m, layer);
    w.Key("word"), w.StartObject();
    for (const std::string& n : names) if (const std::string s = motolii_word(m, layer, n.c_str()); !s.empty()) w.Key(n.c_str()), w.String(s.c_str());
    w.EndObject();
    // Resting values: the value at time 0. A property missing here has its default value, the
    // document's "usual", if its layer kind defines one.
    w.Key("value"), w.StartObject();
    // A parameter driven by a macro is written as the macro produces it (see
    // document/expressions.h).
    for (const std::string& n : names) if (double v = 0; doc_value(*m->d, layer, n.c_str(), 0, &v)) doc_macro_over(*m->d, layer, n.c_str(), 0, &v), w.Key(n.c_str()), w.Double(v);
    w.EndObject();
    w.Key("range"), w.StartObject();
    for (const std::string& n : names) if (double lo = 0, hi = 0; motolii_range(m, layer, n.c_str(), &lo, &hi)) w.Key(n.c_str()), w.StartArray(), w.Double(lo), w.Double(hi), w.EndArray();
    w.EndObject();
    w.Key("words"), w.StartObject();
    for (const std::string& n : names) if (const std::string s = motolii_words(m, layer, n.c_str()); !s.empty()) w.Key(n.c_str()), w.String(s.c_str());
    w.EndObject();
    w.Key("reading"), w.StartObject();
    for (const std::string& n : names) w.Key(n.c_str()), w.String(motolii_reading(m, layer, n.c_str()));
    w.EndObject();
    // How each property is displayed to the user: the built-in table plus any a script defines.
    w.Key("shown"), w.StartObject();
    for (const std::string& n : names) if (const std::string s = motolii_shown(m, n.c_str()); !s.empty()) w.Key(n.c_str()), w.String(s.c_str());
    w.EndObject();
    // For each property that has keyframes, the times of those keyframes.
    w.Key("keyTimes"), w.StartObject();
    for (const std::string& n : names) {
        double at[512];
        const int k = std::min(motolii_key_times(m, layer, n.c_str(), at, 512), 512);
        if (k <= 0) continue;
        w.Key(n.c_str()), w.StartArray();
        for (int i = 0; i < k; ++i) w.Double(at[i]);
        w.EndArray();
    }
    w.EndObject();
    // For each property that has keyframes, the value at each keyframe.
    w.Key("keyValues"), w.StartObject();
    for (const std::string& n : names) {
        double at[512];
        const int k = std::min(motolii_key_times(m, layer, n.c_str(), at, 512), 512);
        if (k <= 0) continue;
        w.Key(n.c_str()), w.StartArray();
        for (int i = 0; i < k; ++i) if (double v = 0; doc_value(*m->d, layer, n.c_str(), at[i], &v)) w.Double(v); else w.Null();
        w.EndArray();
    }
    w.EndObject();
    // For each property that has keyframes, the easing of the segment that starts at each
    // keyframe, as text. An empty string means none.
    w.Key("keyEasings"), w.StartObject();
    for (const std::string& n : names) {
        double at[512];
        const int k = std::min(motolii_key_times(m, layer, n.c_str(), at, 512), 512);
        if (k <= 0) continue;
        w.Key(n.c_str()), w.StartArray();
        for (int i = 0; i < k; ++i) w.String(motolii_easing_of(m, layer, n.c_str(), at[i]));
        w.EndArray();
    }
    w.EndObject();
    w.EndObject();
}

// Preserves the document's last error text across a snapshot build.
//
// Building a snapshot is the engine's own reading, not a request from the caller. The error from
// the caller's last refused call must therefore survive whatever these reads do. It is saved on
// construction and restored on destruction, so every exit path restores it. This follows SQLite's
// error-code preserving interfaces (https://sqlite.org/c3ref/errcode.html).
struct SnapshotKeepsWhy {
    Doc& d;
    std::string why = d.error;
    ~SnapshotKeepsWhy() { d.error = why; }
};
// Rebuilds the parts of the document snapshot that changed. Runs on the render thread while it
// holds the document.
//
// A layer is rebuilt when its properties changed. Every layer is rebuilt when a layer was added
// or removed, or when a layer was renamed, because a name determines which cards other layers
// offer. The document-wide part is always rebuilt. Each layer's part keeps the version it was
// built at, so the app can ask only for what is newer than what it has.
static void snapshot_update(Motolii* m) {
    Doc& d = *m->d;
    const SnapshotKeepsWhy keep{d};
    std::set<int> again;
    bool all = d.layers_changed || m->snapshotLayers.empty();
    std::string changes = d.layers_changed ? "things\n" : "";
    for (const auto& [layer, name] : d.changed) {
        changes += std::to_string(layer) + " " + name + "\n";
        if (name == "name") all = true;
        again.insert(layer);
    }
    d.changed.clear(), d.layers_changed = false;
    m->snapshotRows = sqlite3_total_changes(d.file);
    int layers[1024];
    const int n = std::min(motolii_layers(m, layers, 1024), 1024);
    std::map<int, std::string> parts;
    const auto build = [&](int layer) {
        rapidjson::StringBuffer out;
        SnapshotWriter w(out);
        snapshot_layer(m, layer, w);
        parts[layer] = {out.GetString(), out.GetSize()};
    };
    // Layer 0 is the stage itself; its cards are the stage's.
    if (all || again.count(0)) build(0);
    for (int i = 0; i < n; ++i) if (all || again.count(layers[i])) build(layers[i]);
    rapidjson::StringBuffer out;
    SnapshotWriter w(out);
    w.StartObject();
    w.Key("seconds"), w.Double(motolii_seconds(m));
    w.Key("rate"), w.Int(motolii_rate(m));
    { int wide = 0, high = 0; motolii_size_of(m, &wide, &high); w.Key("size"), w.StartArray(), w.Int(wide), w.Int(high), w.EndArray(); }
    w.Key("fits"), w.Bool(motolii_fits(m) != 0);
    { double a = 0, b = 0; motolii_work_of(m, &a, &b); w.Key("work"), w.StartArray(), w.Double(a), w.Double(b), w.EndArray(); }
    w.Key("point"), w.Double(motolii_point(m));
    // Seconds spent editing the project, like Alight Motion's Total Edit Time.
    w.Key("edited"), w.Double(doc_edited(*m->d));
    w.Key("marks"), w.String(motolii_marks(m));
    w.Key("markColours"), w.String(motolii_mark_colours(m));
    w.Key("settings"), w.String(motolii_settings(m));
    w.Key("guides"), w.String(motolii_guides(m));
    w.Key("easings"), w.String(motolii_easings(m));
    w.Key("easingNames"), w.String(motolii_easing_names(m));
    w.Key("effectNames"), w.String(motolii_effect_names(m));
    // Each easing's shape, sampled at 65 evenly spaced steps of u from 0 to 1, so the app can
    // draw its curve.
    w.Key("easingCurves"), w.StartObject();
    for (const std::string& easing : snapshot_words(motolii_easing_names(m))) {
        w.Key(easing.c_str()), w.StartArray();
        for (int i = 0; i <= 64; ++i) w.Double(motolii_easing_at(m, easing.c_str(), i / 64.0));
        w.EndArray();
    }
    w.EndObject();
    w.Key("changes"), w.String(changes.c_str());
    // The default value of each numeric property, used when the document does not set it.
    w.Key("usual"), w.StartObject();
    for (const DocValue& v : doc_values) if (!v.words) w.Key(v.name), w.Double(doc_usual(*m->d, v.name)), w.Key((std::string(v.name) + "_by").c_str()), w.Double(0);
    w.EndObject();
    // The properties each layer kind has, whether or not they are set. Matches doc_knows.
    w.Key("knows"), w.StartObject();
    for (const char* kind : {"video", "image", "text", "solid", "shape", "camera", "light", "behaviour", "stage"}) {
        std::string all;
        for (const DocValue& v : doc_values)
            // The "_by" variant is the property as driven by a behaviour. The stage has none.
            if (doc_among(v.kinds, kind)) all += std::string(all.empty() ? "" : " ") + v.name + (v.words || !strcmp(kind, "stage") ? "" : std::string(" ") + v.name + "_by");
        w.Key(kind), w.String(all.c_str());
    }
    w.EndObject();
    w.Key("layers"), w.StartArray();
    for (int i = 0; i < n; ++i) w.Int(layers[i]);
    w.EndArray();
    w.EndObject();
    std::lock_guard<std::mutex> hold(m->snapshotLock);
    std::string own = {out.GetString(), out.GetSize()};
    // Nothing the app reads changed, so publish no new snapshot.
    if (parts.empty() && own == m->snapshotAll) return;
    const long v = ++m->snapshotVersion;
    for (auto& [layer, part] : parts) m->snapshotLayers[layer] = {v, std::move(part)};
    std::set<int> are(layers, layers + n);
    are.insert(0);
    // Drop the parts of layers that no longer exist.
    for (auto it = m->snapshotLayers.begin(); it != m->snapshotLayers.end();) it = are.count(it->first) ? std::next(it) : m->snapshotLayers.erase(it);
    m->snapshotAll = std::move(own);
    m->snapshotPending |= 1;
}

// Rebuilds the time snapshot for the current time. Runs on the render thread while it holds the
// document, whenever the time is set.
//
// For each layer it holds the bounding box, the box as seen, the gizmo, and the transform values
// as the stage shows them. For the selected layer and the layers the app watches it also holds
// the values that move at this time. For the selected layer it also holds its points and handles.
static void snapshot_time(Motolii* m) {
    Doc& d = *m->d;
    const SnapshotKeepsWhy keep{d};
    const double at = m->now;
    rapidjson::StringBuffer out;
    SnapshotWriter w(out);
    w.StartObject();
    w.Key("now"), w.Double(at);
    int layers[1024];
    const int n = std::min(motolii_layers(m, layers, 1024), 1024);
    w.Key("layer"), w.StartObject();
    for (int i = 0; i < n; ++i) {
        const int t = layers[i];
        w.Key(std::to_string(t).c_str()), w.StartObject();
        double frame[8], box[4];
        if (doc_frame(d, t, at, frame)) { w.Key("bounds"), w.StartArray(); for (double f : frame) w.Double(f); w.EndArray(); }
        if (doc_seen_box(d, t, at, box)) { w.Key("seen"), w.StartArray(); for (double b : box) w.Double(b); w.EndArray(); }
        if (const std::string g = doc_gizmo(d, t, at); !g.empty()) w.Key("gizmo"), w.String(g.c_str());
        // Each value as the stage shows it, as [value, driven]. "driven" is true when a relation
        // or behaviour drives the value.
        w.Key("shows"), w.StartObject();
        for (const char* name : {"x", "y", "z", "rotate", "scale_x", "scale_y", "opacity"})
            if (double v = 0; const int got = motolii_shows(m, t, name, at, &v)) w.Key(name), w.StartArray(), w.Double(v), w.Bool(got == 2), w.EndArray();
        w.EndObject();
        // The values that move at this time, for the selected layer and for layers the app watches.
        if (t == m->pick || m->watched.count(t)) {
            w.Key("value"), w.StartObject();
            for (const std::string& name : snapshot_words(motolii_moving(m, t)))
                if (double v = 0; doc_value(d, t, name.c_str(), at, &v)) doc_macro_over(d, t, name.c_str(), at, &v), w.Key(name.c_str()), w.Double(v);
            w.EndObject();
        }
        if (t == m->pick) {
            double xy[512], of[512];
            const int p = std::min(doc_points(d, t, at, xy, 256), 256);
            w.Key("points"), w.StartArray(); for (int k = 0; k < 2 * p; ++k) w.Double(xy[k]); w.EndArray();
            const int h = std::min(doc_points(d, t, at, xy, 256, true, of), 256);
            w.Key("handles"), w.StartArray(); for (int k = 0; k < 2 * h; ++k) w.Double(xy[k]); w.EndArray();
            w.Key("of"), w.StartArray(); for (int k = 0; k < 2 * h; ++k) w.Double(of[k]); w.EndArray();
        }
        w.EndObject();
    }
    w.EndObject();
    w.EndObject();
    std::lock_guard<std::mutex> hold(m->snapshotLock);
    ++m->timeVersion;
    m->timeSnapshot = {out.GetString(), out.GetSize()};
    m->snapshotPending |= 2;
}

// Tells the app, through its listener, which snapshots are new. Call it after the document has
// been released, following Lumit's rule. The argument is a bit mask: 1 for the document snapshot,
// 2 for the time snapshot, and 4 for a change in which stage frames are cached on disk.
static void snapshot_notify(Motolii* m) {
    int pending;
    { std::lock_guard<std::mutex> hold(m->snapshotLock); pending = m->snapshotPending, m->snapshotPending = 0; }
    // The set of stage frames cached on disk changed.
    if (const long k = m->cache.told.load(); k != m->cacheNotified) pending |= 4, m->cacheNotified = k;
    if (pending && m->listener) m->listener(pending);
}
