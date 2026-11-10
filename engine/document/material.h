// Included by doc.h; not self-contained. Contains the material a layer wears and the helpers that
// reach the materials and renderables of a layer on the stage.

// Returns the material a layer wears. In the Material group of the Create tab any layer can wear
// one, one at a time, and the shading property names it. Documents from before that group existed
// filled a solid with glass to get glass, so a solid filled with glass wears glass. Returns "" for
// none: a solid then uses Filament's lit surface, and a flat layer is drawn as it is.
static std::string doc_material(Doc& d, int layer) {
    const std::string said = doc_word(d, layer, "shading");
    if (!said.empty()) return said;
    return doc_word(d, layer, "kind") == "solid" && doc_word(d, layer, "fill") == "glass" ? "glass" : "";
}
// Returns the variant of the material for a flat layer (a video, image, text or shape): the variant
// of flat.mat made for it (filament_webgpu.sh), with the image as its colour. Returns "" for none,
// and the layer is then drawn as it is. For glass the stage behind the layer is read
// (doc_layers_read).
static std::string doc_sheet_material(Doc& d, int layer) {
    if (!doc_among("video image text shape", doc_word(d, layer, "kind"))) return "";
    const std::string m = doc_material(d, layer);
    return m == "lit" ? "wear" : m == "glass" || m == "filament_glass" ? "glass" : doc_among("cloth subsurface lacquer bubble", m) ? m : "";
}

// Returns the 1-based index in flat.mat's blendWay of a blend mode that reads the pixels
// underneath, as defined by the W3C compositing specification and implemented by After Effects and
// ThorVG. Returns 0 for the modes that the GPU's own blending does: normal, add, multiply and
// screen.
static int doc_blend_way(const std::string& word) {
    static const char* const ways[] = {"darken", "lighten", "overlay", "soft_light", "hard_light", "color_dodge", "color_burn", "difference", "exclusion", "hue", "saturation", "color", "luminosity",
                                       "linear_burn", "linear_light", "vivid_light", "pin_light", "darker_color", "lighter_color", "subtract", "divide"};
    for (int i = 0; i < 21; ++i) if (word == ways[i]) return i + 1;
    return 0;
}
// Calls `each` with every material instance of a layer on the stage: the one of a sheet, the ones
// of a built-in shape (as many as it is drawn by), and every face of a 3D file.
static void doc_material_instances(Stage& s, const Doc::Shown& t, const std::function<void(MaterialInstance*)>& each) {
    auto& faces = s.engine->getRenderableManager();
    if (t.video) each(t.video->look);
    if (t.drawn) each(t.drawn->look);
    for (const Stage::Renderable& made : s.renderables)
        if (t.shape && made.of == t.shape) each(faces.getMaterialInstanceAt(faces.getInstance(made.thing), 0));
    if (t.solid) for (const utils::Entity e : t.solid->parts) {
        const auto one = faces.getInstance(e);
        for (size_t part = 0; part < faces.getPrimitiveCount(one); ++part) each(faces.getMaterialInstanceAt(one, part));
    }
}
// Calls `each` with each part of a layer that is drawn, as Filament renderables.
static void doc_entities(Stage& s, const Doc::Shown& t, const std::function<void(utils::Entity)>& each) {
    const Mesh* m = t.video ? t.video->sheet : t.drawn ? t.drawn->sheet : t.shape;
    for (const Stage::Renderable& made : s.renderables)
        if (m && made.of == m && !made.matte) each(made.thing);
    if (t.solid) for (const utils::Entity e : t.solid->parts) each(e);
}
// Calls `each` with the renderable manager and the instance of each drawn part of a layer.
static void doc_parts(Stage& s, const Doc::Shown& t, const std::function<void(RenderableManager&, RenderableManager::Instance)>& each) {
    auto& faces = s.engine->getRenderableManager();
    doc_entities(s, t, [&](utils::Entity e) { each(faces, faces.getInstance(e)); });
}
static bool doc_covers(Doc& d, int layer, double now, double* box);
static bool doc_seen_box(Doc& d, int layer, double now, double* box);
static int doc_outline(Doc& d, int layer, double now, double* xy);
static bool doc_half(Doc& d, int layer, float2* half, float* deep = nullptr);
// Returns the matrix that places a layer at a time: moved, rotated about z, y and x, and scaled,
// all about its anchor. The anchor is a point of the layer's own box: 0 is its middle and 1 is its
// edge on that side. It is keyed as the older `anchor` property was.
static math::mat4 doc_place(Doc& d, int layer, double now, int deeper = 0, int copy = 0, bool member = false);
static math::mat4 doc_shown_at(Doc& d, int layer, double now);
static double doc_point(Doc& d, int layer, double now);
static math::double2 doc_seen(Doc& d, math::double3 p);
static math::mat4 doc_above(Doc& d, int layer, double now, int deeper);
static bool doc_match(Doc& d);
static double doc_seconds(Doc& d);
// Declared here and defined later. The value a behaviour gives the nth of n copies at a time, from
// its minimum to its maximum, like Cavalry's stagger, oscillator, noise and random.
static int doc_driven_by(Doc& d, int layer, const char* name);
