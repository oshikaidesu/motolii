// look_map.h: part of motolii.mm, read before motolii_calls.h. The shelves' maps: what is alike lies near, as XLN Audio's
// XO lays its samples out by how alike they sound, by t-SNE (its head of software design to Computer Music, 2019), here
// qdtsne's (MIT, third_party/qdtsne), its quick start as it is; and a font's letters drawn small to be told by, as IDEO's
// Font Map laid fonts out by their drawn letters.

int motolii_map(const float* points, int n, int dims, double* xy) {
    if (!points || !xy || n < 4 || dims < 1) return 0;
    std::vector<double> data(points, points + (size_t)n * (size_t)dims);   // (a point a column: qdtsne's column-major)
    knncolle::VptreeBuilder<int, double, double> near(std::make_shared<knncolle::EuclideanDistance<double, double>>());
    qdtsne::Options o;
    o.perplexity = std::min(o.perplexity, (n - 1) / 3.0);   // (its own 30, or what so few allow: three neighbours to a unit, perplexity_to_k)
    auto status = qdtsne::initialize<2>((std::size_t)dims, n, data.data(), near, o);
    auto y = qdtsne::initialize_random<2>((std::size_t)n);   // (its own seed: the same points, the same map)
    status.run(y.data());
    for (int axis = 0; axis < 2; ++axis) {   // (each way from 0 to 1: where on the shelf's plane)
        double lo = y[axis], hi = y[axis];
        for (int i = 0; i < n; ++i) lo = std::min(lo, y[2 * i + axis]), hi = std::max(hi, y[2 * i + axis]);
        for (int i = 0; i < n; ++i) xy[2 * i + axis] = hi > lo ? (y[2 * i + axis] - lo) / (hi - lo) : 0.5;
    }
    return n;
}

// The words in a font file, white on black w by h, as large as they fit with a point round them, a byte a point (how
// much is covered): ThorVG's own CPU canvas, as aviutl_load.h draws a script's words; the font let go again after, as
// type_sets does (a font only asked about leaves memory). 0: not drawn.
int motolii_type_picture(const char* font, const char* words, int w, int h, unsigned char* grey) {
    if (!font || !words || !grey || w < 3 || h < 3 || w > 1024 || h > 1024 || !std::filesystem::is_regular_file(font)) return 0;
    tvg::Initializer::init(0);   // (ThorVG makes no canvas when it is not started: aviutl_drawn)
    if (tvg::Text::load(font) != tvg::Result::Success) return 0;
    std::vector<uint32_t> px((size_t)w * (size_t)h, 0);
    tvg::SwCanvas* canvas = tvg::SwCanvas::gen();
    tvg::Text* t = tvg::Text::gen();
    t->font(std::filesystem::path(font).stem().string().c_str());   // (ThorVG names a font by its file)
    t->size(100.f);
    t->text(words);
    t->fill(255, 255, 255);
    float x = 0.f, y = 0.f, wide = 0.f, tall = 0.f;
    bool drew = t->bounds(&x, &y, &wide, &tall) == tvg::Result::Success && wide > 0.f && tall > 0.f;
    if (drew) {
        const float k = std::min((w - 2) / wide, (h - 2) / tall);
        t->scale(k);
        t->translate((w - wide * k) / 2 - x * k, (h - tall * k) / 2 - y * k);
        drew = canvas->target(px.data(), w, w, h, tvg::ColorSpace::ABGR8888) == tvg::Result::Success && canvas->add(t) == tvg::Result::Success && canvas->draw(true) == tvg::Result::Success && canvas->sync() == tvg::Result::Success;
    } else tvg::Paint::rel(t);
    delete canvas;
    tvg::Text::unload(font);
    if (!drew) return 0;
    for (size_t i = 0; i < px.size(); ++i) grey[i] = (unsigned char)(px[i] & 0xFF);   // (white, premultiplied: any channel is how much is covered)
    return 1;
}
