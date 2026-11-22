#ifndef MOTOLII_COMMUNITY_QUICKJS_PANEL_SCRIPT_H_
#define MOTOLII_COMMUNITY_QUICKJS_PANEL_SCRIPT_H_
// Runs JavaScript custom UI panels (shelves/panels/*.js) in a sandboxed
// QuickJS runtime without any WebView.
// 詳細: docs/design/custom_panels.md

#include <string>

namespace motolii {

// Lists discovered custom panels from bundled shelves/panels/ and user panels/,
// one per line: "name\tpath\tabout\tacts\ttone".
std::string panel_list();

// Evaluates `render(ctx)` in `source` (JSON in, JSON UI tree out).
// Returns empty string and sets `*error` on failure.
std::string panel_eval_render_source(const std::string& source,
                                     const std::string& filename,
                                     const std::string& ctx_json,
                                     std::string* error);

// Evaluates `onAction(action, ctx)` in `source` (JSON in, JSON result out).
// Returns "{}" if `onAction` is not defined, or empty string with `*error`.
std::string panel_eval_action_source(const std::string& source,
                                     const std::string& filename,
                                     const std::string& action_json,
                                     const std::string& ctx_json,
                                     std::string* error);

// File-backed variants that read `file_path` from disk on each call so edits
// hot-reload immediately.
std::string panel_eval_render(const std::string& file_path,
                              const std::string& ctx_json,
                              std::string* error);

std::string panel_eval_action(const std::string& file_path,
                              const std::string& action_json,
                              const std::string& ctx_json,
                              std::string* error);

// Resolves the custom Inspector card UI script for `effect_path`:
// 1. Sidecar `<stem>.ui.js` beside `effect_path` (works for .wgsl/.fs/.js).
// 2. Co-located `effect_path` itself when it is `.js`/`.mjs` defining
//    `renderCard(`.
// Returns empty string when the effect uses the default auto-generated card.
std::string panel_card_ui_file(const std::string& effect_path);

// Evaluates `renderCard(ctx)` (falling back to `render(ctx)`) for an effect's
// custom Inspector card body.
std::string panel_eval_card_render(const std::string& ui_file,
                                   const std::string& ctx_json,
                                   std::string* error);

// Evaluates `onCardAction(action, ctx)` (falling back to `onAction`).
std::string panel_eval_card_action(const std::string& ui_file,
                                   const std::string& action_json,
                                   const std::string& ctx_json,
                                   std::string* error);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_QUICKJS_PANEL_SCRIPT_H_
