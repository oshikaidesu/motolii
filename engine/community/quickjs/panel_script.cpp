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

int panel_interrupt(JSRuntime*, void* opaque) {
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
  divider() { return { type: "divider" }; },
  spacer(size) { return { type: "spacer", size: Number(size ?? 6) }; },
};
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
  JS_SetInterruptHandler(rt, panel_interrupt, &guard);
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
  const std::filesystem::path p(effect_path);
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
