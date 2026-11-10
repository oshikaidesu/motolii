// Implements the shelf maps declared in motolii.h: motolii_map lays items out on a plane so that
// similar ones lie near each other, motolii_grid snaps such a layout to a grid, motolii_likeness
// describes images as vectors, and motolii_type_frame draws a font specimen.
//
// XLN Audio's XO lays out samples by how alike they sound using t-SNE, and IDEO's Font Map lays
// out fonts by their drawn letters. The shelves use the same idea. The t-SNE is qdtsne (MIT,
// third_party/qdtsne), used as in its quick start.
#include "entry/motolii.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include <onnxruntime_cxx_api.h>
#include <thorvg.h>
#include "qdtsne/qdtsne.hpp"
#include "rectangular_lsap.h"

// Lays out n points of dims numbers each on a plane with t-SNE, so that similar points lie near
// each other. points holds the n points one after another. Writes 2n numbers to xy, with x and y
// each scaled to the range 0 to 1. Returns n, or 0 if there are fewer than 4 points or an
// argument is invalid.
int motolii_map(const float* points, int n, int dims, double* xy) {
    if (!points || !xy || n < 4 || dims < 1) return 0;
    // qdtsne expects column-major data: one point per column.
    std::vector<double> data(points, points + (size_t)n * (size_t)dims);
    knncolle::VptreeBuilder<int, double, double> near(std::make_shared<knncolle::EuclideanDistance<double, double>>());
    qdtsne::Options o;
    // The perplexity is qdtsne's default of 30, or less when there are few points,
    // because qdtsne needs about three neighbours per unit of perplexity.
    o.perplexity = std::min(o.perplexity, (n - 1) / 3.0);
    auto status = qdtsne::initialize<2>((std::size_t)dims, n, data.data(), near, o);
    // qdtsne's default seed, so the same points always give the same map.
    auto y = qdtsne::initialize_random<2>((std::size_t)n);
    status.run(y.data());
    // Scale each axis to the range 0 to 1, where the shelf's plane lies.
    for (int axis = 0; axis < 2; ++axis) {
        double lo = y[axis], hi = y[axis];
        for (int i = 0; i < n; ++i) lo = std::min(lo, y[2 * i + axis]), hi = std::max(hi, y[2 * i + axis]);
        for (int i = 0; i < n; ++i) xy[2 * i + axis] = hi > lo ? (y[2 * i + axis] - lo) / (hi - lo) : 0.5;
    }
    return n;
}

// Assigns each of n places in xy (x and y in 0 to 1) its own cell of a cols x rows grid, so that
// the total squared distance between each place and its cell is as small as possible. cell[i]
// receives row * cols + column. This follows Kyle McDonald's CloudToGrid, which puts the images
// of a t-SNE map on a grid: the grid nodes are spaced evenly from 0 to 1 on each axis, as
// np.linspace does, and the cost is the squared distance from each place to each node. The
// assignment is solved by SciPy's linear_sum_assignment (third_party/scipy_lsap, BSD-3,
// unmodified). Returns n, or 0 if an argument is invalid, there are fewer cells than places, or
// n times the number of cells exceeds 4 million, which takes 32 MB and some seconds, about 2,000
// places on a square grid.
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

// Describes each of n images as a vector of `dims` numbers using a CLIP image encoder stored as
// an ONNX file, either OpenAI CLIP ViT-B/32 or FontCLIP, as engine/deps/likeness_models.py
// writes them. rgba holds the images one after another, each 224 x 224 pixels in RGBA. The
// pixels are normalized with CLIP's own mean and standard deviation (clip.py, _transform's
// Normalize) and run with the ONNX Runtime C++ API (Env, Session, Run). Each output vector is
// scaled to length 1 (L2 normalization), as FontMap does with its FontCLIP vectors. Writes
// n * dims floats to out. A model, once opened, stays open for the life of the process.
// Returns n, or 0 if the model file does not exist or its output is not n x dims.
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
            auto& session = open[model];
            if (!session) session = std::make_unique<Ort::Session>(env, model, Ort::SessionOptions{});
            s = session.get();
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

// Draws words in the font file as white on black into grey, a w x h image with one byte per
// pixel giving how much of the pixel is covered. The text is as large as fits with a margin of
// one pixel on each side, and no larger than font size `most` when most is above 0. It is drawn
// on ThorVG's CPU canvas, as aviutl_load.h draws a script's text. The font is unloaded
// afterwards, as type_sets does, so a font that was only queried does not stay in memory.
// Returns 1 on success, or 0 if the text could not be drawn.
int motolii_type_frame(const char* font, const char* words, int w, int h, float most, unsigned char* grey) {
    if (!font || !words || !grey || w < 3 || h < 3 || w > 1024 || h > 1024 || !std::filesystem::is_regular_file(font)) return 0;
    // ThorVG creates no canvas unless it has been initialized.
    tvg::Initializer::init(0);
    if (tvg::Text::load(font) != tvg::Result::Success) return 0;
    std::vector<uint32_t> px((size_t)w * (size_t)h, 0);
    tvg::SwCanvas* canvas = tvg::SwCanvas::gen();
    tvg::Text* t = tvg::Text::gen();
    // ThorVG identifies a loaded font by its file name without the extension.
    t->font(std::filesystem::path(font).stem().string().c_str());
    t->size(100.f);
    t->text(words);
    t->fill(255, 255, 255);
    float x = 0.f, y = 0.f, wide = 0.f, tall = 0.f;
    bool drew = t->bounds(&x, &y, &wide, &tall) == tvg::Result::Success && wide > 0.f && tall > 0.f;
    if (drew) {
        // Fit the text inside the image with a one pixel margin. FontMap sets its specimen at
        // size 75 and never larger.
        const float k = std::min((w - 2) / wide, (h - 2) / tall), by = most > 0.f ? std::min(k, most / 100.f) : k;
        t->scale(by);
        t->translate((w - wide * by) / 2 - x * by, (h - tall * by) / 2 - y * by);
        drew = canvas->target(px.data(), w, w, h, tvg::ColorSpace::ABGR8888) == tvg::Result::Success && canvas->add(t) == tvg::Result::Success && canvas->draw(true) == tvg::Result::Success && canvas->sync() == tvg::Result::Success;
    } else tvg::Paint::rel(t);
    delete canvas;
    tvg::Text::unload(font);
    if (!drew) return 0;
    // The text is white and premultiplied, so any channel is the coverage.
    for (size_t i = 0; i < px.size(); ++i) grey[i] = (unsigned char)(px[i] & 0xFF);
    return 1;
}
