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

// Those places each given a cell of a cols x rows grid, the one nearest them all told (none on another): Kyle McDonald's
// CloudToGrid, a t-SNE map's pictures on a grid as it does it (its nodes 0 to 1 each way as np.linspace, the cost each
// place's squared distance to each node), the assignment solved by SciPy's own linear_sum_assignment
// (third_party/scipy_lsap, BSD-3, as it is). cell[i]: row * cols + column. 0: not solved, too few cells, or so many
// that each to each is past 4 million (32 MB, some seconds: about 2,000 on a grid).
int motolii_grid(const double* xy, int n, int cols, int rows, int* cell) {
    if (!xy || !cell || n < 1 || cols < 1 || rows < 1 || (long)cols * rows < n || (long)n * cols * rows > 4000000) return 0;
    const int cells = cols * rows;
    std::vector<double> cost((size_t)n * cells);
    for (int i = 0; i < n; ++i)
        for (int c = 0; c < cells; ++c) {
            const double gx = cols > 1 ? (double)(c % cols) / (cols - 1) : .5, gy = rows > 1 ? (double)(c / cols) / (rows - 1) : .5;
            cost[(size_t)i * cells + c] = (xy[2 * i] - gx) * (xy[2 * i] - gx) + (xy[2 * i + 1] - gy) * (xy[2 * i + 1] - gy);
        }
    std::vector<int64_t> a(n), b(n);
    if (solve_rectangular_linear_sum_assignment(n, cells, cost.data(), false, a.data(), b.data()) != 0) return 0;
    for (int i = 0; i < n; ++i) cell[a[i]] = (int)b[i];
    return n;
}

// Each of n pictures (224 points square, RGBA, one after another) told as `dims` numbers by a CLIP image encoder in an
// ONNX file (OpenAI CLIP ViT-B/32's, or FontCLIP's, as tools/look_models.py writes them): the picture made into CLIP's
// own input (clip.py _transform's Normalize, its mean and spread), run by ONNX Runtime (its C++ API: Env, Session, Run),
// each answer made one long, as FontMap keeps its FontCLIP numbers (L2-normalised). A model once opened is kept open.
// 0: not told (no such model, or it answers otherwise).
int motolii_likeness(const char* model, const unsigned char* rgba, int n, int dims, float* out) {
    constexpr int side = 224, area = side * side;
    if (!model || !rgba || !out || n < 1 || dims < 1 || !std::filesystem::is_regular_file(model)) return 0;
    static std::mutex opening;
    static std::map<std::string, std::unique_ptr<Ort::Session>> open;
    try {
        static Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "motolii");
        Ort::Session* s = nullptr;
        {
            std::lock_guard<std::mutex> one(opening);
            auto& kept = open[model];
            if (!kept) kept = std::make_unique<Ort::Session>(env, model, Ort::SessionOptions{});
            s = kept.get();
        }
        const float mean[3] = {0.48145466f, 0.4578275f, 0.40821073f}, spread[3] = {0.26862954f, 0.26130258f, 0.27577711f};
        std::vector<float> in((size_t)n * 3 * area);
        for (int i = 0; i < n; ++i)
            for (int c = 0; c < 3; ++c)
                for (int p = 0; p < area; ++p) in[((size_t)i * 3 + c) * area + p] = (rgba[((size_t)i * area + p) * 4 + c] / 255.f - mean[c]) / spread[c];
        const int64_t shape[4] = {n, 3, side, side};
        Ort::MemoryInfo cpu = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
        Ort::Value x = Ort::Value::CreateTensor<float>(cpu, in.data(), in.size(), shape, 4);
        Ort::AllocatorWithDefaultOptions names;
        const auto inName = s->GetInputNameAllocated(0, names), outName = s->GetOutputNameAllocated(0, names);
        const char* ins[] = {inName.get()};
        const char* outs[] = {outName.get()};
        auto y = s->Run(Ort::RunOptions{nullptr}, ins, &x, 1, outs, 1);
        const auto said = y[0].GetTensorTypeAndShapeInfo().GetShape();
        if (said.size() != 2 || said[0] != n || said[1] != dims) return 0;
        const float* got = y[0].GetTensorData<float>();
        for (int i = 0; i < n; ++i) {
            double long2 = 0;
            for (int k = 0; k < dims; ++k) long2 += (double)got[(size_t)i * dims + k] * got[(size_t)i * dims + k];
            const float by = long2 > 0 ? (float)(1.0 / std::sqrt(long2)) : 0.f;
            for (int k = 0; k < dims; ++k) out[(size_t)i * dims + k] = got[(size_t)i * dims + k] * by;
        }
        return n;
    } catch (const Ort::Exception&) {
        return 0;
    }
}

// The words in a font file, white on black w by h, as large as they fit with a point round them (no larger than size
// `most`, when it is more than 0), a byte a point (how much is covered): ThorVG's own CPU canvas, as aviutl_load.h
// draws a script's words; the font let go again after, as type_sets does (a font only asked about leaves memory).
// 0: not drawn.
int motolii_type_picture(const char* font, const char* words, int w, int h, float most, unsigned char* grey) {
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
        const float k = std::min((w - 2) / wide, (h - 2) / tall), by = most > 0.f ? std::min(k, most / 100.f) : k;   // (as FontMap sets its specimen at 75, never larger)
        t->scale(by);
        t->translate((w - wide * by) / 2 - x * by, (h - tall * by) / 2 - y * by);
        drew = canvas->target(px.data(), w, w, h, tvg::ColorSpace::ABGR8888) == tvg::Result::Success && canvas->add(t) == tvg::Result::Success && canvas->draw(true) == tvg::Result::Success && canvas->sync() == tvg::Result::Success;
    } else tvg::Paint::rel(t);
    delete canvas;
    tvg::Text::unload(font);
    if (!drew) return 0;
    for (size_t i = 0; i < px.size(); ++i) grey[i] = (unsigned char)(px[i] & 0xFF);   // (white, premultiplied: any channel is how much is covered)
    return 1;
}
