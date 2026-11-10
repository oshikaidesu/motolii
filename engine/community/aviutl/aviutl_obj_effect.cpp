#include "community/aviutl/aviutl_obj_effect.h"

#include <filament/Texture.h>

#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <functional>
#include <lua.hpp>
#include <map>
#include <sstream>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

#include "base/json.h"
#include "community/aviutl/aviutl.h"
#include "community/aviutl/aviutl_fx.h"
#include "community/quickjs/script.h"
#include "gpu/screen_interop.h"
#include "shelf/shelf_folders.h"
#include "stage/effects/screen_fx.h"
#include "stage/render/render_stage.h"

using namespace filament;

namespace {

// AviUtl's built-in effects as remade by Sashimono Edit (MIT). Their ISF files
// and the way their parameters are converted are listed in
// effects/sources/sashimono_aviutl.json, which from_sashimono.py writes from
// Sashimono's compat/aviutl/mapping.py. The list is read once. A remade effect:
// the ISF file, and for each AviUtl parameter name three strings. The first is
// the parameter's name in the ISF file. The second says how the number is
// converted: flip, rest, quarter, byte_percent, or anything else for no
// conversion. The third is a second ISF parameter that receives the same value,
// or empty.
struct AviutlRemade {
  std::string file;
  std::map<std::string, std::array<std::string, 3>> params;
};
// Returns the remade effects by AviUtl effect name, read on first use. The
// table is empty if the JSON file is missing or invalid.
const std::map<std::string, AviutlRemade>& aviutl_remakes() {
  static const std::map<std::string, AviutlRemade> all = [] {
    std::map<std::string, AviutlRemade> read;
    const std::filesystem::path dir = doc_folders("effects").front();
    std::ifstream in(dir / "sources" / "sashimono_aviutl.json");
    std::stringstream text;
    text << in.rdbuf();
    rapidjson::Document d;
    if (d.Parse(text.str().c_str()).HasParseError() || !d.IsObject())
      return read;
    for (const auto& e : d.GetObject()) {
      AviutlRemade& one = read[e.name.GetString()];
      // The file is in a folder named for what it does, such as effects/blur/
      // or effects/color/.
      one.file =
          script_shelf_file((dir / e.value["file"].GetString()).string());
      for (const auto& p : e.value["params"].GetObject())
        one.params[p.name.GetString()] = {p.value[0].GetString(),
                                          p.value[1].GetString(),
                                          p.value[2].GetString()};
    }
    return read;
  }();
  return all;
}
// Applies one remade effect to the object, drawing it as a layer's ISF effect
// is drawn (screen_draw in screen_fx.h). The ISF parameters come from `said`,
// the parameters the script passed, converted as the table says: a check box
// becomes its _on parameter and a colour becomes its components. The other
// parameters take the values in the file. The object is converted to straight
// alpha before the effect and back to premultiplied alpha after it, as a
// layer's image is given to its effects. Returns 0 on success, or -1 if there
// is no remade effect of that name.
int aviutl_sashimono(lua_State* L, AviutlRun& r, const std::string& n,
                     const std::map<std::string, double>& said) {
  const auto found = aviutl_remakes().find(n);
  if (found == aviutl_remakes().end()) return -1;
  ScreenFx*& fx = r.isf[found->second.file];
  if (!fx) {
    fx = new ScreenFx;
    fx->file = found->second.file;
    std::string code;
    if (screen_read(*fx, code))
      fx->interop = interop::screen(r.s->engine, fx->file.c_str(), code.c_str(),
                                    fx->bytes, &fx->trouble, fx->textureCount,
                                    fx->layered);
  }
  if (!fx->interop)
    return aviutl_no(L, "obj.effect " + n + ": " + fx->trouble.substr(0, 300));
  std::map<std::string, double> v;
  for (const auto& [k, x] : said)
    if (const auto p = found->second.params.find(k);
        p != found->second.params.end()) {
      const std::string& how = p->second[1];
      const double y = how == "flip"           ? -x
                       : how == "rest"         ? 100 - x
                       : how == "quarter"      ? x * 90
                       : how == "byte_percent" ? x * 100 / 255
                                               : x;
      v[p->second[0]] = y;
      if (!p->second[2].empty()) v[p->second[2]] = y;
    }
  const ScreenNumbers numbers =
      [&](const std::string&, const std::string& parameter, double usual) {
        // clip_time is the script's obj.time. clip_length is effectively
        // infinite, as if the clip never ends.
        if (parameter == "clip_time") return r.s->now;
        if (parameter == "clip_length") return 1.0e9;
        if (const auto it = v.find(parameter); it != v.end()) return it->second;
        const std::string base = parameter.size() > 2
                                     ? parameter.substr(0, parameter.size() - 2)
                                     : std::string();
        if (parameter.size() > 3 &&
            parameter.compare(parameter.size() - 3, 3, "_on") == 0 &&
            v.count(parameter.substr(0, parameter.size() - 3)))
          return v[parameter.substr(0, parameter.size() - 3)] != 0 ? 1.0 : 0.0;
        if (const auto it = v.find(base);
            it != v.end() && parameter[parameter.size() - 2] == '_') {
          // A colour in AviUtl's 0xRRGGBB form. The last character of the
          // parameter name picks the component: x is red, y is green, z is
          // blue, and anything else gives alpha 1.
          const int c = (int)it->second;
          const char part = parameter.back();
          return part == 'x'   ? ((c >> 16) & 255) / 255.0
                 : part == 'y' ? ((c >> 8) & 255) / 255.0
                 : part == 'z' ? (c & 255) / 255.0
                               : 1.0;
        }
        return usual;
      };
  const AviutlBuf object = r.bufs["object"];
  const AviutlBuf& in = aviutl_buf(r, "~sashimono_in", object.w, object.h);
  // Convert to straight alpha, as a layer's effects receive its image.
  aviutl_lay(r, object, in.rt, object.w, object.h, 0, 0, 1, 1, 0, 1, 0, 0, -1,
             1, 0, 2);
  const AviutlBuf& out = aviutl_buf(r, "~sashimono_out", object.w, object.h);
  screen_draw(*r.s, r.isfStack, *fx, in.t, out.rt, numbers, object.w, object.h);
  // Convert back to premultiplied alpha, as AviUtl2's images are.
  aviutl_lay(r, out, r.bufs["object"].rt, object.w, object.h, 0, 0, 1, 1, 0, 1,
             0, 0, -1, 1, 0, 1);
  return 0;
}
// Calls a script defined in this same file by name (lua.txt, obj.effect). Each
// script is an effect, and "name@file" names a part of an @ file. The
// parameters are given by the labels they are shown with, as an alias file
// gives them. The script runs on the object in this Lua state and on these
// buffers, as AviUtl2's scripts share theirs. A parameter that is not given
// takes its usual value, and after the call each variable gets back what it
// held before. Scripts in use rely on this: the σ軸 scripts pass their "PI"
// (the text of a part, made of Lua values), Stylize_K passes its Mosaic, the
// 遅延 of どこでもバッファ by zopty passes its 入出力, and noiseTe's
// フラクタルノイズ passes its パーリンノイズ. Returns -1 if there is no such
// script in this file.
int aviutl_called(lua_State* L, AviutlRun& r, const std::string& n) {
  const size_t at = n.rfind('@');
  const std::string part = at == std::string::npos ? "" : n.substr(0, at),
                    stem = n.substr(at + 1), file = aviutl_path(r.file);
  if (const std::string mine = std::filesystem::path(file).stem().string();
      mine != stem && mine != "@" + stem)
    return -1;
  AviutlCalled& c = r.called[part];
  if (c.chunk == LUA_NOREF) {
    std::string own, all, why;
    const std::string path = file + (part.empty() ? "" : "#" + part);
    c.chunk = LUA_REFNIL;
    if (!aviutl_text(path, own, all, why) || own == r.own) return -1;
    const std::string text =
        own.rfind("\xEF\xBB\xBF", 0) == 0 ? own.substr(3) : own;
    if (luaL_loadbuffer(L, text.data(), text.size(), ("@" + n).c_str()))
      return lua_error(L);
    c.chunk = luaL_ref(L, LUA_REGISTRYINDEX), c.vars = aviutl_vars(own);
    for (const ScriptParameter& k : aviutl_parameters(path))
      c.usual[k.name] = k.usual;
  }
  if (c.chunk == LUA_REFNIL) return -1;
  const int top = lua_gettop(L);
  std::vector<std::pair<const AviutlVar*, int>> held;
  for (const AviutlVar& v : c.vars) {
    if (aviutl_old(v))
      lua_getglobal(L, "obj"), lua_pushstring(L, v.var.c_str()),
          lua_rawget(L, -2), lua_remove(L, -2);
    else
      lua_getglobal(L, v.var.c_str());
    held.emplace_back(&v, luaL_ref(L, LUA_REGISTRYINDEX));
    int said = 0;
    for (int i = 2; i < top && !said; i += 2)
      if (const std::string k = aviutl_str(L, i);
          !k.empty() && (k == v.label || k == v.var))
        said = i + 1;
    aviutl_set(
        L, v,
        [&](const std::string& k) {
          return c.usual.count(k) ? c.usual[k] : v.usual;
        },
        said);
  }
  lua_rawgeti(L, LUA_REGISTRYINDEX, c.chunk);
  const bool fell = lua_pcall(L, 0, 0, 0) != 0;
  for (const auto& [v, ref] : held) {
    lua_rawgeti(L, LUA_REGISTRYINDEX, ref),
        luaL_unref(L, LUA_REGISTRYINDEX, ref);
    if (aviutl_old(*v))
      lua_getglobal(L, "obj"), lua_insert(L, -2),
          lua_setfield(L, -2, v->var.c_str()), lua_pop(L, 1);
    else
      lua_setglobal(L, v->var.c_str());
  }
  return fell ? lua_error(L) : 0;
}

}  // namespace

void aviutl_set(lua_State* L, const AviutlVar& v,
                const std::function<double(const std::string&)>& num,
                int said) {
  const size_t lead = v.expr.find_first_not_of(" \t");
  // The first character of a --value's default gives its type: { is a table, "
  // is a string, and a digit is a number.
  const char kind = lead == std::string::npos ? 0 : v.expr[lead];
  if (said && v.kind == "check" && v.truth)
    lua_pushboolean(L, aviutl_num(L, said) != 0);
  else if (said && v.kind == "check")
    lua_pushinteger(L, aviutl_num(L, said) != 0);
  else if (said && v.kind == "value" && lua_type(L, said) == LUA_TSTRING &&
           kind == '{') {
    // An alias file writes a table value as the text inside its braces, passed
    // as a string (lua.txt, obj.effect). Wrap it in braces and evaluate it so
    // the script sees a table. A value written empty, as ペンツール writes "",
    // works too. For example, σ軸 passes "sz = { W, H
    // }, ..." to the PI parameter of リサイズσ.
    // If the text is not valid table contents, pass it through unchanged.
    if (luaL_dostring(
            L, ("return {" + std::string(lua_tostring(L, said)) + "}").c_str()))
      lua_pop(L, 1), lua_pushvalue(L, said);
  } else if (said && v.kind == "select" && lua_type(L, said) == LUA_TSTRING &&
             std::count(v.choices.begin(), v.choices.end(),
                        lua_tostring(L, said))) {
    // A choice given by its name, as an alias file writes it, for example
    // 進行モード=自動再生 in ペンツール or "単位", "Mired" in 色温度σ(Mired).
    // It is converted to the choice's number.
    lua_pushnumber(
        L, v.values[(size_t)(std::find(v.choices.begin(), v.choices.end(),
                                       lua_tostring(L, said)) -
                             v.choices.begin())]);
  } else if (said && v.kind == "value" && lua_type(L, said) == LUA_TSTRING &&
             (std::isdigit((unsigned char)kind) || kind == '-' ||
              kind == '.') &&
             lua_isnumber(L, said))
    lua_pushnumber(L, lua_tonumber(L, said));
  else if (said)
    lua_pushvalue(L, said);
  // Round to the track's step (移動単位), as AviUtl2 holds it; lua.txt says the
  // value is an integer inside. For example, the 遅延 parameter of
  // どこでもバッファ counts frames in whole numbers, so 2.5 must not index
  // bufs[3.5].
  else if (v.kind == "track")
    lua_pushnumber(L, std::round(num(v.var) / v.step) * v.step);
  else if (v.kind == "check" && v.truth)
    lua_pushboolean(L, num(v.var) != 0);
  else if (v.kind == "check")
    lua_pushinteger(L, num(v.var) != 0);
  else if (v.kind == "select")
    lua_pushnumber(
        L, v.values.empty()
               ? 0
               : v.values[(size_t)std::clamp<double>(
                     std::round(num(v.var)), 0, (double)v.values.size() - 1)]);
  else if (v.kind == "color" && v.unset && num(v.var + "_on") == 0)
    lua_pushnil(L);
  else if (v.kind == "color")
    lua_pushinteger(L, ((int)num(v.var + "_r") << 16) |
                           ((int)num(v.var + "_g") << 8) |
                           (int)num(v.var + "_b"));
  else if (luaL_dostring(L, ("return " + v.expr).c_str()))
    lua_pop(L, 1), lua_pushnil(L);
  if (aviutl_old(v))
    lua_getglobal(L, "obj"), lua_insert(L, -2),
        lua_setfield(L, -2, v.var.c_str()), lua_pop(L, 1);
  else
    lua_setglobal(L, v.var.c_str());
}
int aviutl_effect(lua_State* L) {
  AviutlRun& r = aviutl_of(L);
  const std::string n = aviutl_str(L, 1);
  std::map<std::string, double> said;
  for (int i = 2; i + 1 <= lua_gettop(L); i += 2)
    said[aviutl_str(L, i)] = aviutl_num(L, i + 1);
  const auto at = [&](const char* k, double otherwise) {
    return said.count(k) ? said[k] : otherwise;
  };
  if (n == "ぼかし" && at("範囲", 0) == 0) return 0;
  if (n == "ぼかし" && said.count("範囲") && at("縦横比", 0) == 0 &&
      at("光の強さ", 0) == 0) {
    // Blur, as in sashimono-edit's effects/builtin.py (_BLUR): a horizontal
    // pass, then a vertical pass. With サイズ固定 (fixed size) the blur reads
    // no further than the image edge, because the sampler clamps. Otherwise the
    // image first grows by the radius on each side, as far as the blur reaches
    // (pixel_reach in strokes.py).
    const double radius = std::min(at("範囲", 0), 4096.0);
    if (!(radius > 0)) return 0;
    if (!r.blur) return aviutl_no(L, "obj.effect ぼかし: " + r.trouble);
    if (at("サイズ固定", 0) == 0) {
      const double grow = std::ceil(radius);
      aviutl_copy(r, "~blur", "object");
      const AviutlBuf from = r.bufs["~blur"];
      const AviutlBuf& to =
          aviutl_buf(r, "object", (uint32_t)std::min(8192.0, from.w + 2 * grow),
                     (uint32_t)std::min(8192.0, from.h + 2 * grow));
      aviutl_lay(r, from, to.rt, to.w, to.h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1);
    }
    const AviutlBuf object = r.bufs["object"];
    const AviutlBuf& across = aviutl_buf(r, "~blur", object.w, object.h);
    for (const auto& [from, to, x] : {std::tuple{object, across, true},
                                      std::tuple{across, object, false}}) {
      const float k[4] = {x ? 1.f / from.w : 0.f, x ? 0.f : 1.f / from.h,
                          (float)radius, 0};
      const int pass = r.draws[r.blur]++;
      interop::parameters(r.s->engine, r.blur, k, sizeof k, pass);
      Texture* texture = from.t;
      interop::draw(r.s->engine, r.blur, &texture, to.rt, to.w, to.h, pass);
    }
    return 0;
  }
  if (n == "リサイズ" && at("拡大率", 100) == 100 && at("X", 100) == 100 &&
      at("Y", 100) == 100)
    return 0;
  if (n == "領域拡張" && !at("塗りつぶし", 0)) {
    // Area expansion without a fill: add transparent margins around the object.
    const double t = at("上", 0), b = at("下", 0), l = at("左", 0),
                 rt = at("右", 0);
    aviutl_copy(r, "~expand", "object");
    const AviutlBuf from = r.bufs["~expand"];
    const AviutlBuf& to =
        aviutl_buf(r, "object", (uint32_t)std::max(1.0, from.w + l + rt),
                   (uint32_t)std::max(1.0, from.h + t + b));
    aviutl_lay(r, from, to.rt, to.w, to.h, (l - rt) / 2, (t - b) / 2, 1, 1, 0,
               1, 0, 0, -1, 1);
    return 0;
  }
  if (n == "リサイズ") {
    // Resize, as in sashimono-edit objapi.py _resize. With
    // "ドット数でサイズ指定" (set size in dots), X and Y are sizes in pixels.
    // Otherwise the size is 拡大率 (scale) times X percent and Y percent.
    // "補間なし" (no interpolation) selects the nearest pixel. Each side is at
    // most MAX_FIGURE_SIZE, 4096.
    aviutl_copy(r, "~resize", "object");
    const AviutlBuf from = r.bufs["~resize"];
    const bool dots = at("ドット数でサイズ指定", 0) != 0;
    const double zoom = at("拡大率", 100) / 100,
                 w = dots ? at("X", from.w)
                          : from.w * zoom * at("X", 100) / 100,
                 h = dots ? at("Y", from.h)
                          : from.h * zoom * at("Y", 100) / 100;
    if (!std::isfinite(w) || !std::isfinite(h))
      return aviutl_no(L, "obj.effect リサイズ of no number");
    const AviutlBuf& to = aviutl_buf(
        r, "object", (uint32_t)std::clamp(std::round(w), 1.0, 4096.0),
        (uint32_t)std::clamp(std::round(h), 1.0, 4096.0));
    aviutl_lay(r, from, to.rt, to.w, to.h, 0, 0, (double)to.w / from.w,
               (double)to.h / from.h, 0, 1, 0, 0, -1,
               at("補間なし", 0) != 0 ? 1 : 0);
    return 0;
  }
  if (n == "クリッピング") {
    // Clipping, as in sashimono-edit objapi.py _clip. 上 下 左 右 (top, bottom,
    // left, right) are cut off in pixels. If everything is cut off, one clear
    // pixel remains. What is left stays where it was: ox, oy, cx and cy are
    // moved back by half the cut, unless 中心の位置を変更 (change the centre
    // position) is set.
    const double t = std::max(0.0, std::round(at("上", 0))),
                 b = std::max(0.0, std::round(at("下", 0))),
                 l = std::max(0.0, std::round(at("左", 0))),
                 rt = std::max(0.0, std::round(at("右", 0)));
    if (!std::isfinite(t + b + l + rt))
      return aviutl_no(L, "obj.effect クリッピング of no number");
    aviutl_copy(r, "~clip", "object");
    const AviutlBuf from = r.bufs["~clip"];
    const bool all = t + b >= from.h || l + rt >= from.w;
    const AviutlBuf& to =
        aviutl_buf(r, "object", all ? 1 : (uint32_t)(from.w - l - rt),
                   all ? 1 : (uint32_t)(from.h - t - b));
    if (all)
      aviutl_clear(r, to, 0, false);
    else
      aviutl_lay(r, from, to.rt, to.w, to.h, 0, 0, 1, 1, 0, 1, (l - rt) / 2,
                 (t - b) / 2, -1, 1);
    if (at("中心の位置を変更", 0) == 0) {
      lua_getglobal(L, "obj");
      const auto move = [&](const char* k, double by) {
        lua_getfield(L, -1, k);
        const double v = aviutl_num(L, -1, 0);
        lua_pop(L, 1);
        lua_pushnumber(L, v + by);
        lua_setfield(L, -2, k);
      };
      move("ox", (l - rt) / 2), move("oy", (t - b) / 2),
          move("cx", -(l - rt) / 2), move("cy", -(t - b) / 2);
      lua_pop(L, 1);
    }
    return 0;
  }
  // An effect that Sashimono Edit remakes.
  if (const auto built = aviutl_sashimono(L, r, n, said); built >= 0)
    return built;
  // Offscreen drawing (sashimono-edit objapi.py _offscreen) turns the effects
  // queued so far into the image. Here each effect is applied at once, so
  // nothing is waiting.
  if (n == "オフスクリーン描画") return 0;
  // No name: lua.txt says this means the filters after the script, which run
  // after it here anyway. YMM4-LuaScript native/worker.lua and sashimono-edit
  // objapi.py lua_effect do the same.
  if (n.empty()) return 0;
  if (const int ran = aviutl_called(L, r, n); ran >= 0) return ran;
  return aviutl_no(L, "obj.effect " + n);
}
