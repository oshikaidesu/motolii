// material.h: part of doc.h (the material a thing wears; its looks and drawn parts on the stage). Read only through doc.h.
// The material a thing wears (Create's Material group: any thing wears one, one at a time): its shading as said; a solid
// filled with glass, as documents before it said glass, glass. "" none: a solid Filament's lit surface, a flat thing as drawn.
static std::string doc_material(Doc& d, int thing) {
    const std::string said = doc_word(d, thing, "shading");
    if (!said.empty()) return said;
    return doc_word(d, thing, "kind") == "solid" && doc_word(d, thing, "fill") == "glass" ? "glass" : "";
}
// The sheet a flat thing (a film, a picture, a text, a shape) wears its material as: flat.mat's own for it (kit_wgpu.sh),
// its picture its colour. "" none: as it is drawn. Of glass, the stage behind it is read (doc_things_read).
static std::string doc_sheet_wear(Doc& d, int thing) {
    if (!doc_among("film picture text shape", doc_word(d, thing, "kind"))) return "";
    const std::string m = doc_material(d, thing);
    return m == "lit" ? "wear" : m == "glass" || m == "filament_glass" ? "glass" : doc_among("cloth subsurface lacquer bubble", m) ? m : "";
}

// Every look of a thing as it is on the stage (a sheet's one; a kit shape's, as many as it is drawn by; every face of a 3D file).
// A way of lying on what is under that reads what is under (the W3C's compositing, After Effects' and ThorVG's): its
// number in flat.mat's blendWay (0: one the GPU's own blending does: normal, add, multiply, screen).
static int doc_blend_way(const std::string& word) {
    static const char* const ways[] = {"darken", "lighten", "overlay", "soft_light", "hard_light", "color_dodge", "color_burn", "difference", "exclusion", "hue", "saturation", "color", "luminosity",
                                       "linear_burn", "linear_light", "vivid_light", "pin_light", "darker_color", "lighter_color", "subtract", "divide"};
    for (int i = 0; i < 21; ++i) if (word == ways[i]) return i + 1;
    return 0;
}
static void doc_looks(Stage& s, const Doc::Shown& t, const std::function<void(MaterialInstance*)>& each) {
    auto& faces = s.engine->getRenderableManager();
    if (t.film) each(t.film->look);
    if (t.drawn) each(t.drawn->look);
    for (const Stage::Made& made : s.made)
        if (t.shape && made.of == t.shape) each(faces.getMaterialInstanceAt(faces.getInstance(made.thing), 0));
    if (t.solid) for (const utils::Entity e : t.solid->parts) {
        const auto one = faces.getInstance(e);
        for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part) each(faces.getMaterialInstanceAt(one, part));
    }
}
// Each drawn part of a thing (Filament's renderables), and the scene it is in (its run's: run 0 or not yet put, the stage's own).
static void doc_entities(Stage& s, const Doc::Shown& t, const std::function<void(utils::Entity)>& each) {
    const Mesh* m = t.film ? t.film->sheet : t.drawn ? t.drawn->sheet : t.shape;
    for (const Stage::Made& made : s.made)
        if (m && made.of == m && !made.matte) each(made.thing);
    if (t.solid) for (const utils::Entity e : t.solid->parts) each(e);
}
static void doc_parts(Stage& s, const Doc::Shown& t, const std::function<void(RenderableManager&, RenderableManager::Instance)>& each) {
    auto& faces = s.engine->getRenderableManager();
    doc_entities(s, t, [&](utils::Entity e) { each(faces, faces.getInstance(e)); });
}
static bool doc_covers(Doc& d, int thing, double now, double* box);
static bool doc_seen_box(Doc& d, int thing, double now, double* box);
static int doc_outline(Doc& d, int thing, double now, double* xy);
static bool doc_half(Doc& d, int thing, float2* half, float* deep = nullptr);
// Where a thing is at a moment, as a matrix: moved, turned about z, y and x, made its size, all about its anchor (a
// point of its own box: 0 its middle, 1 its edge on that side; the past repository's `anchor`, keyed as it was).
static math::mat4 doc_place(Doc& d, int thing, double now, int deeper = 0, int copy = 0, bool member = false);
static math::mat4 doc_shown_at(Doc& d, int thing, double now);
int sk_along(const tvg::PathCommand* cmds, uint32_t cmdsCnt, const tvg::Point* pts, int n, float from, std::vector<float>& out);
static double doc_point(Doc& d, int thing, double now);
static math::double2 doc_seen(Doc& d, math::double3 p);
static math::mat4 doc_above(Doc& d, int thing, double now, int deeper);
static bool doc_match(Doc& d);
static double doc_seconds(Doc& d);
// A thing's copies given back its own look, their own looks done away with (no longer coloured each, or taken off).
// What a behaviour gives the nth of n copies at a moment (Cavalry's stagger, oscillator, noise and random, its names):
// from its minimum to its maximum.
static int doc_driven_by(Doc& d, int thing, const char* name);
