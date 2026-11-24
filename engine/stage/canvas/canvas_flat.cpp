#include "stage/canvas/canvas_flat.h"

#include <filament/TextureSampler.h>

#include "base/hash.h"
#include "gpu/gpu_interop.h"
#include "stage/canvas/canvas_edge.h"
#include "stage/canvas/canvas_renderables.h"
#include "stage/canvas/path_operations.h"
#include "stage/render/render_layers.h"

namespace motolii {

using filament::ACCURATE;
using filament::Color;
using filament::MaterialInstance;
using filament::sRGBColor;
using filament::TextureSampler;
using filament::math::float2;
using filament::math::float3;
using filament::math::float4;
using filament::math::mat4f;

namespace {

// The outline's path as ThorVG's arrays, to hand to the path operators.
struct OutlinePath {
  const tvg::PathCommand* cmds = nullptr;
  const tvg::Point* pts = nullptr;
  uint32_t cmdsCnt = 0, ptsCnt = 0;
};
OutlinePath outline_path(tvg::Shape* o) {
  OutlinePath r;
  o->path(&r.cmds, &r.cmdsCnt, &r.pts, &r.ptsCnt);
  return r;
}

// Replaces the outline's path by `c` and `p`.
void outline_put(tvg::Shape* o, const std::vector<tvg::PathCommand>& c,
                 const std::vector<tvg::Point>& p) {
  o->reset();
  o->appendPath(c.data(), (uint32_t)c.size(), p.data(), (uint32_t)p.size());
}

// Bytes held by all cached cuts, and the limit of 256 MiB.
std::atomic<size_t> cuts_held{0};
constexpr size_t cuts_most = 256ull << 20;
// Returns a hash of every input a cut depends on.
uint64_t cut_key(float3 trim, const std::array<float, 10>& bend,
                 const std::vector<PathOpStep>& steps,
                 const Canvas2D::Other& join, const Canvas2D::Other& morph,
                 const Canvas2D::Other& trace) {
  // FNV-1a over everything the cut depends on.
  uint64_t h = fnv1a64(&trim, sizeof trim);
  h = fnv1a64(bend.data(), sizeof bend, h);
  if (!steps.empty())
    h = fnv1a64(steps.data(), steps.size() * sizeof(PathOpStep), h);
  for (const Canvas2D::Other* o : {&join, &morph, &trace}) {
    h = fnv1a64(&o->how, sizeof o->how, h);
    h = fnv1a64(&o->much, sizeof o->much, h);
    h = fnv1a64(o->by.data(), o->by.size() * sizeof(tvg::PathCommand), h);
    h = fnv1a64(o->at.data(), o->at.size() * sizeof(tvg::Point), h);
  }
  return h;
}

}  // namespace

bool apply_path_steps(tvg::Shape* outShape,
                      std::vector<tvg::PathCommand> pathBy,
                      std::vector<tvg::Point> pathAt,
                      const std::vector<PathOpStep>& steps, float side,
                      float high, float fine) {
  bool lastVoxel = false;
  for (const PathOpStep& st : steps) {
    if (pathBy.empty()) break;
    std::vector<tvg::PathCommand> nextBy;
    std::vector<tvg::Point> nextAt;
    bool ok = false;
    switch (st.kind) {
      case 0:  // round
        if (st.a > 0.f)
          ok = tvg_bend_one(pathBy.data(), (uint32_t)pathBy.size(),
                            pathAt.data(), (uint32_t)pathAt.size(), 0,
                            std::clamp(st.a, 0.f, 0.5f) * side, 0.f, 0.f,
                            nextBy, nextAt);
        break;
      case 1:  // bloat
        if (st.a != 0.f)
          ok = tvg_bend_one(pathBy.data(), (uint32_t)pathBy.size(),
                            pathAt.data(), (uint32_t)pathAt.size(), 1,
                            100.f * std::clamp(st.a, -1.f, 1.f), 0.f, 0.f,
                            nextBy, nextAt);
        break;
      case 2:  // zigzag
        if (st.a != 0.f)
          ok = tvg_bend_one(pathBy.data(), (uint32_t)pathBy.size(),
                            pathAt.data(), (uint32_t)pathAt.size(), 2,
                            std::clamp(st.a, -4.f, 4.f) * high, st.b, st.c,
                            nextBy, nextAt);
        break;
      case 3:  // offset
        if (st.a != 0.f)
          ok = tvg_bend_one(pathBy.data(), (uint32_t)pathBy.size(),
                            pathAt.data(), (uint32_t)pathAt.size(), 3,
                            std::clamp(st.a, -4.f, 4.f) * high, 0.f, 0.f,
                            nextBy, nextAt);
        break;
      case 4:  // rough
        if (st.a > 0.f)
          ok = sk_rough(pathBy.data(), (uint32_t)pathBy.size(), pathAt.data(),
                        std::max(st.b, 0.005f) * high,
                        std::min(st.a, 0.5f) * high, 0, nextBy, nextAt);
        break;
      case 5:  // resample
        if (st.a >= 2.f)
          ok =
              sk_resample(pathBy.data(), (uint32_t)pathBy.size(), pathAt.data(),
                          std::min((int)st.a, 2048), nextBy, nextAt);
        break;
      case 6:  // voxel
        if (st.a > 0.f) {
          sk_voxel(pathBy.data(), (uint32_t)pathBy.size(), pathAt.data(),
                   st.a * high, nextBy, nextAt);
          pathBy = std::move(nextBy), pathAt = std::move(nextAt);
          lastVoxel = !pathBy.empty();
          continue;
        }
        break;
    }
    if (ok) {
      pathBy = std::move(nextBy), pathAt = std::move(nextAt);
      lastVoxel = false;
    }
  }
  tvg_finalize_path(outShape, pathBy.data(), (uint32_t)pathBy.size(),
                    pathAt.data(), (uint32_t)pathAt.size(),
                    lastVoxel ? 0.f : fine);
  return lastVoxel;
}

Canvas2D::Cuts::~Cuts() { cuts_held -= bytes; }

Canvas2D* flat_mesh(Stage& s, const char* form, float wide, const mat4f& place,
                    float high, float3 colour, const char* lay, float4 edge,
                    const Canvas2DFx& fx, int points, float inner,
                    float round) {
  // The path is built in a space 1024 points high; the width follows from
  // `wide`.
  const int h = 1024, w = std::max(2, (int)std::lround(1024.f * wide));
  Canvas2D* d = new Canvas2D;
  d->fx = fx, d->cutW = (float)w, d->sheetHigh = high, d->hollow = fx.hollow;
  // Inset the path by half the edge width, rounded to a whole point, as `flat`
  // does.
  const float in = std::round(
      0.5f * std::min(edge.w * (float)h, 0.5f * (float)std::min(w, h)));
  d->edgeWide = 2.f * in;
  d->outline = tvg::Shape::gen();
  // Only curves are subdivided; straight lines stay whole.
  flat_path(d, d->outline, form, w, h, in, points, inner, round,
            -(float)h / 64.f);
  d->sheet = new Mesh;
  const std::vector<uint32_t> ends = shape_cut(d, 0.f, 1.f, true);
  d->cut = true, d->wideBy = wide;
  d->wash = float4{Color::toLinear<ACCURATE>(sRGBColor{colour}), 1.f};
  d->inLight = fx.lit;
  const std::vector<MaterialInstance*> looks =
      add_parts(s, d->sheet, flat_laid(lay, fx.lit, fx.wear).c_str(),
                std::vector<mat4f>((size_t)std::max(1, fx.copies), place), ends,
                1, fx.lit, 1, 4, fx.together);
  if (looks.empty()) return nullptr;
  d->look = looks[0];
  d->edgeLook = looks.size() > 1 ? looks[1] : nullptr;
  for (MaterialInstance* look : looks)
    look->setParameter("picture", white_point(s), TextureSampler());
  d->look->setParameter("wash", d->wash);
  if (d->edgeLook)
    d->edgeLook->setParameter(
        "wash", float4{Color::toLinear<ACCURATE>(sRGBColor{edge.xyz}), 1.f});
  return d;
}

void cut_at(Stage& s, Canvas2D* d, float3 trim,
            const std::array<float, 10>& bend, Canvas2D::Other join,
            Canvas2D::Other morph, Canvas2D::Other trace,
            const std::vector<PathOpStep>& steps) {
  if (join.how < 0 || join.by.empty()) join = {};
  if (morph.much <= 0.f || morph.by.empty()) morph = {};
  if (trace.by.empty()) trace = {};
  const bool joins =
      !(join == d->joined) || !(morph == d->morphed) || !(trace == d->traced);
  if (!d->cut || !d->outline ||
      (trim == d->trimmed && bend == d->bent && steps == d->bentSteps &&
       !joins))
    return;
  const uint64_t key = cut_key(trim, bend, steps, join, morph, trace);
  if (const auto cached = d->cuts.all.find(key); cached != d->cuts.all.end()) {
    // This exact cut was made before; reuse it.
    const Canvas2D::Cut& c = cached->second;
    d->trimmed = trim, d->bent = bend, d->bentSteps = steps,
    d->bentVoxel = steps.empty() ? bend[9] > 0.f
                                 : (!steps.empty() && steps.back().kind == 6 &&
                                    steps.back().a > 0.f),
    d->joined = std::move(join), d->morphed = std::move(morph),
    d->traced = std::move(trace);
    d->outline->reset(),
        d->outline->appendPath(c.by.data(), (uint32_t)c.by.size(), c.at.data(),
                               (uint32_t)c.at.size());
    Mesh& m = *d->sheet;
    m.pos = c.pos, m.uv = c.uv, m.idx = c.idx,
    m.nrm.assign(m.pos.size(), float3{0, 0, 1});
    d->fillPoints = c.fillPoints, d->fillEnd = c.fillEnd;
    reshape(s, d->sheet, c.ends);
    return;
  }
  const bool refillTrim = !d->hollow && !(trim == d->trimmed);
  d->trimmed = trim;
  const bool rebend = bend != d->bent || steps != d->bentSteps || joins,
             refill = rebend || refillTrim;
  if (rebend) {
    d->bent = bend, d->bentSteps = steps, d->joined = join, d->morphed = morph,
    d->traced = trace;
    d->bentVoxel = false;
    const float high = d->plainHigh;
    // When tracing, the traced path replaces the shape's own path.
    const bool traces = !trace.by.empty();
    std::vector<tvg::PathCommand> pathBy = traces ? trace.by : d->plain;
    std::vector<tvg::Point> pathAt = traces ? trace.at : d->plainAt;
    if (!steps.empty()) {
      d->bentVoxel =
          apply_path_steps(d->outline, std::move(pathBy), std::move(pathAt),
                           steps, d->plainSide, high, d->fine);
    } else {
      if (bend[8] >= 2.f) {
        std::vector<tvg::PathCommand> c;
        std::vector<tvg::Point> p;
        if (sk_resample(pathBy.data(), (uint32_t)pathBy.size(), pathAt.data(),
                        std::min((int)bend[8], 2048), c, p))
          pathBy = std::move(c), pathAt = std::move(p);
      }
      tvg_bend(d->outline, pathBy.data(), (uint32_t)pathBy.size(),
               pathAt.data(), (uint32_t)pathAt.size(),
               std::clamp(bend[0], 0.f, 0.5f) * d->plainSide,
               100.f * std::clamp(bend[1], -1.f, 1.f), bend[2] * high,
               (int)std::clamp(bend[3], 0.f, 100.f), bend[4] > 0.5f,
               bend[5] * high, d->fine);
      if (bend[6] > 0.f) {
        const auto [cmds, pts, cmdsCnt, ptsCnt] = outline_path(d->outline);
        std::vector<tvg::PathCommand> c;
        std::vector<tvg::Point> p;
        if (sk_rough(cmds, cmdsCnt, pts, std::max(bend[7], 0.005f) * high,
                     std::min(bend[6], 0.5f) * high, 0, c, p))
          outline_put(d->outline, c, p);
      }
    }
    if (morph.much > 0.f) {
      // Morph toward the other path by morph.much
      // paths are walked at even steps and matched point to point.
      const auto [cmds, pts, cmdsCnt, ptsCnt] = outline_path(d->outline);
      std::vector<tvg::PathCommand> c;
      std::vector<tvg::Point> p;
      if (morph.how > 1) {
        // A blend
        // steps from this path to the other, combined into one path.
        std::vector<tvg::PathCommand> all;
        std::vector<tvg::Point> at;
        for (int k = 0; k < morph.how; ++k)
          if (sk_morph(cmds, cmdsCnt, pts, morph.by.data(),
                       (uint32_t)morph.by.size(), morph.at.data(),
                       (float)k / (float)(morph.how - 1), c, p))
            all.insert(all.end(), c.begin(), c.end()),
                at.insert(at.end(), p.begin(), p.end());
        if (!all.empty()) outline_put(d->outline, all, at);
      } else if (sk_morph(cmds, cmdsCnt, pts, morph.by.data(),
                          (uint32_t)morph.by.size(), morph.at.data(),
                          std::min(morph.much, 1.f), c, p))
        outline_put(d->outline, c, p);
      d->bentVoxel = false;
    }
    if (join.how >= 0) {
      const auto [cmds, pts, cmdsCnt, ptsCnt] = outline_path(d->outline);
      std::vector<tvg::PathCommand> c;
      std::vector<tvg::Point> p;
      sk_op(join.how, cmds, cmdsCnt, pts, join.by.data(),
            (uint32_t)join.by.size(), join.at.data(), c, p);
      if (c.empty())
        d->outline->reset();
      else
        outline_put(d->outline, c, p);
      d->bentVoxel = false;
    }
    if (steps.empty() && bend[9] > 0.f) {
      const auto [cmds, pts, cmdsCnt, ptsCnt] = outline_path(d->outline);
      std::vector<tvg::PathCommand> c;
      std::vector<tvg::Point> p;
      sk_voxel(cmds, cmdsCnt, pts, bend[9] * high, c, p);
      if (c.empty())
        d->outline->reset();
      else
        outline_put(d->outline, c, p);
      d->bentVoxel = !c.empty();
    }
  }
  const float from = std::clamp(trim.y, 0.f, 1.f) + trim.z,
              to = 1.f - std::clamp(trim.x, 0.f, 1.f) + trim.z;
  const std::vector<uint32_t> ends = shape_cut(d, from, to, refill);
  reshape(s, d->sheet, ends);
  // Remember this cut while there is room, dropping the oldest cuts of this
  // shape first.
  Canvas2D::Cut c;
  const auto [cmds, pts, cmdsCnt, ptsCnt] = outline_path(d->outline);
  const Mesh& m = *d->sheet;
  c.bytes = cmdsCnt * sizeof *cmds + ptsCnt * sizeof *pts +
            m.pos.size() * (sizeof(float3) + sizeof(float2)) +
            m.idx.size() * sizeof(uint32_t) + 128;
  while (cuts_held + c.bytes > cuts_most && !d->cuts.order.empty()) {
    const auto old = d->cuts.all.find(d->cuts.order.front());
    d->cuts.order.pop_front();
    if (old == d->cuts.all.end()) continue;
    d->cuts.bytes -= old->second.bytes, cuts_held -= old->second.bytes;
    d->cuts.all.erase(old);
  }
  if (cuts_held + c.bytes > cuts_most) return;
  c.by.assign(cmds, cmds + cmdsCnt), c.at.assign(pts, pts + ptsCnt),
      c.pos = m.pos, c.uv = m.uv, c.idx = m.idx, c.ends = ends,
      c.fillPoints = d->fillPoints, c.fillEnd = d->fillEnd;
  d->cuts.bytes += c.bytes, cuts_held += c.bytes;
  d->cuts.order.push_back(key);
  d->cuts.all.emplace(key, std::move(c));
}

Canvas2D* layer_canvas(Stage& s, const char* file, uint32_t id, float pixel,
                       float4* box) {
  if (!interop::device(s.engine)) return nullptr;
  float4 found{0.f};
  interop::on_driver(s.engine, [&] {
    // Measure the layer alone with ThorVG, at its first frame.
    tvg::Initializer::init(0);
    tvg::Animation* look = tvg::LottieAnimation::gen();
    // ThorVG builds a frame only when asked for one other than the current
    // frame, so ask for frame 1 and then frame 0.
    if (look->picture()->load(file) == tvg::Result::Success &&
        (look->frame(1.f), look->frame(0.f), true))
      if (const tvg::Paint* one = look->picture()->paint(id)) {
        tvg::Paint* copy = one->duplicate();
        copy->transform(tvg::Matrix{1, 0, 0, 0, 1, 0, 0, 0, 1});
        copy->bounds(&found.x, &found.y, &found.z, &found.w);
        tvg::Paint::rel(copy);
      }
    delete look;
  });
  s.engine->flushAndWait();
  if (found.z <= 0.f || found.w <= 0.f) return nullptr;
  *box = found;
  // Draw at least 512 points high, however small the layer is in the
  // composition.
  const float sharp = std::max(1.f, 512.f / found.w);
  return place_canvas(
      s,
      [&](Canvas2D* d, int* w, int* h) -> tvg::Paint* {
        d->source = tvg::LottieAnimation::gen();
        if (d->source->picture()->load(file) != tvg::Result::Success)
          return nullptr;
        // Ask for frame 1 first so that frame 0 is built when it is requested
        // later.
        d->source->frame(1.f);
        d->layerId = id;
        d->fit = tvg::Matrix{
            sharp, 0, -found.x * sharp, 0, sharp, -found.y * sharp, 0, 0, 1};
        *w = std::max(2, (int)std::ceil(found.z * sharp)),
        *h = std::max(2, (int)std::ceil(found.w * sharp));
        d->holder = tvg::Scene::gen();
        return d->holder;
      },
      mat4f{}, found.w* pixel, float3{-1.f}, true, nullptr);
}

std::vector<uint32_t> canvas_deep(Stage& s, Canvas2D* d) {
  std::vector<uint32_t> ids;
  tvg::LottieAnimation* film = d ? d->lottie : nullptr;
  if (!film) return ids;
  interop::on_driver(s.engine, [&] {
    auto* walk = tvg::Accessor::gen();
    walk->set(
        film->picture(),
        [&](const tvg::Paint* one, void*) {
          float n[19];
          uint32_t above = 0;
          int kind = 0;
          if (one->id &&
              film->pose(one->id, n, &above, &kind) == tvg::Result::Success &&
              kind == 1 &&
              std::find(ids.begin(), ids.end(), one->id) == ids.end())
            ids.push_back(one->id);
          return true;
        },
        nullptr);
    delete walk;
  });
  s.engine->flushAndWait();
  d->deep = ids;
  return ids;
}

void layer_at(Stage& s, Canvas2D* d, float frame) {
  if (!d || !d->source) return;
  interop::on_driver(s.engine, [d, frame] {
    d->source->frame(frame);
    d->holder->remove();
    if (const tvg::Paint* one = d->source->picture()->paint(d->layerId)) {
      tvg::Paint* copy = one->duplicate();
      copy->transform(d->fit);
      d->holder->add(copy);
    }
    canvas_redraw_now(d);
  });
}

void canvas_off(Stage& s, Canvas2D* d) {
  s.playing.erase(d);
  edge_off(s, d);
  // take_off destroys the sheet's first material with its entities. The edge's
  // is the second, and goes here: left alive, Filament still hands it the
  // pictures it was last given (the edge's, what is behind the layer) at the
  // next frame, after those are destroyed.
  filament::MaterialInstance* const edge = d->edgeLook;
  take_off(s, d->sheet);
  if (edge) {
    std::erase_if(
        s.scissors,
        [edge](const Stage::Scissor& sc) { return sc.look == edge; });
    s.engine->destroy(edge);
  }
  d->look = nullptr, d->edgeLook = nullptr;
  cache_drop(s, d);
  // ThorVG releases its texture before Filament destroys it.
  interop::on_driver(s.engine, [d] {
    delete d->canvas;
    delete d->film;
    d->canvas = nullptr, d->film = nullptr;
  });
  if (d->texture) s.engine->destroy(d->texture);
  interop::on_driver(s.engine, [d] { delete d; });
}

}  // namespace motolii
