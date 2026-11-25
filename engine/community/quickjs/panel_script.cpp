// Sandboxed QuickJS evaluator for JS custom UI panels (WebView-less CEP).
// 詳細: docs/design/custom_panels.md
#include "community/quickjs/panel_script.h"

#include <quickjs.h>

#include <chrono>
#include <filesystem>
#include <sstream>
#include <string>

#include "base/file_read.h"
#include "shelf/shelf_folders.h"

namespace motolii {
namespace {

constexpr size_t kPanelMemoryLimit = 16 * 1024 * 1024;
constexpr auto kPanelTimeout = std::chrono::milliseconds(500);

struct TimeoutGuard {
  std::chrono::steady_clock::time_point deadline;
  bool timed_out = false;
};

template <typename Target>
int panel_interrupt(Target*, void* opaque) {
  auto* g = static_cast<TimeoutGuard*>(opaque);
  if (std::chrono::steady_clock::now() > g->deadline) {
    g->timed_out = true;
    return 1;
  }
  return 0;
}

// Built-in declarative UI helper object injected into every panel script.
// Authors may call `ui.column(...)` etc. or return plain JSON objects directly.
const char* kPanelPrelude = R"JS(
const ui = {
  column(children, opts) { return Object.assign({ type: "column", children: children || [] }, opts); },
  row(children, opts) { return Object.assign({ type: "row", children: children || [] }, opts); },
  grid(children, opts) { return Object.assign({ type: "grid", cols: 3, children: children || [] }, opts); },
  section(title, children, opts) { return Object.assign({ type: "section", title: String(title ?? ""), open: true, children: children || [] }, opts); },
  text(text, opts) { return Object.assign({ type: "text", text: String(text ?? "") }, opts); },
  badge(text, opts) { return Object.assign({ type: "badge", text: String(text ?? "") }, opts); },
  meter(value, opts) { return Object.assign({ type: "meter", value: Number(value ?? 0) }, opts); },
  swatch(color, opts) { return Object.assign({ type: "swatch", color: String(color ?? "#ffffff") }, opts); },
  button(label, id, opts) { return Object.assign({ type: "button", label: String(label ?? ""), id: String(id ?? label ?? "") }, opts); },
  toggle(label, value, opts) { return Object.assign({ type: "toggle", label: String(label ?? ""), value: !!value }, opts); },
  slider(label, value, opts) { return Object.assign({ type: "slider", label: String(label ?? ""), value: Number(value ?? 0) }, opts); },
  number(label, value, opts) { return Object.assign({ type: "number", label: String(label ?? ""), value: Number(value ?? 0) }, opts); },
  select(label, value, options, opts) { return Object.assign({ type: "select", label: String(label ?? ""), value: String(value ?? ""), options: options || [] }, opts); },
  input(label, value, opts) { return Object.assign({ type: "input", label: String(label ?? ""), value: String(value ?? "") }, opts); },
  color(label, value, opts) { return Object.assign({ type: "color", label: String(label ?? ""), value: String(value ?? "#ffffff") }, opts); },
  xy(label, x, y, opts) { return Object.assign({ type: "xy", label: String(label ?? ""), x: Number(x ?? 0), y: Number(y ?? 0) }, opts); },
  canvas(height, draw, opts) { return Object.assign({ type: "canvas", height: Number(height ?? 96), draw: draw || [] }, opts); },
  svg(height, svg, opts) { return Object.assign({ type: "svg", height: Number(height ?? 96), svg: String(svg ?? "") }, opts); },
  box(children, opts) { const list = Array.isArray(children) ? children : (children ? [children] : []); return Object.assign({ type: "box", children: list }, opts); },
  stack(children, opts) { return Object.assign({ type: "stack", children: children || [] }, opts); },
  knob(label, value, opts) { return Object.assign({ type: "knob", label: String(label ?? ""), value: Number(value ?? 0) }, opts); },
  image(src, opts) { return Object.assign({ type: "image", src: String(src ?? "") }, opts); },
  scene3d(height, opts) { return Object.assign({ type: "scene3d", height: Number(height ?? 120) }, opts); },
  shader(height, preset, opts) { return Object.assign({ type: "shader", height: Number(height ?? 100), preset: String(preset ?? "holo") }, opts); },
  waveform(height, samples, opts) { return Object.assign({ type: "waveform", height: Number(height ?? 72), samples: samples || [] }, opts); },
  sequencer(steps, opts) { return Object.assign({ type: "sequencer", steps: steps || [] }, opts); },
  fader(label, value, opts) { return Object.assign({ type: "fader", label: String(label ?? ""), value: Number(value ?? 0) }, opts); },
  vu(value, opts) { return Object.assign({ type: "vu", value: Number(value ?? 0) }, opts); },
  curve(height, points, opts) { return Object.assign({ type: "curve", height: Number(height ?? 92), points: points || [] }, opts); },
  gradient(stops, opts) { return Object.assign({ type: "gradient", stops: stops || [] }, opts); },
  picker(height, pins, opts) { return Object.assign({ type: "picker", height: Number(height ?? 140), pins: pins || [] }, opts); },
  divider(opts) { return Object.assign({ type: "divider" }, opts); },
  spacer(size) { return size === undefined ? { type: "spacer" } : { type: "spacer", size: Number(size) }; },
};
// Unified host facade (`layer()`, `stage`, `audio`) matching host_prelude.js
// so Vism panels, Vism cards and expressions share the same vocabulary.
(function (g) {
  function C() { return g.__vismCtx || {}; }
  function allRaw() {
    const c = C();
    if (Array.isArray(c.layers) && c.layers.length) return c.layers;
    return c.layer ? [c.layer] : [];
  }
  function findRaw(ref) {
    const list = allRaw();
    const c = C();
    if (ref === undefined || ref === null) {
      if (c.layer) return c.layer;
      const sel = Array.isArray(c.selected) && c.selected.length ? c.selected[0] : 0;
      return sel ? list.find((l) => l && l.id === sel) || null : list[0] || null;
    }
    if (typeof ref === "number") return list.find((l) => l && l.id === (ref | 0)) || null;
    if (typeof ref === "string") return list.find((l) => l && l.name === ref) || null;
    if (typeof ref === "object" && typeof ref.id === "number") return list.find((l) => l && l.id === (ref.id | 0)) || null;
    return null;
  }
  function wrapLayer(raw) {
    if (!raw) {
      return {
        id: 0, exists: false, name: "", kind: "", text: "", index: 0,
        parent: null, children: [], start: 0, duration: -1,
        x: 0, y: 0, z: 0, pos: [0, 0, 0], size: 1,
        scaleX: 1, scaleY: 1, scaleZ: 1, scale: [1, 1, 1], anchor: [0, 0, 0],
        rotate: 0, rotateX: 0, rotateY: 0, opacity: 1, bounds: null,
        visible: false, selected: false, fill: "",
        at() { return this; }, copy() { return this; },
        get(p, fb) { return fb === undefined ? 0 : fb; }, word() { return ""; },
        keys() { return []; }, fx(e, p, fb) { return fb === undefined ? 0 : fb; },
        toWorld() { return [NaN, NaN, NaN]; }, fromWorld() { return [NaN, NaN]; },
        sample() { return [0, 0, 0, 0]; },
      };
    }
    const list = allRaw();
    const num = (k, fb) => (typeof raw[k] === "number" ? raw[k] : fb);
    const sx = num("scale_x", 1), sy = num("scale_y", 1), sz = num("scale_z", 1);
    const ax = num("anchor_x", 0), ay = num("anchor_y", 0), az = num("anchor_z", 0);
    const w = num("width", 0), h = num("height", 0);
    return {
      id: raw.id | 0,
      exists: true,
      name: String(raw.name || ""),
      kind: String(raw.kind || ""),
      text: String(raw.text || ""),
      index: list.indexOf(raw) + 1,
      get parent() {
        const pid = num("parent", 0) | 0;
        return pid > 0 ? wrapLayer(list.find((l) => l && l.id === pid) || null) : null;
      },
      get children() {
        const id = raw.id | 0;
        return list.filter((l) => l && (l.parent | 0) === id).map(wrapLayer);
      },
      start: num("start", 0),
      duration: num("duration", -1),
      x: num("x", 0), y: num("y", 0), z: num("z", 0),
      pos: [num("x", 0), num("y", 0), num("z", 0)],
      size: num("size", 1),
      scaleX: sx, scaleY: sy, scaleZ: sz, scale: [sx, sy, sz],
      anchor: [ax, ay, az],
      rotate: num("rotate", 0), rotateX: num("rotate_x", 0), rotateY: num("rotate_y", 0),
      opacity: num("opacity", 1),
      bounds: w > 0 || h > 0 ? { x: num("x", 0), y: num("y", 0), width: w, height: h, left: -w * 0.5, top: -h * 0.5, rotate: num("rotate", 0), halfX: w * 0.5, halfY: h * 0.5, px: 1 } : null,
      visible: raw.visible !== false,
      selected: !!raw.selected,
      fill: String(raw.fill || ""),
      at() { return this; },
      copy() { return this; },
      get(prop, fb) { return typeof raw[prop] === "number" ? raw[prop] : (fb === undefined ? 0 : fb); },
      word(prop) { return raw[prop] === undefined || raw[prop] === null ? "" : String(raw[prop]); },
      keys() { return []; },
      fx(e, p, fb) {
        const params = C().params || {};
        if (typeof params[p] === "number") return params[p];
        return fb === undefined ? 0 : fb;
      },
      toWorld() { return [NaN, NaN, NaN]; },
      fromWorld() { return [NaN, NaN]; },
      sample() { return [0, 0, 0, 0]; },
    };
  }
  function calcBands() {
    const a = Array.isArray(C().audio) ? C().audio : [];
    if (!a.length) return { bass: 0, lowMid: 0, highMid: 0, treble: 0, rms: 0 };
    const slice = (s, e) => {
      let sum = 0, peak = 0, cnt = 0;
      for (let i = s; i < e && i < a.length; i++) {
        const v = Number(a[i]) || 0;
        sum += v; if (v > peak) peak = v; cnt++;
      }
      return cnt ? Math.min(1, Math.max(0, 0.6 * (sum / cnt) + 0.4 * peak)) : 0;
    };
    const n = a.length;
    const b0 = slice(0, Math.max(1, Math.round(n * 0.2)));
    const b1 = slice(Math.round(n * 0.2), Math.round(n * 0.45));
    const b2 = slice(Math.round(n * 0.45), Math.round(n * 0.75));
    const b3 = slice(Math.round(n * 0.75), n);
    const rms = Math.min(1, 0.4 * b0 + 0.2 * b1 + 0.2 * b2 + 0.2 * b3);
    return { bass: b0, lowMid: b1, highMid: b2, treble: b3, rms };
  }
  const audioFn = function () { return audioFn; };
  for (const k of ["bass", "lowMid", "highMid", "treble", "rms"]) {
    Object.defineProperty(audioFn, k, { get() { return calcBands()[k]; }, enumerable: true });
  }
  Object.defineProperty(audioFn, "waveform", { get() { return Array.isArray(C().waveform) ? C().waveform : []; }, enumerable: true });
  Object.defineProperty(audioFn, "strikes", { get() { return Array.isArray(C().strikes) ? C().strikes : []; }, enumerable: true });
  audioFn.bands = () => calcBands();
  audioFn.at = () => audioFn;
  audioFn.spectrum = (out) => {
    const src = Array.isArray(C().audio) ? C().audio : [];
    const buf = out || new Uint8Array(src.length || 24);
    for (let i = 0; i < buf.length && i < src.length; i++) {
      buf[i] = buf instanceof Float32Array ? -100 + 70 * (Number(src[i]) || 0) : Math.round(255 * Math.min(1, Math.max(0, Number(src[i]) || 0)));
    }
    return buf;
  };
  audioFn.wave = (out) => {
    const src = Array.isArray(C().waveform) ? C().waveform : [];
    const buf = out || new Float32Array(src.length || 64);
    for (let i = 0; i < buf.length && i < src.length; i++) buf[i] = Number(src[i]) || 0;
    return buf;
  };
  g.layer = function (ref) { return wrapLayer(findRaw(ref)); };
  g.audio = audioFn;
  g.stage = {
    get time() { return Number(C().time) || 0; },
    get fps() { return Number(C().fps) > 0 ? Number(C().fps) : 60; },
    get frame() { return typeof C().frame === "number" ? C().frame : this.time * this.fps; },
    get width() { return (C().comp && C().comp.width) || 1920; },
    get height() { return (C().comp && C().comp.height) || 1080; },
    get duration() { return Number(C().duration) || 0; },
    get px() { return (C().comp && C().comp.point) || 1; },
    get bpm() { return Number(C().bpm) || 0; },
    get bpmFrom() { return Number(C().bpm_from) || 0; },
    get beat() { const b = this.bpm; return b > 0 ? (this.time - this.bpmFrom) * b / 60 : 0; },
    get layers() { return allRaw().map(wrapLayer); },
    get self() { return wrapLayer(findRaw(undefined)); },
    get selected() {
      const ids = new Set(Array.isArray(C().selected) ? C().selected : []);
      return allRaw().filter((l) => l && ids.has(l.id)).map(wrapLayer);
    },
    get marks() { return Array.isArray(C().marks) ? C().marks : []; },
    camera() { return { eye: [0, 0, 6], look: [0, 0, 0], up: [0, 1, 0], fov: 30, distance: 1, id: 0 }; },
    toScreen() { return [NaN, NaN]; },
    get(p, fb) { return typeof C()[p] === "number" ? C()[p] : (fb === undefined ? 0 : fb); },
    word(p) { return C()[p] === undefined || C()[p] === null ? "" : String(C()[p]); },
  };
})(globalThis);
)JS";

std::string js_exception_string(JSContext* cx, bool timed_out) {
  if (timed_out) return "Panel script timed out (>500ms)";
  JSValue exc = JS_GetException(cx);
  std::string msg = "Panel script error";
  if (const char* s = JS_ToCString(cx, exc)) {
    msg = s;
    JS_FreeCString(cx, s);
  }
  JSValue stack = JS_GetPropertyStr(cx, exc, "stack");
  if (!JS_IsUndefined(stack) && !JS_IsNull(stack)) {
    if (const char* st = JS_ToCString(cx, stack)) {
      if (st[0] != '\0') msg += std::string("\n") + st;
      JS_FreeCString(cx, st);
    }
  }
  JS_FreeValue(cx, stack);
  JS_FreeValue(cx, exc);
  return msg;
}

std::string eval_panel_call(const std::string& source,
                            const std::string& filename, const char* fn_name,
                            const char* fallback_fn,
                            const std::string* action_json,
                            const std::string& ctx_json, std::string* error) {
  JSRuntime* rt = JS_NewRuntime();
  JS_SetMemoryLimit(rt, kPanelMemoryLimit);
  TimeoutGuard guard{std::chrono::steady_clock::now() + kPanelTimeout, false};
  JS_SetInterruptHandler(rt, static_cast<JSInterruptHandler*>(&panel_interrupt),
                         &guard);
  JSContext* cx = JS_NewContext(rt);

  auto fail = [&](const std::string& msg) -> std::string {
    if (error) *error = msg;
    JS_FreeContext(cx);
    JS_FreeRuntime(rt);
    return "";
  };

  // Inject declarative `ui` helpers.
  JSValue pre = JS_Eval(cx, kPanelPrelude, std::strlen(kPanelPrelude),
                        "<panel_ui>", JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(pre)) {
    JS_FreeValue(cx, pre);
    return fail(js_exception_string(cx, guard.timed_out));
  }
  JS_FreeValue(cx, pre);

  // Evaluate user's panel script.
  JSValue loaded = JS_Eval(cx, source.c_str(), source.size(), filename.c_str(),
                           JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(loaded)) {
    JS_FreeValue(cx, loaded);
    return fail(js_exception_string(cx, guard.timed_out));
  }
  JS_FreeValue(cx, loaded);

  JSValue global = JS_GetGlobalObject(cx);
  JSValue fn = JS_GetPropertyStr(cx, global, fn_name);
  if (!JS_IsFunction(cx, fn) && fallback_fn != nullptr) {
    JS_FreeValue(cx, fn);
    fn = JS_GetPropertyStr(cx, global, fallback_fn);
  }
  if (!JS_IsFunction(cx, fn)) {
    JS_FreeValue(cx, fn);
    JS_FreeValue(cx, global);
    if (action_json != nullptr) {
      JS_FreeContext(cx);
      JS_FreeRuntime(rt);
      return "{}";
    }
    return fail(std::string("Missing function `") + fn_name + "(ctx)`");
  }

  const std::string ctx_str = ctx_json.empty() ? "{}" : ctx_json;
  JSValue ctx_val =
      JS_ParseJSON(cx, ctx_str.c_str(), ctx_str.size(), "<ctx.json>");
  if (JS_IsException(ctx_val)) {
    JS_FreeValue(cx, ctx_val);
    JS_FreeValue(cx, fn);
    JS_FreeValue(cx, global);
    return fail(js_exception_string(cx, guard.timed_out));
  }

  JS_SetPropertyStr(cx, global, "__vismCtx", JS_DupValue(cx, ctx_val));

  JSValue result = JS_UNDEFINED;
  if (action_json != nullptr) {
    const std::string act_str = action_json->empty() ? "{}" : *action_json;
    JSValue act_val =
        JS_ParseJSON(cx, act_str.c_str(), act_str.size(), "<action.json>");
    if (JS_IsException(act_val)) {
      JS_FreeValue(cx, act_val);
      JS_FreeValue(cx, ctx_val);
      JS_FreeValue(cx, fn);
      JS_FreeValue(cx, global);
      return fail(js_exception_string(cx, guard.timed_out));
    }
    JSValue argv[2] = {act_val, ctx_val};
    result = JS_Call(cx, fn, global, 2, argv);
    JS_FreeValue(cx, act_val);
  } else {
    JSValue argv[1] = {ctx_val};
    result = JS_Call(cx, fn, global, 1, argv);
  }
  JS_FreeValue(cx, ctx_val);
  JS_FreeValue(cx, fn);
  JS_FreeValue(cx, global);

  if (JS_IsException(result)) {
    JS_FreeValue(cx, result);
    return fail(js_exception_string(cx, guard.timed_out));
  }

  std::string out = "{}";
  if (!JS_IsUndefined(result) && !JS_IsNull(result)) {
    JSValue json = JS_JSONStringify(cx, result, JS_UNDEFINED, JS_UNDEFINED);
    if (JS_IsException(json)) {
      JS_FreeValue(cx, json);
      JS_FreeValue(cx, result);
      return fail(js_exception_string(cx, guard.timed_out));
    }
    if (const char* s = JS_ToCString(cx, json)) {
      out = s;
      JS_FreeCString(cx, s);
    }
    JS_FreeValue(cx, json);
  }
  JS_FreeValue(cx, result);
  JS_FreeContext(cx);
  JS_FreeRuntime(rt);
  return out;
}

std::string sanitize_tab(std::string s) {
  for (char& c : s) {
    if (c == '\t' || c == '\r' || c == '\n') c = ' ';
  }
  const size_t a = s.find_first_not_of(' ');
  if (a == std::string::npos) return "";
  const size_t b = s.find_last_not_of(' ');
  return s.substr(a, b - a + 1);
}

void read_panel_meta(const std::filesystem::path& path, std::string& title,
                     std::string& about, std::string& acts, std::string& tone) {
  title = path.stem().string();
  about.clear();
  acts = "Panel";
  tone = "accent";
  const std::string src = read_text(path);
  std::istringstream in(src);
  std::string line;
  for (int i = 0; i < 24 && std::getline(in, line); ++i) {
    const size_t s = line.find_first_not_of(" \t");
    if (s == std::string::npos) continue;
    if (line.compare(s, 2, "//") != 0) break;
    std::string body = sanitize_tab(line.substr(s + 2));
    auto take = [&](const char* key, std::string& dst) {
      const size_t klen = std::strlen(key);
      if (body.compare(0, klen, key) == 0) {
        const std::string val = sanitize_tab(body.substr(klen));
        if (!val.empty()) dst = val;
      }
    };
    take("--title:", title);
    take("--about:", about);
    take("--acts:", acts);
    take("--tone:", tone);
  }
}

}  // namespace

std::string panel_list() {
  std::string out;
  for (const auto& path : doc_folder_files("panels", ".js")) {
    std::string title, about, acts, tone;
    read_panel_meta(path, title, about, acts, tone);
    if (!out.empty()) out += '\n';
    out += sanitize_tab(title) + '\t' + path.generic_string() + '\t' +
           sanitize_tab(about) + '\t' + sanitize_tab(acts) + '\t' +
           sanitize_tab(tone);
  }
  return out;
}

std::string panel_eval_render_source(const std::string& source,
                                     const std::string& filename,
                                     const std::string& ctx_json,
                                     std::string* error) {
  return eval_panel_call(source, filename, "render", nullptr, nullptr, ctx_json,
                         error);
}

std::string panel_eval_action_source(const std::string& source,
                                     const std::string& filename,
                                     const std::string& action_json,
                                     const std::string& ctx_json,
                                     std::string* error) {
  return eval_panel_call(source, filename, "onAction", nullptr, &action_json,
                         ctx_json, error);
}

std::string panel_eval_render(const std::string& file_path,
                              const std::string& ctx_json, std::string* error) {
  const std::string src = read_text(file_path);
  if (src.empty()) {
    if (error) *error = "Panel file is empty or unreadable: " + file_path;
    return "";
  }
  return panel_eval_render_source(src, file_path, ctx_json, error);
}

std::string panel_eval_action(const std::string& file_path,
                              const std::string& action_json,
                              const std::string& ctx_json, std::string* error) {
  const std::string src = read_text(file_path);
  if (src.empty()) {
    if (error) *error = "Panel file is empty or unreadable: " + file_path;
    return "";
  }
  return panel_eval_action_source(src, file_path, action_json, ctx_json, error);
}

std::string panel_card_ui_file(const std::string& effect_path) {
  if (effect_path.empty()) return "";
  std::error_code ec;
  const std::filesystem::path p(resolve_shelf_path(effect_path));
  const std::filesystem::path sidecar =
      p.parent_path() / (p.stem().string() + ".ui.js");
  if (std::filesystem::is_regular_file(sidecar, ec)) {
    return sidecar.generic_string();
  }
  const std::string ext = p.extension().string();
  if ((ext == ".js" || ext == ".mjs") &&
      std::filesystem::is_regular_file(p, ec)) {
    const std::string src = read_text(p);
    if (src.find("function renderCard") != std::string::npos ||
        src.find("renderCard =") != std::string::npos ||
        src.find("renderCard=") != std::string::npos) {
      return p.generic_string();
    }
  }
  return "";
}

std::string panel_eval_card_render(const std::string& ui_file,
                                   const std::string& ctx_json,
                                   std::string* error) {
  const std::string src = read_text(ui_file);
  if (src.empty()) {
    if (error) *error = "Card UI file is empty or unreadable: " + ui_file;
    return "";
  }
  return eval_panel_call(src, ui_file, "renderCard", "render", nullptr,
                         ctx_json, error);
}

std::string panel_eval_card_action(const std::string& ui_file,
                                   const std::string& action_json,
                                   const std::string& ctx_json,
                                   std::string* error) {
  const std::string src = read_text(ui_file);
  if (src.empty()) {
    if (error) *error = "Card UI file is empty or unreadable: " + ui_file;
    return "";
  }
  return eval_panel_call(src, ui_file, "onCardAction", "onAction", &action_json,
                         ctx_json, error);
}

}  // namespace motolii
