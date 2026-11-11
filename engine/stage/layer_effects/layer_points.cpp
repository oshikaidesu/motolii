// A compute shader that moves the points of a layer's solid, each frame, on
// the GPU. See thing_fx_points in layer_fx.h for the file's contract.
#include <filesystem>
#include <fstream>
#include <map>
#include <sstream>

#include "gpu/compute_interop.h"
#include "stage/layer_effects/layer_fx.h"

namespace motolii {

// What a points file was built into, and the buffers of the mesh it moves.
struct PointsFx {
  std::string file;
  std::filesystem::file_time_type stamp;
  // The file's own program, and the one that makes the normals it wrote the
  // frames Filament draws with (only for a file that writes normals).
  interop::Program *program = nullptr, *frames = nullptr;
  interop::Buffer *knobs = nullptr, *from = nullptr, *normals = nullptr,
                  *normalsOut = nullptr, *tangents = nullptr;
  interop::Set *set = nullptr, *framesSet = nullptr;
  // The vertex buffer `set` was made for. A mesh that outgrows its buffers gets
  // new ones.
  filament::VertexBuffer* vb = nullptr;
  uint32_t knobBytes = 0;
};

namespace {
std::string points_text(const std::string& file) {
  std::ifstream in(file);
  std::stringstream all;
  all << in.rdbuf();
  return all.str();
}
}  // namespace

bool points_is(const std::string& file) {
  if (std::filesystem::path(file).extension() != ".wgsl") return false;
  // Asked for every file of every layer each frame: read once per change.
  static std::map<std::string, std::pair<std::filesystem::file_time_type, bool>>
      known;
  std::error_code wrong;
  const auto stamp = std::filesystem::last_write_time(file, wrong);
  auto at = known.find(file);
  if (at == known.end() || at->second.first != stamp)
    at = known
             .insert_or_assign(
                 file,
                 std::make_pair(stamp, points_text(file).find("@compute") !=
                                           std::string::npos))
             .first;
  return at->second.second;
}

namespace {
// The normals a points file wrote, made the tangent frames Filament draws
// with: what geometry::SurfaceOrientation makes of normals alone, on the GPU.
// Frisvad's basis (SurfaceOrientation.cpp frisvadTangentSpace), then
// mat3f::packTangentFrame (math/mat3.h) with matrix::extractQuat
// (math/TMatHelpers.h), line for line. A point whose normal was left at zero
// keeps the frame its shape gave it.
const char* const kFrames = R"(
@group(0) @binding(0) var<storage, read_write> normals: array<f32>;
@group(0) @binding(2) var<storage, read_write> frames: array<f32>;
@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) id: vec3u) {
  let i = id.x;
  if (3u * i + 2u >= arrayLength(&normals) || 4u * i + 3u >= arrayLength(&frames)) { return; }
  var n = vec3f(normals[3u * i], normals[3u * i + 1u], normals[3u * i + 2u]);
  let long = length(n);
  if (long == 0.0) { return; }
  n = n / long;
  var t = vec3f(-1.0, 0.0, 0.0);
  var b = vec3f(0.0, 0.0, -1.0);
  if (n.y >= -1.0 + 1.1920929e-7) {
    let a = 1.0 / (1.0 + n.y);
    let c = -n.z * n.x * a;
    t = vec3f(c, -n.z, 1.0 - n.z * n.z * a);
    b = vec3f(1.0 - n.x * n.x * a, -n.x, c);
  }
  var m = mat3x3f(t, cross(n, t), n);
  var q = vec4f(0.0);
  let trace = m[0][0] + m[1][1] + m[2][2];
  if (trace > 0.0) {
    var s = sqrt(trace + 1.0);
    q.w = 0.5 * s;
    s = 0.5 / s;
    q.x = (m[1][2] - m[2][1]) * s;
    q.y = (m[2][0] - m[0][2]) * s;
    q.z = (m[0][1] - m[1][0]) * s;
  } else {
    var a = 0;
    if (m[1][1] > m[0][0]) { a = 1; }
    if (m[2][2] > m[a][a]) { a = 2; }
    let j = (a + 1) % 3;
    let k = (j + 1) % 3;
    var s = sqrt((m[a][a] - (m[j][j] + m[k][k])) + 1.0);
    q[a] = 0.5 * s;
    if (s != 0.0) { s = 0.5 / s; }
    q.w = (m[j][k] - m[k][j]) * s;
    q[j] = (m[a][j] + m[j][a]) * s;
    q[k] = (m[a][k] + m[k][a]) * s;
  }
  q = normalize(q);
  if (q.w < 0.0) { q = -q; }
  let bias = 1.0 / 32767.0;
  if (q.w < bias) { q = vec4f(q.xyz * sqrt(1.0 - bias * bias), bias); }
  if (dot(cross(t, n), b) < 0.0) { q = -q; }
  frames[4u * i] = q.x; frames[4u * i + 1u] = q.y; frames[4u * i + 2u] = q.z; frames[4u * i + 3u] = q.w;
}
)";
}  // namespace

void thing_fx_points(Stage& s, ThingFx& e) {
  Mesh* m = e.solid;
  if (e.pointsFile.empty() || !m || !m->objects || !m->vb || m->pos.empty())
    return;
  if (!e.points) e.points = new PointsFx;
  PointsFx& p = *e.points;
  std::error_code wrong;
  const auto stamp = std::filesystem::last_write_time(e.pointsFile, wrong);
  using interop::Kind;
  if (p.file != e.pointsFile || p.stamp != stamp) {
    // compute_interop has no call that frees a program: the old one stays.
    p = PointsFx{};
    p.file = e.pointsFile, p.stamp = stamp;
    const std::string text = points_text(e.pointsFile);
    const Kind slots[7] = {Kind::UNIFORM, Kind::STORAGE, Kind::STORAGE,
                           Kind::STORAGE, Kind::STORAGE, Kind::STORAGE,
                           Kind::STORAGE};
    p.program = interop::program(s.engine, "points", text.c_str(), slots, 7);
    // Only a file that writes normals has its normals made frames.
    if (text.find("@binding(10)") != std::string::npos) {
      const Kind two[2] = {Kind::STORAGE, Kind::STORAGE};
      p.frames = interop::program(s.engine, "frames", kFrames, two, 2);
    }
  }
  if (!p.program) return;
  // time, then the file's own numbers in the order of its head.
  std::vector<float> knobs{(float)s.now};
  knobs.insert(knobs.end(), e.pointsKnobs.begin(), e.pointsKnobs.end());
  knobs.resize((knobs.size() + 3) / 4 * 4);
  const uint32_t knobBytes = (uint32_t)(knobs.size() * sizeof(float));
  if (!p.knobs || p.knobBytes != knobBytes)
    p.knobs = interop::buffer(s.engine, Kind::UNIFORM, knobBytes),
    p.knobBytes = knobBytes, p.vb = nullptr;
  const uint32_t n = (uint32_t)m->pos.size();
  if (p.vb != m->vb) {
    const uint32_t three = m->vbRoom * 3 * (uint32_t)sizeof(float);
    p.from = interop::buffer(s.engine, Kind::STORAGE, three);
    p.normals = interop::buffer(s.engine, Kind::STORAGE, three);
    p.normalsOut = interop::buffer(s.engine, Kind::STORAGE, three);
    p.tangents = interop::buffer(s.engine, Kind::STORAGE, three / 3 * 4);
    interop::Buffer* const all[7] = {p.knobs,
                                     p.from,
                                     interop::buffer(s.engine, m->object[2]),
                                     interop::buffer(s.engine, m->object[0]),
                                     p.normals,
                                     p.normalsOut,
                                     p.tangents};
    p.set = interop::set(s.engine, p.program, all);
    if (p.frames) {
      interop::Buffer* const two[2] = {p.normalsOut,
                                       interop::buffer(s.engine, m->object[1])};
      p.framesSet = interop::set(s.engine, p.frames, two);
    }
    p.vb = m->vb;
  }
  // The shape's tangents, as three.js hands them to a material (x y z, and w
  // the side its bitangent is on): the x axis of each point's frame.
  std::vector<float> tangents(n * 4);
  for (uint32_t i = 0; i < n; ++i) {
    const filament::math::quatf& q = m->quat[i];
    tangents[4 * i] = 1 - 2 * (q.y * q.y + q.z * q.z);
    tangents[4 * i + 1] = 2 * (q.x * q.y + q.w * q.z);
    tangents[4 * i + 2] = 2 * (q.x * q.z - q.w * q.y);
    tangents[4 * i + 3] = q.w < 0 ? -1.f : 1.f;
  }
  // No normal written yet: a point the file leaves alone keeps its frame.
  const std::vector<float> none(n * 3, 0.f);
  interop::write(s.engine, p.from, m->pos.data(), n * 3 * sizeof(float));
  interop::write(s.engine, p.normals, m->nrm.data(), n * 3 * sizeof(float));
  interop::write(s.engine, p.tangents, tangents.data(), n * 4 * sizeof(float));
  interop::write(s.engine, p.knobs, knobs.data(), knobBytes);
  if (p.frames)
    interop::write(s.engine, p.normalsOut, none.data(), n * 3 * sizeof(float));
  interop::run(s.engine, p.program, p.set, (n + 63) / 64);
  if (p.frames) interop::run(s.engine, p.frames, p.framesSet, (n + 63) / 64);
}

}  // namespace motolii
