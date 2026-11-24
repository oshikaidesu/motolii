// Automatic single-pass WGSL fusion for contiguous pointwise effects.
// Combines multiple 1-pixel-in / 1-pixel-out shaders (and optional leading
// linear->sRGB / trailing sRGB->linear tone passes) into a single GPU pass.
#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <regex>
#include <set>
#include <string>
#include <vector>

#include "gpu/screen_interop.h"
#include "stage/effects/screen_fx.h"
#include "stage/effects/screen_pool.h"

namespace motolii {

namespace {

bool is_ident(char c) { return std::isalnum((unsigned char)c) || c == '_'; }

// Replaces whole-word occurrences of `from` with `to`, skipping member names
// after `.` so struct field names are never renamed.
std::string replace_ident(const std::string& src, const std::string& from,
                          const std::string& to) {
  if (from.empty() || from == to) return src;
  std::string out;
  out.reserve(src.size() + 64);
  size_t pos = 0;
  while (true) {
    const size_t hit = src.find(from, pos);
    if (hit == std::string::npos) {
      out.append(src, pos, std::string::npos);
      break;
    }
    const bool leftOk =
        hit == 0 || (!is_ident(src[hit - 1]) && src[hit - 1] != '.');
    const size_t after = hit + from.size();
    const bool rightOk = after >= src.size() || !is_ident(src[after]);
    if (leftOk && rightOk) {
      out.append(src, pos, hit - pos);
      out.append(to);
    } else {
      out.append(src, pos, after - pos);
    }
    pos = after;
  }
  return out;
}

// Strips `@builtin(...)` and `@location(...)` attributes from a struct block
// so SkSL's FSIn/FSOut can be used as plain structs inside a fused module.
std::string strip_io_attrs(const std::string& s) {
  static const std::regex kAttr(R"(@(?:builtin|location)\s*\([^)]*\)\s*)");
  return std::regex_replace(s, kAttr, "");
}

// Removes all `diagnostic(...);` lines, `@group(...) @binding(...) var...;`
// declarations, and synthetic `frame_level`/`frame_sample` helpers before
// embedding a WGSL module into a fused shader.
std::string strip_module_header(const std::string& wgsl) {
  static const std::regex kDiag(R"(diagnostic\s*\([^)]*\)\s*;)");
  static const std::regex kBind(
      R"(@group\(\s*\d+u?\s*\)\s*@binding\(\s*\d+u?\s*\)\s*var(?:<\s*uniform\s*>)?[^;]*;)");
  static const std::regex kFrameHelper(
      R"(fn\s+frame_(?:level|sample)\s*\([^)]*\)\s*->\s*vec4(?:f|<f32>)\s*\{[^}]*\})");
  std::string out = std::regex_replace(wgsl, kDiag, "");
  out = std::regex_replace(out, kBind, "");
  return std::regex_replace(out, kFrameHelper, "");
}

// Finds the matching `}` for the `{` at `openPos`, or npos if unbalanced.
size_t find_matching_brace(const std::string& s, size_t openPos) {
  int depth = 0;
  for (size_t i = openPos; i < s.size(); ++i) {
    if (s[i] == '{')
      ++depth;
    else if (s[i] == '}' && --depth == 0)
      return i;
  }
  return std::string::npos;
}

// Collects top-level struct, fn, const, and var names declared at brace depth 0
// (excluding `main`).
std::vector<std::string> collect_top_decls(const std::string& src) {
  std::vector<std::string> names;
  std::set<std::string> seen;
  int depth = 0;
  const auto push = [&](const std::string& n) {
    if (!n.empty() && n != "main" && seen.insert(n).second) names.push_back(n);
  };
  for (size_t i = 0; i < src.size(); ++i) {
    if (src[i] == '/' && i + 1 < src.size() && src[i + 1] == '/') {
      while (i < src.size() && src[i] != '\n') ++i;
      continue;
    }
    if (src[i] == '{') {
      ++depth;
      continue;
    }
    if (src[i] == '}') {
      if (depth > 0) --depth;
      continue;
    }
    if (depth != 0) continue;
    for (const char* kw : {"struct", "fn", "const", "var"}) {
      const size_t klen = std::strlen(kw);
      if (i + klen < src.size() && src.compare(i, klen, kw) == 0 &&
          (i == 0 || !is_ident(src[i - 1])) && !is_ident(src[i + klen])) {
        size_t j = i + klen;
        // Skip optional address space on `var<private>`.
        if (kw[0] == 'v' && j < src.size() && src[j] == '<') {
          const size_t close = src.find('>', j);
          if (close != std::string::npos) j = close + 1;
        }
        while (j < src.size() && std::isspace((unsigned char)src[j])) ++j;
        const size_t start = j;
        while (j < src.size() && is_ident(src[j])) ++j;
        if (j > start) push(src.substr(start, j - start));
        i = j;
        break;
      }
    }
  }
  return names;
}

// Rewrites a single pointwise node `k` into helper definitions plus a callable
// `fn _n{k}_run(_frag: vec4<f32>, _uv: vec2<f32>) -> vec4<f32>`.
bool emit_node_wgsl(const ScreenFx& fx, size_t k, std::string& outBody,
                    std::string& outStructType) {
  std::string body = strip_module_header(fx.wgsl);
  const size_t samplePos = body.find(fx.sampleExpr);
  if (samplePos == std::string::npos) return false;
  body.replace(samplePos, fx.sampleExpr.size(), "_m_in");

  // Remove `@fragment fn main(...) { ... }` from SkSL nodes (we call
  // `_n{k}_skslMain` directly) or convert generic `@fragment fn main(...)`
  // into a plain function.
  const std::string pfx = "_n" + std::to_string(k) + "_";
  const std::regex kFragMain(R"(@fragment\s+fn\s+main\s*\()");
  std::smatch m;
  if (!std::regex_search(body, m, kFragMain)) return false;
  const size_t mStart = (size_t)m.position();
  const size_t mBrace = body.find('{', mStart);
  if (mBrace == std::string::npos) return false;
  const size_t mEnd = find_matching_brace(body, mBrace);
  if (mEnd == std::string::npos) return false;

  std::string mainWrapper;
  if (fx.pointwiseSksl) {
    body.erase(mStart, mEnd - mStart + 1);
    body = strip_io_attrs(body);
    mainWrapper = "fn " + pfx +
                  "run(_frag: vec4<f32>, _uv: vec2<f32>) -> vec4<f32> {\n"
                  "  var _in: " +
                  pfx +
                  "FSIn;\n  _in.sk_FragCoord = _frag;\n  var _out: " + pfx +
                  "FSOut;\n  " + pfx +
                  "_skslMain(_in, &_out);\n  return _out.sk_FragColor;\n}\n";
  } else {
    // Parse parameter names from `@fragment fn main(...) -> ... {`
    const std::string head = body.substr(mStart, mBrace - mStart);
    const std::string fnBody = body.substr(mBrace, mEnd - mBrace + 1);
    body.erase(mStart, mEnd - mStart + 1);
    std::smatch pf, pu;
    const std::regex kPosParam(R"(@builtin\(\s*position\s*\)\s*(\w+)\s*:)");
    const std::regex kUvParam(R"(@location\(\s*0\s*\)\s*(\w+)\s*:)");
    std::string fragName = "_unused_frag", uvName = "_unused_uv";
    if (std::regex_search(head, pf, kPosParam)) fragName = pf[1];
    if (std::regex_search(head, pu, kUvParam)) uvName = pu[1];
    mainWrapper = "fn " + pfx + "run(" + fragName + ": vec4<f32>, " + uvName +
                  ": vec2<f32>) -> vec4<f32> " + fnBody + "\n";
  }

  // Prefix all top-level declarations (structs, fns, consts, vars) so fused
  // nodes never collide on names like `Knobs`, `effect__h4f2`, `hash`, etc.
  const std::vector<std::string> decls = collect_top_decls(body);
  for (const std::string& d : decls) {
    body = replace_ident(body, d, pfx + d);
    if (!fx.pointwiseSksl) mainWrapper = replace_ident(mainWrapper, d, pfx + d);
  }
  if (!fx.uniformVar.empty() && fx.bytes > 0) {
    const std::string fieldRef = "_m_u._n" + std::to_string(k);
    body = replace_ident(body, fx.uniformVar, fieldRef);
    mainWrapper = replace_ident(mainWrapper, fx.uniformVar, fieldRef);
    outStructType = pfx + fx.uniformStruct;
  } else {
    outStructType.clear();
  }
  outBody = body + "\n" + mainWrapper;
  return true;
}

FusedScreen* get_or_build_fused(Stage& s, ScreenFx* const* nodes, size_t count,
                                bool foldToSrgb, bool foldToLinear) {
  StageFxCache& cache = screen_cache(s);
  std::string key = foldToSrgb ? "S" : "0";
  for (size_t k = 0; k < count; ++k) key += "|" + nodes[k]->file;
  key += foldToLinear ? "|L" : "|0";

  FusedScreen& entry = cache.fused[key];
  if (entry.interop || entry.failed) return entry.interop ? &entry : nullptr;

  std::string wgsl =
      "diagnostic(off, derivative_uniformity);\n"
      "diagnostic(off, chromium.unreachable_code);\n"
      "@group(0) @binding(0) var _m_tex: texture_2d<f32>;\n"
      "@group(0) @binding(1) var _m_samp: sampler;\n"
      "var<private> _m_in: vec4<f32>;\n";

  if (foldToSrgb) {
    wgsl +=
        "fn _m_to_srgb(p: vec4<f32>) -> vec4<f32> {\n"
        "  if (p.a <= 0.0) { return vec4<f32>(0.0); }\n"
        "  let c = clamp(p.rgb / p.a, vec3<f32>(0.0), vec3<f32>(1.0));\n"
        "  let t = select(1.055 * pow(c, vec3<f32>(1.0 / 2.4)) - 0.055, c * "
        "12.92, c <= vec3<f32>(0.0031308));\n"
        "  return vec4<f32>(t * p.a, p.a);\n"
        "}\n";
  }
  if (foldToLinear) {
    wgsl +=
        "fn _m_to_linear(p: vec4<f32>) -> vec4<f32> {\n"
        "  if (p.a <= 0.0) { return vec4<f32>(0.0); }\n"
        "  let c = clamp(p.rgb / p.a, vec3<f32>(0.0), vec3<f32>(1.0));\n"
        "  let t = select(pow((c + 0.055) / 1.055, vec3<f32>(2.4)), c / 12.92, "
        "c <= vec3<f32>(0.04045));\n"
        "  return vec4<f32>(t * p.a, p.a);\n"
        "}\n";
  }

  std::string bodies;
  std::string uniformFields;
  entry.offsets.assign(count, 0u);
  entry.files.clear();
  uint32_t offset = 0;

  for (size_t k = 0; k < count; ++k) {
    std::string nodeBody, structType;
    if (!emit_node_wgsl(*nodes[k], k, nodeBody, structType)) {
      entry.failed = true;
      return nullptr;
    }
    bodies += nodeBody;
    entry.files.push_back(nodes[k]->file);
    if (!structType.empty() && nodes[k]->bytes > 0) {
      offset = (offset + 15u) & ~15u;
      entry.offsets[k] = offset;
      uniformFields +=
          "  @align(16) _n" + std::to_string(k) + ": " + structType + ",\n";
      offset += nodes[k]->bytes;
    }
  }
  entry.totalBytes = (offset + 15u) & ~15u;

  wgsl += bodies;
  if (entry.totalBytes > 0) {
    wgsl += "struct _M_U {\n" + uniformFields +
            "};\n@group(0) @binding(2) var<uniform> _m_u: _M_U;\n";
  }
  wgsl +=
      "@fragment fn main(@builtin(position) _frag: vec4<f32>, @location(0) "
      "_uv: vec2<f32>) -> @location(0) vec4<f32> {\n"
      "  var _c: vec4<f32> = textureSampleLevel(_m_tex, _m_samp, _uv, 0.0);\n";
  if (foldToSrgb) wgsl += "  _c = _m_to_srgb(_c);\n";
  for (size_t k = 0; k < count; ++k) {
    wgsl += "  _m_in = _c; _c = clamp(_n" + std::to_string(k) +
            "_run(_frag, _uv), vec4<f32>(0.0), vec4<f32>(1.0));\n";
  }
  if (foldToLinear) wgsl += "  _c = _m_to_linear(_c);\n";
  wgsl += "  return _c;\n}\n";

  std::string why;
  entry.interop = interop::screen(s.engine, "fused_fx", wgsl.c_str(),
                                  entry.totalBytes, &why, 1, 0);
  if (!entry.interop) {
    std::fprintf(stderr, "fused fx fallback (%zu nodes): %s\n", count,
                 why.c_str());
    entry.failed = true;
    return nullptr;
  }
  return &entry;
}

}  // namespace

void screen_analyze_pointwise(ScreenFx& fx, const std::string& wgsl) {
  fx.pointwise = false;
  fx.pointwiseSksl = false;
  fx.preservesZeroAlpha = false;
  fx.usesTime = false;
  fx.spillKind = ScreenFx::SpillKind::Unbounded;
  fx.spillField = -1;
  fx.spillScale = 1.f;
  fx.spillBase = 0.f;
  fx.spillCap = 0.f;
  fx.bypassField = -1;
  fx.bypassBelow = 0.f;
  fx.sampleExpr.clear();

  // Determine whether the shader body outside struct declarations actually
  // reads any time/frame uniform member (many shaders declare `@auto time` in
  // their uniform struct without referencing it).
  {
    static const std::regex kStructBlock(R"(struct\s+\w+\s*\{[^}]*\})");
    const std::string body = std::regex_replace(wgsl, kStructBlock, "");
    for (const ScreenFx::Field& f : fx.fields) {
      if (f.kind == ScreenFx::FieldKind::Time ||
          f.kind == ScreenFx::FieldKind::ClipTime ||
          f.kind == ScreenFx::FieldKind::Frame) {
        const std::string needle = "." + f.name;
        size_t pos = 0;
        while ((pos = body.find(needle, pos)) != std::string::npos) {
          const size_t after = pos + needle.size();
          if (after >= body.size() || !is_ident(body[after])) {
            fx.usesTime = true;
            break;
          }
          pos = after;
        }
        if (fx.usesTime) break;
      }
    }
  }

  // Classify bounded spill behavior and zero-strength bypass.
  // Explicit author directives (`// --pad:...`, `// --bypass:<param>`) take
  // priority so any custom WGSL/ISF/TSL shader can opt in with one line.
  const auto find_param_field = [&](const char* name) -> int {
    for (size_t i = 0; i < fx.fields.size(); ++i)
      if (fx.fields[i].kind == ScreenFx::FieldKind::Param &&
          fx.fields[i].floats == 1 && fx.fields[i].name == name)
        return (int)i;
    return -1;
  };
  if (!fx.bypassParam.empty()) {
    const int idx = find_param_field(fx.bypassParam.c_str());
    if (idx >= 0) fx.bypassField = idx, fx.bypassBelow = 0.f;
  }
  if (!fx.padSpec.empty()) {
    // Supported forms: "0", "<px>", "<param>", "<param>*<scale>+<base>:<cap>"
    std::string spec = fx.padSpec;
    float cap = 0.f;
    if (const size_t colon = spec.find(':'); colon != std::string::npos) {
      cap = (float)std::atof(spec.c_str() + colon + 1);
      spec.resize(colon);
    }
    char* endNum = nullptr;
    const double fixed = std::strtod(spec.c_str(), &endNum);
    if (endNum && *endNum == '\0') {
      if (fixed <= 0.0) {
        fx.spillKind = ScreenFx::SpillKind::Zero;
        fx.preservesZeroAlpha = true;
      } else {
        fx.spillKind = ScreenFx::SpillKind::FixedPx;
        fx.spillBase = (float)fixed;
        fx.spillCap = cap;
      }
    } else {
      float scale = 1.f, base = 0.f;
      std::string pname = spec;
      if (const size_t plus = pname.find('+'); plus != std::string::npos) {
        base = (float)std::atof(pname.c_str() + plus + 1);
        pname.resize(plus);
      }
      if (const size_t mul = pname.find('*'); mul != std::string::npos) {
        scale = (float)std::atof(pname.c_str() + mul + 1);
        pname.resize(mul);
      }
      const int idx = find_param_field(pname.c_str());
      if (idx >= 0) {
        fx.spillKind = ScreenFx::SpillKind::ParamPx;
        fx.spillField = idx;
        fx.spillScale = scale;
        fx.spillBase = base;
        fx.spillCap = cap;
      }
    }
  }
  if (!fx.spill && !fx.alpha && !fx.source && fx.historyFrames == 0 &&
      fx.others.empty() && fx.layered == 0) {
    // 1. Non-pointwise SkSL/WGSL filters that strictly early-return 0 on
    //    alpha == 0 and premultiply output by center alpha (e.g. denoise).
    if (fx.spillKind == ScreenFx::SpillKind::Unbounded && !fx.hasFrameRect &&
        fx.passes.empty() && fx.textureCount == 1 &&
        wgsl.find("invert_alpha") == std::string::npos) {
      static const std::regex kEarlyZeroFilter(
          R"(if\s*\(?[\w\.]+\s*<=?\s*(?:0\.0|0\.001|1e-0?[456])(?:\s*\)\s*\|\|\s*\([^)]*\))?\s*\)?\s*\{\s*(?:\{\s*)?return\s+vec4(?:f|<f32>)\(0(?:\.0)?\))");
      static const std::regex kPremulReturn(
          R"(return\s+vec4(?:f|<f32>)\([^;]*\*\s*(\w+\.[wa])\s*,\s*\1\s*\))");
      if (std::regex_search(wgsl, kEarlyZeroFilter) &&
          std::regex_search(wgsl, kPremulReturn)) {
        fx.preservesZeroAlpha = true;
        fx.spillKind = ScreenFx::SpillKind::Zero;
      }
    }
    // 2. Bounded-length SkSL directional blur (samples within blurLength px).
    if (fx.spillKind == ScreenFx::SpillKind::Unbounded && !fx.hasFrameRect &&
        fx.passes.empty() && fx.textureCount == 1) {
      if (const int idx = find_param_field("blurLength");
          idx >= 0 && wgsl.find("_uniform0.blurLength") != std::string::npos &&
          wgsl.find("/ _uniform0.resolution") != std::string::npos) {
        fx.spillKind = ScreenFx::SpillKind::ParamPx;
        fx.spillField = idx;
        fx.spillScale = 1.f;
        fx.spillBase = 0.f;
        fx.spillCap = 0.f;
        if (fx.bypassField < 0) fx.bypassField = idx, fx.bypassBelow = 0.f;
      }
    }
    // 3. Sashimono separable 1D-tap blur / glow ISF shaders (taps clamped to
    //    min(param, 96.0) pixels).
    if (fx.spillKind == ScreenFx::SpillKind::Unbounded && fx.hasFrameRect) {
      for (const char* pname : {"radius", "blur"}) {
        const int idx = find_param_field(pname);
        if (idx >= 0 && wgsl.find(std::string("min(v.") + pname + ", 96.0f)") !=
                            std::string::npos) {
          fx.spillKind = ScreenFx::SpillKind::ParamPx;
          fx.spillField = idx;
          fx.spillScale = 1.f;
          fx.spillBase = 0.f;
          fx.spillCap = 96.f;
          if (fx.bypassField < 0) {
            if (const int inten = find_param_field("intensity"); inten >= 0)
              fx.bypassField = inten, fx.bypassBelow = 0.f;
            else
              fx.bypassField = idx, fx.bypassBelow = 0.499f;
          }
          break;
        }
      }
    }
    // 4. Multi-pass pyramid Gaussian / Fast blur ISF shaders whose texOffsets
    //    are clamped to [0, 1] of frameRect (worst-case spread <= 5*blurAmount
    //    + 8 px, capped at 128 px).
    if (fx.spillKind == ScreenFx::SpillKind::Unbounded && fx.hasFrameRect &&
        !fx.passes.empty()) {
      if (const int idx = find_param_field("blurAmount");
          idx >= 0 && wgsl.find("blurRadiusInPixels") != std::string::npos &&
          wgsl.find("halfSizeBaseRender") != std::string::npos &&
          wgsl.find("clamp(") != std::string::npos) {
        fx.spillKind = ScreenFx::SpillKind::ParamPx;
        fx.spillField = idx;
        fx.spillScale = 5.f;
        fx.spillBase = 8.f;
        fx.spillCap = 128.f;
        if (fx.bypassField < 0 && find_param_field("intensity") < 0)
          fx.bypassField = idx, fx.bypassBelow = 0.f;
      }
    }
  }

  if (!fx.passes.empty() || fx.historyFrames != 0 || !fx.others.empty() ||
      fx.textureCount != 1 || fx.source || fx.layered != 0)
    return;
  // Disallow any non-pointwise texture intrinsic.
  static const std::regex kForbidden(
      R"(\btexture(?:Load|Gather|Dimensions)\s*\()");
  if (std::regex_search(wgsl, kForbidden)) return;

  // Locate uniform var + struct names if present.
  static const std::regex kUniformDecl(
      R"(var\s*<\s*uniform\s*>\s*(\w+)\s*:\s*(\w+)\s*;)");
  std::smatch um;
  if (std::regex_search(wgsl, um, kUniformDecl)) {
    fx.uniformVar = um[1];
    fx.uniformStruct = um[2];
  }

  // Count texture sample calls outside synthetic `frame_level`/`frame_sample`
  // helpers so normal user-written WGSL & TSL shaders fuse automatically too.
  const std::string scanBody = strip_module_header(wgsl);
  static const std::regex kAnySample(
      R"(\b(?:textureSample(?:Level)?|frame_(?:sample|level))\s*\()");
  int sampleCalls = 0;
  for (std::sregex_iterator it(scanBody.begin(), scanBody.end(), kAnySample),
       end;
       it != end; ++it)
    ++sampleCalls;

  static const char* const kSksl1 =
      "textureSample(image_Texture, image_Sampler, (coord + "
      "(select(vec2<f32>(0.0), _uniform0.layerRect.xy, "
      "vec2<bool>(_uniform0.layerRect.z > 0.0)))) / _uniform0.resolution)";
  static const char* const kSksl2 =
      "textureSample(image_Texture, image_Sampler, ((_stageIn.sk_FragCoord.xy "
      "- (select(vec2<f32>(0.0), _uniform0.layerRect.xy, "
      "vec2<bool>(_uniform0.layerRect.z > 0.0)))) + (select(vec2<f32>(0.0), "
      "_uniform0.layerRect.xy, vec2<bool>(_uniform0.layerRect.z > 0.0)))) / "
      "_uniform0.resolution)";

  const auto not_in_loop = [&](const std::string& src, size_t pos) {
    const size_t fnStart = src.rfind("fn ", pos);
    if (fnStart == std::string::npos) return false;
    static const std::regex kLoop(R"(\b(?:for|while|loop)\b)");
    return !std::regex_search(src.begin() + (long)fnStart,
                              src.begin() + (long)pos, kLoop);
  };

  if (sampleCalls == 1) {
    if (const size_t p1 = scanBody.find(kSksl1);
        p1 != std::string::npos && not_in_loop(scanBody, p1)) {
      fx.pointwise = true;
      fx.pointwiseSksl = true;
      fx.sampleExpr = kSksl1;
    } else if (const size_t p2 = scanBody.find(kSksl2);
               p2 != std::string::npos && not_in_loop(scanBody, p2)) {
      fx.pointwise = true;
      fx.pointwiseSksl = true;
      fx.sampleExpr = kSksl2;
    } else {
      // Match any user-written WGSL or TSL shader that samples its single
      // texture at its own UV coordinate (whether raw or rewritten by
      // screen_framed to frame_sample/frame_level).
      std::string uvName = "uv";
      {
        static const std::regex kUvDecl(
            R"(@location\(\s*0\s*\)\s*(\w+)\s*:\s*vec2(?:f|<f32>))");
        std::smatch umv;
        if (std::regex_search(scanBody, umv, kUvDecl)) {
          uvName = umv[1];
          // screen_framed renames `foo` -> `foo_on` and defines `let foo =
          // ...`.
          if (uvName.size() > 3 && uvName.ends_with("_on"))
            uvName.resize(uvName.size() - 3);
        }
      }
      const std::regex kDirectUv(
          R"(\b(?:textureSampleLevel|textureSample|frame_level|frame_sample)\s*\(\s*\w+\s*,\s*\w+\s*,\s*)" +
          uvName + R"(\s*(?:,\s*0(?:\.0)?f?\s*)?\))");
      std::smatch dm;
      if (std::regex_search(scanBody, dm, kDirectUv) &&
          not_in_loop(scanBody, (size_t)dm.position())) {
        fx.pointwise = true;
        fx.pointwiseSksl = false;
        fx.sampleExpr = dm[0];
      }
    }
  }

  // A pointwise shader that cannot emit non-zero pixels where input alpha is
  // zero (and never inverts/replaces alpha) can safely render into a tight
  // bounding texture around the layer without full-screen expansion.
  if (fx.pointwise && !fx.spill && !fx.alpha && !fx.source &&
      fx.spillKind == ScreenFx::SpillKind::Unbounded &&
      wgsl.find("invert_alpha") == std::string::npos) {
    static const std::regex kEarlyZero(
        R"(if\s*\(?[\w\.]+\s*<=?\s*(?:0\.0|0\.001|1e-0?[456])\s*\)?\s*\{\s*(?:\{\s*)?(?:return\s+(?:vec4(?:f|<f32>)\(0(?:\.0)?\)|\w+)|[\w_]+\s*=\s*vec4(?:f|<f32>)\(0(?:\.0)?\)))");
    static const std::regex kPremulOut(
        R"((?:sk_FragColor\s*=|return)\s*vec4(?:f|<f32>)\([^;]*\*\s*(_\d+_\w+\.[wa]|\w+\.[wa])\s*,\s*\1\s*\))");
    if (std::regex_search(scanBody, kEarlyZero) ||
        std::regex_search(scanBody, kPremulOut)) {
      fx.preservesZeroAlpha = true;
      fx.spillKind = ScreenFx::SpillKind::Zero;
    }
  }
}

bool screen_draw_fused(Stage& s, ScreenStack& st, ScreenFx* const* nodes,
                       size_t count, bool foldToSrgb, bool foldToLinear,
                       filament::Texture* from, filament::RenderTarget* to,
                       const ScreenNumbers& numbers, uint32_t w, uint32_t h,
                       bool over) {
  if (count == 0) return false;
  if (!w) w = (uint32_t)s.w, h = (uint32_t)s.h;
  FusedScreen* fused =
      get_or_build_fused(s, nodes, count, foldToSrgb, foldToLinear);
  if (!fused || !fused->interop) return false;

  // Pack all fused nodes' uniforms into one contiguous buffer and upload once.
  int slot = 0;
  if (fused->totalBytes > 0) {
    std::vector<float> packed(fused->totalBytes / 4, 0.f);
    for (size_t k = 0; k < count; ++k) {
      ScreenFx& fx = *nodes[k];
      std::copy(fx.source ? st.own : st.frame,
                (fx.source ? st.own : st.frame) + 4, fx.frame);
      std::copy(fx.frame, fx.frame + 4, fx.pass);
      if (fx.bytes > 0) {
        if (fx.paramBufFrame == s.frameCount && fx.paramBufW == w &&
            fx.paramBufH == h && fx.paramBufPass == 0 &&
            fx.paramBuf.size() == fx.bytes / 4) {
          std::memcpy(packed.data() + fused->offsets[k] / 4, fx.paramBuf.data(),
                      fx.bytes);
        } else {
          screen_fill_parameters(
              s, fx, numbers, packed.data() + fused->offsets[k] / 4, 0, w, h);
        }
      }
    }
    if (fused->slotFrame != s.frameCount)
      fused->slotFrame = s.frameCount, fused->nextSlot = 0;
    slot = (int)fused->nextSlot++;
    interop::parameters(s.engine, fused->interop, packed.data(),
                        fused->totalBytes, slot);
  }
  interop::draw(s.engine, fused->interop, &from, to, w, h, slot, nullptr, over);
  return true;
}

}  // namespace motolii
