// aviutl_obj_effect.h: part of aviutl_fx.h. Read only through aviutl_fx.h. obj.effect: AviUtl's built-in effects as Sashimono Edit remakes them, and this file's own scripts called by name.
// AviUtl's built-in effects as Sashimono Edit remakes them (MIT): their ISF files and how their params are said
// (effects/sources/sashimono_aviutl.json, written by from_sashimono.py from Sashimono's own compat/aviutl/mapping.py), read once.
static std::vector<std::filesystem::path> doc_folders(const char* folder);   // (document/layer_edit.h)
struct AviutlRemade { std::string file; std::map<std::string, std::array<std::string, 3>> params; };   // (each param: its name there, how its number is said again, a second name it also goes to)
static const std::map<std::string, AviutlRemade>& aviutl_remakes() {
    static const std::map<std::string, AviutlRemade> all = [] {
        std::map<std::string, AviutlRemade> read;
        const std::filesystem::path dir = doc_folders("effects").front();
        std::ifstream in(dir / "sources" / "sashimono_aviutl.json");
        std::stringstream text;
        text << in.rdbuf();
        rapidjson::Document d;
        if (d.Parse(text.str().c_str()).HasParseError() || !d.IsObject()) return read;
        for (const auto& e : d.GetObject()) {
            AviutlRemade& one = read[e.name.GetString()];
            one.file = script_shelf_file((dir / e.value["file"].GetString()).string());   // (in the folder of what it does: effects/blur/, effects/color/…)
            for (const auto& p : e.value["params"].GetObject()) one.params[p.name.GetString()] = {p.value[0].GetString(), p.value[1].GetString(), p.value[2].GetString()};
        }
        return read;
    }();
    return all;
}
// One of them on the object, as a thing's ISF effect is drawn (screen_fx.h screen_draw): its knobs the params said (each
// said again as Sashimono says it; a check its _on, a colour its parts), the rest as its file says; the object made
// straight for it and premultiplied again after, as the thing's picture is given to its effects. -1: none of them.
static int aviutl_sashimono(lua_State* L, AviutlRun& r, const std::string& n, const std::map<std::string, double>& said) {
    const auto found = aviutl_remakes().find(n);
    if (found == aviutl_remakes().end()) return -1;
    ScreenFx*& fx = r.isf[found->second.file];
    if (!fx) {
        fx = new ScreenFx;
        fx->file = found->second.file;
        std::string code;
        if (screen_read(*fx, code)) fx->door = door::screen(r.s->engine, fx->file.c_str(), code.c_str(), fx->bytes, &fx->trouble, fx->pictures, fx->layered);
    }
    if (!fx->door) return aviutl_no(L, "obj.effect " + n + ": " + fx->trouble.substr(0, 300));
    std::map<std::string, double> v;
    for (const auto& [k, x] : said)
        if (const auto p = found->second.params.find(k); p != found->second.params.end()) {
            const std::string& how = p->second[1];
            const double y = how == "flip" ? -x : how == "rest" ? 100 - x : how == "quarter" ? x * 90 : how == "byte_percent" ? x * 100 / 255 : x;
            v[p->second[0]] = y;
            if (!p->second[2].empty()) v[p->second[2]] = y;
        }
    const ScreenNumbers numbers = [&](const std::string&, const std::string& knob, double usual) {
        if (knob == "clip_time") return r.s->now;   // (its clock the script's obj.time; its length, none that ends)
        if (knob == "clip_length") return 1.0e9;
        if (const auto it = v.find(knob); it != v.end()) return it->second;
        const std::string base = knob.size() > 2 ? knob.substr(0, knob.size() - 2) : std::string();
        if (knob.size() > 3 && knob.compare(knob.size() - 3, 3, "_on") == 0 && v.count(knob.substr(0, knob.size() - 3))) return v[knob.substr(0, knob.size() - 3)] != 0 ? 1.0 : 0.0;
        if (const auto it = v.find(base); it != v.end() && knob[knob.size() - 2] == '_') {   // (a colour, AviUtl's 0xRRGGBB)
            const int c = (int)it->second;
            const char part = knob.back();
            return part == 'x' ? ((c >> 16) & 255) / 255.0 : part == 'y' ? ((c >> 8) & 255) / 255.0 : part == 'z' ? (c & 255) / 255.0 : 1.0;
        }
        return usual;
    };
    const AviutlBuf object = r.bufs["object"];
    const AviutlBuf& in = aviutl_buf(r, "~sashimono_in", object.w, object.h);
    aviutl_lay(r, object, in.rt, object.w, object.h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1, 0, 2);   // (straight, as a thing's effects are given its picture)
    const AviutlBuf& out = aviutl_buf(r, "~sashimono_out", object.w, object.h);
    screen_draw(*r.s, r.isfStack, *fx, in.t, out.rt, numbers, object.w, object.h);
    aviutl_lay(r, out, r.bufs["object"].rt, object.w, object.h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1, 0, 1);   // (premultiplied again, as AviUtl2's pictures are)
    return 0;
}
// A knob's value made its variable (a global, or obj's for the old --track0) as its kind is told (lua.txt): from `num`
// (a knob's value by its name), or the Lua value at `said` on the stack, as obj.effect said it.
static void aviutl_set(lua_State* L, const AviutlVar& v, const std::function<double(const std::string&)>& num, int said = 0) {
    const size_t lead = v.expr.find_first_not_of(" \t");
    const char kind = lead == std::string::npos ? 0 : v.expr[lead];   // (a --value's by its default: { a table, " a string, a digit a number)
    if (said && v.kind == "check" && v.truth) lua_pushboolean(L, aviutl_num(L, said) != 0);
    else if (said && v.kind == "check") lua_pushinteger(L, aviutl_num(L, said) != 0);
    else if (said && v.kind == "value" && lua_type(L, said) == LUA_TSTRING && kind == '{') {   // (said as an alias file writes it (lua.txt obj.effect), a table its braces' inside as a string its quotes' (ペンツール's "" written empty): σ軸's "sz = { W, H }, ..." to リサイズσ's PI)
        if (luaL_dostring(L, ("return {" + std::string(lua_tostring(L, said)) + "}").c_str())) lua_pop(L, 1), lua_pushvalue(L, said);   // (not a table's inside: as it was said)
    } else if (said && v.kind == "select" && lua_type(L, said) == LUA_TSTRING && std::count(v.choices.begin(), v.choices.end(), lua_tostring(L, said))) {   // (a choice said by its name, as an alias file writes it (ペンツール's 進行モード=自動再生): 色温度σ(Mired)'s "単位", "Mired")
        lua_pushnumber(L, v.values[(size_t)(std::find(v.choices.begin(), v.choices.end(), lua_tostring(L, said)) - v.choices.begin())]);
    } else if (said && v.kind == "value" && lua_type(L, said) == LUA_TSTRING && (std::isdigit((unsigned char)kind) || kind == '-' || kind == '.') && lua_isnumber(L, said)) lua_pushnumber(L, lua_tonumber(L, said));
    else if (said) lua_pushvalue(L, said);
    else if (v.kind == "track") lua_pushnumber(L, std::round(num(v.var) / v.step) * v.step);   // (by its 移動単位, as AviUtl2 holds it (lua.txt: an integer inside): どこでもバッファ's 遅延 counts its frames by one, a 2.5 read bufs[3.5])
    else if (v.kind == "check" && v.truth) lua_pushboolean(L, num(v.var) != 0);
    else if (v.kind == "check") lua_pushinteger(L, num(v.var) != 0);
    else if (v.kind == "select") lua_pushnumber(L, v.values.empty() ? 0 : v.values[(size_t)std::clamp<double>(std::round(num(v.var)), 0, (double)v.values.size() - 1)]);
    else if (v.kind == "color" && v.unset && num(v.var + "_on") == 0) lua_pushnil(L);
    else if (v.kind == "color") lua_pushinteger(L, ((int)num(v.var + "_r") << 16) | ((int)num(v.var + "_g") << 8) | (int)num(v.var + "_b"));
    else if (luaL_dostring(L, ("return " + v.expr).c_str())) lua_pop(L, 1), lua_pushnil(L);
    if (aviutl_old(v)) lua_getglobal(L, "obj"), lua_insert(L, -2), lua_setfield(L, -2, v.var.c_str()), lua_pop(L, 1);
    else lua_setglobal(L, v.var.c_str());
}
// A script of this file by its name (lua.txt obj.effect: each script is an effect, "name@file" a part of an @ file, its
// knobs said by the names they are shown by, as an alias file says them): run on the object here, in this Lua and on
// these buffers, as AviUtl2's scripts share theirs; a knob not said as it comes, and its variable given back what it
// held after. As σ軸's scripts hand their "PI" (a part's own text of Lua values) and Stylize_K's its Mosaic, zopty's
// どこでもバッファ 遅延 its 入出力, noiseTe's フラクタルノイズ its パーリンノイズ. -1: no such script in this file.
static int aviutl_called(lua_State* L, AviutlRun& r, const std::string& n) {
    const size_t at = n.rfind('@');
    const std::string part = at == std::string::npos ? "" : n.substr(0, at), stem = n.substr(at + 1), file = aviutl_path(r.file);
    if (const std::string mine = std::filesystem::path(file).stem().string(); mine != stem && mine != "@" + stem) return -1;
    AviutlCalled& c = r.called[part];
    if (c.chunk == LUA_NOREF) {
        std::string own, all, why;
        const std::string path = file + (part.empty() ? "" : "#" + part);
        c.chunk = LUA_REFNIL;
        if (!aviutl_text(path, own, all, why) || own == r.own) return -1;
        const std::string text = own.rfind("\xEF\xBB\xBF", 0) == 0 ? own.substr(3) : own;
        if (luaL_loadbuffer(L, text.data(), text.size(), ("@" + n).c_str())) return lua_error(L);
        c.chunk = luaL_ref(L, LUA_REGISTRYINDEX), c.vars = aviutl_vars(own);
        for (const ScriptKnob& k : aviutl_knobs(path)) c.usual[k.name] = k.usual;
    }
    if (c.chunk == LUA_REFNIL) return -1;
    const int top = lua_gettop(L);
    std::vector<std::pair<const AviutlVar*, int>> held;
    for (const AviutlVar& v : c.vars) {
        if (aviutl_old(v)) lua_getglobal(L, "obj"), lua_pushstring(L, v.var.c_str()), lua_rawget(L, -2), lua_remove(L, -2);
        else lua_getglobal(L, v.var.c_str());
        held.emplace_back(&v, luaL_ref(L, LUA_REGISTRYINDEX));
        int said = 0;
        for (int i = 2; i < top && !said; i += 2)
            if (const std::string k = aviutl_str(L, i); !k.empty() && (k == v.label || k == v.var)) said = i + 1;
        aviutl_set(L, v, [&](const std::string& k) { return c.usual.count(k) ? c.usual[k] : v.usual; }, said);
    }
    lua_rawgeti(L, LUA_REGISTRYINDEX, c.chunk);
    const bool fell = lua_pcall(L, 0, 0, 0) != 0;
    for (const auto& [v, ref] : held) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, ref), luaL_unref(L, LUA_REGISTRYINDEX, ref);
        if (aviutl_old(*v)) lua_getglobal(L, "obj"), lua_insert(L, -2), lua_setfield(L, -2, v->var.c_str()), lua_pop(L, 1);
        else lua_setglobal(L, v->var.c_str());
    }
    return fell ? lua_error(L) : 0;
}
static int aviutl_effect(lua_State* L) {   // (a built-in effect by its name: these, as sashimono-edit makes them)
    AviutlRun& r = aviutl_of(L);
    const std::string n = aviutl_str(L, 1);
    std::map<std::string, double> said;
    for (int i = 2; i + 1 <= lua_gettop(L); i += 2) said[aviutl_str(L, i)] = aviutl_num(L, i + 1);
    const auto at = [&](const char* k, double otherwise) { return said.count(k) ? said[k] : otherwise; };
    if (n == "ぼかし" && at("範囲", 0) == 0) return 0;
    if (n == "ぼかし" && said.count("範囲") && at("縦横比", 0) == 0 && at("光の強さ", 0) == 0) {   // (sashimono-edit's blur, effects/builtin.py _BLUR: across, then down; サイズ固定 reads no further than the picture (the sampler's clamp), else the picture grows by the radius each side, as far as it reaches: strokes.py pixel_reach)
        const double radius = std::min(at("範囲", 0), 4096.0);
        if (!(radius > 0)) return 0;
        if (!r.blur) return aviutl_no(L, "obj.effect ぼかし: " + r.trouble);
        if (at("サイズ固定", 0) == 0) {
            const double grow = std::ceil(radius);
            aviutl_copy(r, "~blur", "object");
            const AviutlBuf from = r.bufs["~blur"];
            const AviutlBuf& to = aviutl_buf(r, "object", (uint32_t)std::min(8192.0, from.w + 2 * grow), (uint32_t)std::min(8192.0, from.h + 2 * grow));
            aviutl_lay(r, from, to.rt, to.w, to.h, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1);
        }
        const AviutlBuf object = r.bufs["object"];
        const AviutlBuf& across = aviutl_buf(r, "~blur", object.w, object.h);
        for (const auto& [from, to, x] : {std::tuple{object, across, true}, std::tuple{across, object, false}}) {
            const float k[4] = {x ? 1.f / from.w : 0.f, x ? 0.f : 1.f / from.h, (float)radius, 0};
            const int pass = r.draws[r.blur]++;
            door::knobs(r.s->engine, r.blur, k, sizeof k, pass);
            Texture* picture = from.t;
            door::draw(r.s->engine, r.blur, &picture, to.rt, to.w, to.h, pass);
        }
        return 0;
    }
    if (n == "リサイズ" && at("拡大率", 100) == 100 && at("X", 100) == 100 && at("Y", 100) == 100) return 0;
    if (n == "領域拡張" && !at("塗りつぶし", 0)) {   // (margins of nothing round it)
        const double t = at("上", 0), b = at("下", 0), l = at("左", 0), rt = at("右", 0);
        aviutl_copy(r, "~expand", "object");
        const AviutlBuf from = r.bufs["~expand"];
        const AviutlBuf& to = aviutl_buf(r, "object", (uint32_t)std::max(1.0, from.w + l + rt), (uint32_t)std::max(1.0, from.h + t + b));
        aviutl_lay(r, from, to.rt, to.w, to.h, (l - rt) / 2, (t - b) / 2, 1, 1, 0, 1, 0, 0, -1, 1);
        return 0;
    }
    if (n == "リサイズ") {   // (sashimono-edit objapi.py _resize: "ドット数でサイズ指定" then X, Y in pixels, else 拡大率 times X %, Y %; "補間なし" the nearest pixel; no larger than its MAX_FIGURE_SIZE, 4096)
        aviutl_copy(r, "~resize", "object");
        const AviutlBuf from = r.bufs["~resize"];
        const bool dots = at("ドット数でサイズ指定", 0) != 0;
        const double zoom = at("拡大率", 100) / 100, w = dots ? at("X", from.w) : from.w * zoom * at("X", 100) / 100, h = dots ? at("Y", from.h) : from.h * zoom * at("Y", 100) / 100;
        if (!std::isfinite(w) || !std::isfinite(h)) return aviutl_no(L, "obj.effect リサイズ of no number");
        const AviutlBuf& to = aviutl_buf(r, "object", (uint32_t)std::clamp(std::round(w), 1.0, 4096.0), (uint32_t)std::clamp(std::round(h), 1.0, 4096.0));
        aviutl_lay(r, from, to.rt, to.w, to.h, 0, 0, (double)to.w / from.w, (double)to.h / from.h, 0, 1, 0, 0, -1, at("補間なし", 0) != 0 ? 1 : 0);
        return 0;
    }
    if (n == "クリッピング") {   // (sashimono-edit objapi.py _clip: 上 下 左 右 cut off in pixels, all of it a clear pixel; what is left stays where it was, ox, oy, cx, cy moved back by half the cut, unless 中心の位置を変更)
        const double t = std::max(0.0, std::round(at("上", 0))), b = std::max(0.0, std::round(at("下", 0))), l = std::max(0.0, std::round(at("左", 0))), rt = std::max(0.0, std::round(at("右", 0)));
        if (!std::isfinite(t + b + l + rt)) return aviutl_no(L, "obj.effect クリッピング of no number");
        aviutl_copy(r, "~clip", "object");
        const AviutlBuf from = r.bufs["~clip"];
        const bool all = t + b >= from.h || l + rt >= from.w;
        const AviutlBuf& to = aviutl_buf(r, "object", all ? 1 : (uint32_t)(from.w - l - rt), all ? 1 : (uint32_t)(from.h - t - b));
        if (all) aviutl_clear(r, to, 0, false);
        else aviutl_lay(r, from, to.rt, to.w, to.h, 0, 0, 1, 1, 0, 1, (l - rt) / 2, (t - b) / 2, -1, 1);
        if (at("中心の位置を変更", 0) == 0) {
            lua_getglobal(L, "obj");
            const auto move = [&](const char* k, double by) { lua_getfield(L, -1, k); const double v = aviutl_num(L, -1, 0); lua_pop(L, 1); lua_pushnumber(L, v + by); lua_setfield(L, -2, k); };
            move("ox", (l - rt) / 2), move("oy", (t - b) / 2), move("cx", -(l - rt) / 2), move("cy", -(t - b) / 2);
            lua_pop(L, 1);
        }
        return 0;
    }
    if (const auto made = aviutl_sashimono(L, r, n, said); made >= 0) return made;   // (one Sashimono Edit remakes)
    if (n == "オフスクリーン描画") return 0;   // (sashimono-edit objapi.py _offscreen: the effects laid up so far made into the picture; here each is made at once, so none wait)
    if (n.empty()) return 0;   // (no name: lua.txt says the filters after the script, which run after it here anyway; YMM4-LuaScript native/worker.lua and sashimono-edit objapi.py lua_effect return the same)
    if (const int ran = aviutl_called(L, r, n); ran >= 0) return ran;
    return aviutl_no(L, "obj.effect " + n);
}

