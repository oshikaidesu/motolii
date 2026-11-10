#ifndef MOTOLII_COMMUNITY_QUICKJS_SCRIPT_LEVA_H_
#define MOTOLII_COMMUNITY_QUICKJS_SCRIPT_LEVA_H_

// Reads a script's parameters written in the object form of leva (pmndrs/leva,
// MIT license, https://github.com/pmndrs/leva, revision 402a1e9d0899, license
// text in engine/third_party/leva/LICENSE) and turns them into the AviUtl2
// header lines that script.cpp already reads. The card shown to the user is
// therefore the same as for an AviUtl2 script, and isf.cpp does the same for
// the JSON of an ISF shader.
//
// The script declares one object at its top level:
//   const knobs = { count: 5, spin: true, tint: "#ff3366",
//                   way: { value: "ring", options: ["ring", "grid"] },
//                   spread: { value: 0.5, min: 0, max: 2, step: 0.01 },
//                   Advanced: folder({ ... }, { collapsed: true }) };
//
// The kind of each parameter follows from its value, as leva's plugins decide
// it: a number becomes a slider, a boolean a check box, a "#rrggbb" string a
// color, and an object with options a choice.
//
// min and max only set the range of the slider. They do not limit what the user
// may type (see document/edit/layer_edit.h). When they are not written, the
// range is the one of Houdini's FloatParmTemplate: 0 to 10 with min_is_strict
// false. The range is widened to include the current value, so that a parameter
// sitting at the end of its range can still be dragged back to that value. This
// widening is Motolii's own.
//
// The values reach each() flat, as k.name, the way leva's useControls returns
// them.
//
// The label is leva's { label } when written. Otherwise it is the key formatted
// as Godot's inspector formats a property name (String::capitalize, MIT
// license, godotengine/godot revision c51ff06e8836): "ease_in" becomes "Ease
// In" and "scaleFrom" becomes "Scale From".

#include <quickjs.h>

#include <map>
#include <string>

// JavaScript source for leva's folder() (packages/leva/src/helpers/folder.ts).
// It only marks the object as a folder. The script's runtime defines it as a
// global as well.
extern const char* leva_prelude;

// Returns the header lines for the object declared as `const knobs = { ... }`
// in src. `let` and `var` work as well. Returns "" if there is no such
// declaration or it cannot be evaluated. If trouble is not null and evaluation
// throws, it receives the exception text.
std::string leva_head(const std::string& src, std::string* trouble = nullptr);

// Sets each color on k as a "#rrggbb" string, as leva's useControls returns it
// (k.tint, for example). A color is found as three numbers named base_x, base_y
// and base_z. A base name that is already a parameter of its own is skipped.
void leva_colours(JSContext* cx, JSValue k,
                  const std::map<std::string, double>& numbers,
                  const std::map<std::string, std::string>& words);

#endif  // MOTOLII_COMMUNITY_QUICKJS_SCRIPT_LEVA_H_
