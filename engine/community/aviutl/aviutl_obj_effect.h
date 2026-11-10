#ifndef MOTOLII_COMMUNITY_AVIUTL_AVIUTL_OBJ_EFFECT_H_
#define MOTOLII_COMMUNITY_AVIUTL_AVIUTL_OBJ_EFFECT_H_
// aviutl_obj_effect.h: obj.effect of the AviUtl adapter. It applies AviUtl's built-in effects as
// remade by Sashimono Edit, and scripts defined in the same file, called by name.
#include <functional>
#include <string>

#include <lua.hpp>

#include "community/aviutl/aviutl.h"

// Sets the script variable for parameter `v` according to its kind (lua.txt). The value comes from
// `num`, which looks up a parameter's value by name, or from the Lua value at stack index `said`
// when obj.effect passed one. The variable is a global, or a field of obj for the old --track0
// style.
void aviutl_set(lua_State* L, const AviutlVar& v, const std::function<double(const std::string&)>& num, int said = 0);
// obj.effect(name, label, value, ...) applies an effect by name. Built-in effects are done as
// sashimono-edit does them (blur, resize, area expand, clipping, offscreen drawing). Then the
// effects Sashimono Edit remakes are tried, then scripts in this file. An unknown name raises an
// error.
int aviutl_effect(lua_State* L);

#endif  // MOTOLII_COMMUNITY_AVIUTL_AVIUTL_OBJ_EFFECT_H_
