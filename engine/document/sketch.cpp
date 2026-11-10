#include "document/sketch.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <functional>
#include <iterator>
#include <map>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include <filament/Engine.h>
#include <filament/Material.h>
#include <filament/MaterialInstance.h>
#include <filament/RenderableManager.h>
#include <filament/TextureSampler.h>
#include <math/mat3.h>
#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>

#include "community/quickjs/script.h"
#include "document/relations.h"
#include "document/scripts.h"
#include "document/shown.h"
#include "document/value_at.h"
#include "shelf/shelf_folders.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/canvas/canvas_sketch.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

namespace {

// Returns shape number `i` of the sketch, fetching shapes from the script up to that number the
// first time they are needed. Fetched shapes are kept in `shapes`.
// The script returns a float array: the point, face and edge counts, then the positions, normals
// and texture coordinates of the points, then the face indices and the edge indices. A shape whose
// array is too short is left empty.
const SketchShape* doc_sketch_shape(std::vector<SketchShape>& shapes, Script& run, size_t i) {
    while (shapes.size() <= i) {
        const std::vector<uint8_t> raw = run.bytes("__mesh_shape(" + std::to_string(shapes.size()) + ")");
        SketchShape one;
        if (raw.size() >= 3 * sizeof(float)) {
            const float* f = (const float*)raw.data();
            const size_t points = (size_t)f[0], faces = (size_t)f[1], edges = (size_t)f[2];
            if (raw.size() >= (3 + points * 8 + faces * 3 + edges * 2) * sizeof(float)) {
                const float* p = f + 3, *n = p + points * 3, *u = n + points * 3, *a = u + points * 2, *e = a + faces * 3;
                one.pos.assign((const float3*)p, (const float3*)n), one.nrm.assign((const float3*)n, (const float3*)u), one.uv.assign((const float2*)u, (const float2*)a);
                for (size_t k = 0; k < faces * 3; ++k) one.idx.push_back((uint32_t)a[k]);
                for (size_t k = 0; k < edges * 2; ++k) one.edges.push_back((uint32_t)e[k]);
            }
        }
        shapes.push_back(std::move(one));
    }
    return &shapes[i];
}
// Builds a Filament material from a sketch shader. `text` is the material source that __shader_text
// in p5_mesh.h made from the sketch's shader. `names` lists the shader's uniforms, each as a name,
// a type, a count and a size.
// The source is compiled with Filament's own matc, as the render shaders are
// (gpu/filament_webgpu.sh). A real shader takes about a third of a second. The result is cached on
// disk under a hash of the source, so each distinct source is compiled once.
// If compiling fails, the error is printed and the returned paint has no material, so the shader
// draws nothing.
SketchPaint doc_sketch_paint(Stage& s, const std::string& text, const std::string& names) {
    SketchPaint paint;
    std::istringstream lines(names);
    for (SketchTold one; lines >> one.name >> one.type >> one.count >> one.size; ) paint.told.push_back(one), paint.size += one.count * one.size;
    const std::filesystem::path made = std::filesystem::temp_directory_path() / "motolii_paints";
    std::filesystem::create_directories(made);
    const std::string stem = (made / std::to_string(std::hash<std::string>{}(text))).string();
    if (!std::filesystem::exists(stem + ".filamat")) {
        std::ofstream(stem + ".mat") << text;
        const std::string matc = (doc_engine("third_party/filament_src/out/wgpu_install/bin") / "matc").string();
        if (std::system(("'" + matc + "' -a webgpu -a metal -p desktop -o '" + stem + ".filamat' '" + stem + ".mat' > '" + stem + ".log' 2>&1").c_str()) != 0) {
            std::ifstream log(stem + ".log");
            std::fprintf(stderr, "a sketch's shader did not compile: %s\n", std::string(std::istreambuf_iterator<char>(log), {}).c_str());
            return paint;
        }
    }
    const std::vector<uint8_t> bytes = load_file((stem + ".filamat").c_str());
    if (!bytes.empty()) paint.material = Material::Builder().package(bytes.data(), bytes.size()).build(*s.engine);
    return paint;
}
// Sets the shader uniform described by `one` on `look` from the floats at `v`. `one.count` is the
// array length of the uniform. Sampler uniforms are not set here.
void doc_sketch_told(MaterialInstance* look, const SketchTold& one, const float* v) {
    const char* name = one.name.c_str();
    if (one.type == "int" || one.type == "bool") {
        std::vector<int32_t> whole(v, v + one.count);
        if (one.type == "bool") look->setParameter(name, (bool)whole[0]);
        else look->setParameter(name, whole.data(), (size_t)one.count);
    } else if (one.type == "float") look->setParameter(name, v, (size_t)one.count);
    else if (one.type == "vec2") look->setParameter(name, (const float2*)v, (size_t)one.count);
    else if (one.type == "vec3") look->setParameter(name, (const float3*)v, (size_t)one.count);
    else if (one.type == "vec4") look->setParameter(name, (const float4*)v, (size_t)one.count);
    else if (one.type == "mat3") look->setParameter(name, mat3f{float3{v[0], v[1], v[2]}, float3{v[3], v[4], v[5]}, float3{v[6], v[7], v[8]}});
    else if (one.type == "mat4") { mat4f m; std::memcpy(&m, v, sizeof m); look->setParameter(name, m); }
}

}  // namespace

void doc_sketch_mesh(Doc& d, int layer, Doc::Shown& t, double now) {
    // Layout of the float array returned by __mesh_at(frame) in p5_mesh.h:
    // - Header, HEAD floats: the number of draws, of triangle corners and of line segments; the
    //   scale U from sketch units to world units; the sketch's width and height; the background
    //   color (4 floats); the number of images; the number of rows of the light table; the number
    //   of shader uses; the number of floats of shader-use data; the number of shaders.
    // - Draws, RET floats each: the shape number; a 4x4 matrix (16 floats); the fill color (4); the
    //   fill mode, where -1 means no fill and 1000 or more selects a shader use; a line number; the
    //   stroke color (4); the stroke weight; the image number.
    // - Triangle corners, TRI floats each: position (3); normal (3); color (4); fill mode; line
    //   number; image coordinates (2); image number.
    // - Line segments, SEG floats each: the two end points (6); color (4); weight; line number.
    // - The light table, 4 floats per row, passed to sketch.mat as the parameter `told`.
    // - The shader uses: the shader number, 4 floats for s_scale, then the values of that shader's
    //   uniforms.
    // Limits: past MOST vertices the rest are dropped. Past PICTURES images the rest draw as white.
    // Past WAYS shader uses the rest are drawn flat.
    // Record sizes in floats, and the limits named above.
    constexpr size_t HEAD = 15, RET = 29, TRI = 15, SEG = 12, TOLD = 720, MOST = 3000000, PICTURES = 6, WAYS = 4096;
    Stage& s = *d.stage;
    DocScript* sc = doc_script_of(d, doc_literal_word(d, layer, "script"));
    if (!sc || !sc->run || !sc->run->ok()) return;
    // The sketch's own frame number, counted at 60 frames per second.
    const double gone = doc_literal(d, layer, "begin", 0, 0), begins = doc_literal(d, layer, "start", 0, 0) - gone;
    const int frame = (int)std::lround(doc_own_time(d, layer, now, now - begins) * 60.0);
    const auto shown = doc_shown_at(d, layer, now);
    // Lighting is computed where the layer stands now, so give the material the camera position in
    // the layer's space and the layer's rotation.
    const math::double4 from = inverse(shown) * math::double4{s.camera->getPosition(), 1.0};
    const float3 eye = float3{(float)(from.x / from.w), (float)(from.y / from.w), (float)(from.z / from.w)};
    t.look->setParameter("eye", eye), t.look->setParameter("fromSketch", math::mat3f(shown.upperLeft()));
    // Strength of each line group, from the parameters named line_N, where N is the line number. A
    // group without a parameter has strength 1.
    std::map<int, float> strong;
    for (size_t i = 0; i < sc->parameters.size(); ++i)
        if (const std::string& k = sc->parameters[i].name; k.rfind("line_", 0) == 0) strong[std::atoi(k.c_str() + 5)] = (float)doc_number(d, layer, sc->names[i].c_str(), now, sc->parameters[i].usual);
    // Nothing to rebuild if the frame, the scripts, the camera position and the strengths are all
    // unchanged.
    if (t.sketchFrame == frame && t.sketchMade == doc_scripts_made(d) && length(t.sketchEye - eye) < 1e-4f && t.sketchStrong == strong) return;
    // If the scripts were reloaded, drop everything cached from the old ones.
    if (t.sketchMade != doc_scripts_made(d)) t.sketchShapes.clear(), t.sketchPics.clear(), t.sketchPaints.clear();
    t.sketchFrame = frame, t.sketchMade = doc_scripts_made(d), t.sketchEye = eye, t.sketchStrong = strong;
    const std::vector<uint8_t> raw = sc->run->bytes("__mesh_at(" + std::to_string(frame) + ")");
    if (raw.size() < HEAD * sizeof(float)) return;
    const float* f = (const float*)raw.data();
    const size_t draws = (size_t)f[0], tris = (size_t)f[1], segs = (size_t)f[2];
    const float U = f[3], wide = f[4], high = f[5];
    const size_t told = (size_t)f[11], ways = (size_t)f[12], said = (size_t)f[13], shaders = (size_t)f[14];
    // Give up if the array is shorter than its own counts say.
    if (raw.size() < (HEAD + draws * RET + tris * TRI + segs * SEG + told * 4 + said) * sizeof(float)) return;
    // Pointers to the sections of the array: background color, draws, light table and shader uses.
    const float* back = f + 6, *all = f + HEAD, *table = all + draws * RET + tris * TRI + segs * SEG, *way = table + told * 4;
    if (told) t.look->setParameter("told", (const float4*)table, std::min(told, TOLD));
    // Compile the shaders that the sketch has added since the last frame.
    for (size_t i = t.sketchPaints.size(); i < shaders; ++i) t.sketchPaints.push_back(doc_sketch_paint(s, sc->run->said("__mesh_shader(" + std::to_string(i) + ")"), sc->run->said("__mesh_shader_names(" + std::to_string(i) + ")")));
    // The material instance for each shader use, or null if it has none.
    std::vector<MaterialInstance*> worn(std::min(ways, WAYS), nullptr);
    std::map<size_t, size_t> used;
    // For each shader use: find its shader, give it a material instance, then set s_scale and the
    // uniform values. The cursor `way` then moves on to the next use.
    for (size_t i = 0; i < ways; ++i) {
        SketchPaint& paint = t.sketchPaints[(size_t)way[0]];
        if (i < WAYS && paint.material) {
            // `n` is the number of uses of this shader so far this frame. Each use gets its own
            // material instance because the uniform values differ. Instances are kept and reused
            // across frames.
            size_t& n = used[(size_t)way[0]];
            if (paint.looks.size() <= n) {
                paint.looks.push_back(paint.material->createInstance());
                // Image uniforms start as a white texture.
                for (const SketchTold& one : paint.told) if (one.type == "sampler2D") paint.looks.back()->setParameter(one.name.c_str(), white_point(s), TextureSampler());
            }
            worn[i] = paint.looks[n++];
            worn[i]->setParameter("s_scale", float4{way[1], way[2], way[3], way[4]});
            const float* v = way + 5;
            for (const SketchTold& one : paint.told) doc_sketch_told(worn[i], one, v), v += one.count * one.size;
        }
        way += 5 + paint.size;
    }
    // Load the images the sketch draws with, up to PICTURES. Each has a width, a height and wrap
    // modes for S and T as in p5's textureWrap: 0 clamp, 1 repeat, 2 mirror.
    for (size_t i = t.sketchPics.size(); i < std::min((size_t)f[10], PICTURES); ++i) {
        const std::vector<uint8_t> said = sc->run->bytes("__mesh_pic(" + std::to_string(i) + ")");
        if (said.size() < 4 * sizeof(float)) break;
        const float* p = (const float*)said.data();
        Canvas2D* pic = sketch_texture(s, sc->run.get(), (doc_engine("third_party/filament_src/assets/fonts") / "Roboto-Medium.ttf").string(), (int)i, (int)p[0], (int)p[1]);
        t.sketchPics.push_back(pic);
        if (!pic) continue;
        constexpr TextureSampler::WrapMode wraps[] = {TextureSampler::WrapMode::CLAMP_TO_EDGE, TextureSampler::WrapMode::REPEAT, TextureSampler::WrapMode::MIRRORED_REPEAT};
        TextureSampler read(TextureSampler::MinFilter::LINEAR, TextureSampler::MagFilter::LINEAR);
        read.setWrapModeS(wraps[(int)p[2]]), read.setWrapModeT(wraps[(int)p[3]]);
        t.look->setParameter(("picture" + std::to_string(i)).c_str(), pic->texture, read);
    }
    // Draw each image for this frame's time.
    for (Canvas2D* pic : t.sketchPics) if (pic) canvas_at(s, pic, (float)frame / 60.f);
    // Start the mesh again from empty.
    Mesh& m = *t.shape;
    m.pos.clear(), m.nrm.clear(), m.uv.clear(), m.uv1.clear(), m.color.clear(), m.idx.clear();
    // Index lists, one per material. Part 0 uses sketch.mat's material. Part i + 1 uses the
    // instance of shader use i, so that each use draws with its own uniform values.
    std::vector<std::vector<uint32_t>> parts(worn.size() + 1);
    // Returns the index list for a fill mode. Modes of 1000 or more name a shader use. A use
    // without a material falls back to part 0.
    const auto part = [&](float flatly) -> std::vector<uint32_t>& {
        const size_t i = flatly >= 1000.f ? (size_t)flatly - 1000 : worn.size();
        return parts[i < worn.size() && worn[i] ? i + 1 : 0];
    };
    // Strength of a line group, 1 if none was set.
    const auto power = [&](int line) { const auto k = strong.find(line); return k == strong.end() ? 1.f : k->second; };
    // Appends a vertex. The texture coordinate `uv` carries the fill mode and the image number, and
    // `uv1` carries the image coordinates.
    const auto point = [&](float3 p, float3 n, float4 c, float flatly, float2 at = {}, float pic = 0.f) { m.pos.push_back(p), m.nrm.push_back(n), m.uv.push_back(float2{flatly, pic}), m.uv1.push_back(at), m.color.push_back(c); };
    // Appends a line from `a` to `b` of width `w` as a band made of two triangles that faces the
    // camera. If the two ends coincide the band is a small square, which is how a point is drawn.
    const auto band = [&](float3 a, float3 b, float4 c, float w) {
        if (m.pos.size() + 4 > MOST) return;
        const float3 way = b - a, look = eye - a;
        float3 side = cross(way, look);
        if (length(way) < 1e-6f) side = cross(float3{0.f, 1.f, 0.f}, look);
        side = side * (0.5f * w / std::max(length(side), 1e-6f));
        const float3 along = length(way) < 1e-6f ? normalize(cross(look, side)) * (0.5f * w) : float3{0.f};
        const uint32_t o = (uint32_t)m.pos.size();
        const float3 n = normalize(look);
        point(a - side - along, n, c, 1.f), point(a + side - along, n, c, 1.f), point(b + side + along, n, c, 1.f), point(b - side + along, n, c, 1.f);
        parts[0].insert(parts[0].end(), {o, o + 1, o + 2, o, o + 2, o + 3});
    };
    // If the sketch clears with a background color, draw it as a wall at z = -40, near the far end
    // of what the world's camera sees. The camera is 6 units back and the far plane is 60 units on
    // from there (evaluate.h). The wall is scaled to be as wide from that camera as the sketch is.
    if (back[3] > 0.f) {
        const float z = -40.f, grow = (6.f - z) / 12.f, x = grow * U * wide, y = grow * U * high;
        const float4 c{back[0], back[1], back[2], back[3]};
        const uint32_t o = (uint32_t)m.pos.size();
        const float3 n{0.f, 0.f, 1.f};
        point(float3{-x, -y, z}, n, c, 1.f), point(float3{x, -y, z}, n, c, 1.f), point(float3{x, y, z}, n, c, 1.f), point(float3{-x, y, z}, n, c, 1.f);
        parts[0].insert(parts[0].end(), {o, o + 1, o + 2, o, o + 2, o + 3});
    }
    // p5's y axis points down and the world's points up. The triangle order is reversed too, so
    // that each face keeps facing the same way.
    const float3 flip{U, -U, U};
    for (size_t i = 0; i < draws; ++i) {
        const float* r = all + i * RET;
        const SketchShape* shape = doc_sketch_shape(t.sketchShapes, *sc->run, (size_t)r[0]);
        const float k = power((int)r[22]);
        if (k < 1e-4f) continue;
        mat4f e;
        std::memcpy(&e, r + 1, 16 * sizeof(float));
        e = e * mat4f::scaling(float3{k});
        const mat3f turn = transpose(inverse(e.upperLeft()));
        // Maps a point of the shape to the world by the draw's matrix, as __w in p5_mesh.h does
        // after its __view step.
        const auto seen = [&](float3 p) { const float4 q = e * float4{p, 1.f}; return q.xyz / std::max(q.w, 0.1f) * flip; };
        // Fill the shape's faces unless it has no fill or the mesh is full.
        if (r[21] >= 0.f && m.pos.size() + shape->pos.size() <= MOST) {
            const uint32_t o = (uint32_t)m.pos.size();
            std::vector<uint32_t>& into = part(r[21]);
            const float4 c{r[17], r[18], r[19], r[20]};
            for (size_t v = 0; v < shape->pos.size(); ++v) {
                const float3 n = v < shape->nrm.size() ? turn * shape->nrm[v] : float3{0.f, 0.f, 1.f};
                point(seen(shape->pos[v]), length(n) > 1e-6f ? normalize(n * float3{1.f, -1.f, 1.f}) : float3{0.f, 0.f, 1.f}, c, r[21] >= 1000.f ? 1.f : r[21], v < shape->uv.size() ? shape->uv[v] : float2{}, r[28]);
            }
            for (size_t v = 0; v + 2 < shape->idx.size(); v += 3) into.insert(into.end(), {o + shape->idx[v], o + shape->idx[v + 2], o + shape->idx[v + 1]});
        }
        // Stroke the shape's edges as bands.
        if (r[27] > 0.f)
            for (size_t v = 0; v + 1 < shape->edges.size(); v += 2) band(seen(shape->pos[shape->edges[v]]), seen(shape->pos[shape->edges[v + 1]]), float4{r[23], r[24], r[25], r[26]}, r[27] * U);
    }
    // Free triangles. The corners are taken in the order i, i + 2, i + 1 to reverse the winding
    // after the flip.
    for (size_t i = 0; i + 2 < tris && m.pos.size() + 3 <= MOST; i += 3) {
        const uint32_t o = (uint32_t)m.pos.size();
        for (const size_t v : {i, i + 2, i + 1}) {
            const float* r = all + draws * RET + v * TRI;
            const float3 n = normalize(float3{r[3], -r[4], r[5]} + float3{0.f, 0.f, 1e-6f});
            point(float3{r[0], r[1], r[2]} * flip, n, float4{r[6], r[7], r[8], r[9] * power((int)r[11])}, r[10] >= 1000.f ? 1.f : r[10], float2{r[12], r[13]}, r[14]);
        }
        std::vector<uint32_t>& into = part(all[draws * RET + i * TRI + 10]);
        into.insert(into.end(), {o, o + 1, o + 2});
    }
    // Free line segments.
    for (size_t i = 0; i < segs; ++i) {
        const float* r = all + draws * RET + tris * TRI + i * SEG;
        band(float3{r[0], r[1], r[2]} * flip, float3{r[3], r[4], r[5]} * flip, float4{r[6], r[7], r[8], r[9] * power((int)r[11])}, r[10] * U);
    }
    // A mesh cannot be empty, so draw one invisible degenerate triangle.
    if (m.pos.empty()) point(float3{0.f}, float3{0.f, 0.f, 1.f}, float4{0.f}, 1.f), point(float3{0.f}, float3{0.f, 0.f, 1.f}, float4{0.f}, 1.f), point(float3{0.f}, float3{0.f, 0.f, 1.f}, float4{0.f}, 1.f), parts[0] = {0, 1, 2};
    // Join the index lists. `ends` holds where each part ends.
    std::vector<uint32_t> ends;
    for (const std::vector<uint32_t>& one : parts) m.idx.insert(m.idx.end(), one.begin(), one.end()), ends.push_back((uint32_t)m.idx.size());
    // If there are more parts than the renderable has primitives, add primitives, with half as many
    // again to spare.
    if (ends.size() > t.sketchParts) more_parts(s, &m, t.sketchParts = ends.size() + ends.size() / 2, t.look);
    // Upload the new geometry.
    reshape(s, &m, ends);
    // Give each renderable of this mesh the material instances for parts 1 and up, and empty the
    // primitives it no longer uses.
    auto& faces = s.engine->getRenderableManager();
    for (const Stage::Renderable& made : s.renderables) {
        if (made.of != &m) continue;
        const auto at = faces.getInstance(made.thing);
        for (size_t i = 0; i < worn.size(); ++i) if (worn[i]) faces.setMaterialInstanceAt(at, i + 1, worn[i]);
        for (size_t k = ends.size(); k < t.sketchParts; ++k) faces.setGeometryAt(at, k, RenderableManager::PrimitiveType::TRIANGLES, m.vb, m.ib, 0, 0);
    }
}
