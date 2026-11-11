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
  interop::Program* program = nullptr;
  interop::Buffer *knobs = nullptr, *from = nullptr, *normals = nullptr;
  interop::Set* set = nullptr;
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

void thing_fx_points(Stage& s, ThingFx& e) {
  Mesh* m = e.solid;
  if (e.pointsFile.empty() || !m || !m->objects || !m->vb || m->pos.empty())
    return;
  if (!e.points) e.points = new PointsFx;
  PointsFx& p = *e.points;
  std::error_code wrong;
  const auto stamp = std::filesystem::last_write_time(e.pointsFile, wrong);
  if (p.file != e.pointsFile || p.stamp != stamp) {
    // compute_interop has no call that frees a program: the old one stays.
    p = PointsFx{};
    p.file = e.pointsFile, p.stamp = stamp;
    const interop::Kind slots[5] = {
        interop::Kind::UNIFORM, interop::Kind::STORAGE, interop::Kind::STORAGE,
        interop::Kind::STORAGE, interop::Kind::STORAGE};
    p.program = interop::program(s.engine, "points",
                                 points_text(e.pointsFile).c_str(), slots, 5);
  }
  if (!p.program) return;
  // time, then the file's own numbers in the order of its head.
  std::vector<float> knobs{(float)s.now};
  knobs.insert(knobs.end(), e.pointsKnobs.begin(), e.pointsKnobs.end());
  knobs.resize((knobs.size() + 3) / 4 * 4);
  const uint32_t knobBytes = (uint32_t)(knobs.size() * sizeof(float));
  if (!p.knobs || p.knobBytes != knobBytes)
    p.knobs = interop::buffer(s.engine, interop::Kind::UNIFORM, knobBytes),
    p.knobBytes = knobBytes, p.vb = nullptr;
  if (p.vb != m->vb) {
    p.from = interop::buffer(s.engine, interop::Kind::STORAGE,
                             m->vbRoom * 3 * (uint32_t)sizeof(float));
    p.normals = interop::buffer(s.engine, interop::Kind::STORAGE,
                                m->vbRoom * 3 * (uint32_t)sizeof(float));
    interop::Buffer* const all[5] = {
        p.knobs, p.from, interop::buffer(s.engine, m->object[2]),
        interop::buffer(s.engine, m->object[0]), p.normals};
    p.set = interop::set(s.engine, p.program, all);
    p.vb = m->vb;
  }
  const uint32_t n = (uint32_t)m->pos.size();
  interop::write(s.engine, p.from, m->pos.data(), n * 3 * sizeof(float));
  interop::write(s.engine, p.normals, m->nrm.data(), n * 3 * sizeof(float));
  interop::write(s.engine, p.knobs, knobs.data(), knobBytes);
  interop::run(s.engine, p.program, p.set, (n + 63) / 64);
}

}  // namespace motolii
