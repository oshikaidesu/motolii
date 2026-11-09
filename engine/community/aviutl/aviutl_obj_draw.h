// aviutl_obj_draw.h: part of aviutl_fx.h. Read only through aviutl_fx.h. obj.draw and obj.drawpoly: a picture placed in depth on the door's mesh, and the blend and sampler it is laid with.
// Faces on the door's mesh into `to`, its middle the corners' 0, 0, y down: each four corners two triangles, 0-1-2 and
// 0-2-3 (sashimono-edit's _fill_quad, MIT), the picture `from` on them at the corners' u, v (pixels), or their colours
// (premultiplied, 0 to 1: lua.txt's, as sashimono-edit's raster.draw_triangle takes them); all of one call at once (as
// Filament draws its own triangle). Seen by AviUtl's camera as sashimono-edit's engine/gpu/projection.py has it (1024
// pixels before the screen, a point z further 1024 / (1024 + z) as large; a face with a corner at the camera or behind
// it not drawn), the GPU's own divide by w laying the picture between in perspective. Into the temporary buffer too, unlike sashimono-edit's (z left out there): GrungeConverter.anm2's maker draws it
// with z there and thresholds it after "for the edges blurred, z moved", so AviUtl2's own sees it so.
struct AviutlCorner { double x, y, z, u, v; float colour[4] = {1, 1, 1, 1}; };
static void aviutl_mesh(AviutlRun& r, const AviutlBuf& from, const AviutlBuf& to, const std::vector<std::vector<AviutlCorner>>& faces, double ox, double oy, double oz, double fade, int way, int sampler) {
    std::vector<float> corners;
    const auto corner = [&](const AviutlCorner& p) {
        const float w = (float)((1024.0 + oz + p.z) / 1024.0);
        corners.insert(corners.end(), {(float)((ox + p.x) / (to.w / 2.0)), (float)(-(oy + p.y) / (to.h / 2.0)), 0.f, w, p.colour[0], p.colour[1], p.colour[2], p.colour[3], (float)(p.u / std::max(1u, from.w)), (float)(p.v / std::max(1u, from.h))});
    };
    for (const auto& c : faces) {
        if (std::any_of(c.begin(), c.end(), [&](const AviutlCorner& p) { return 1024.0 + oz + p.z < 1.0; })) continue;
        corner(c[0]), corner(c[1]), corner(c[2]);
        if (c.size() == 4) corner(c[0]), corner(c[2]), corner(c[3]);
    }
    if (corners.empty()) return;
    const float k[4] = {(float)fade, 0, 0, 0};
    const int pass = r.draws[r.poly]++;
    door::knobs(r.s->engine, r.poly, k, sizeof k, pass);
    Texture* picture = from.t ? from.t : r.none;
    door::draw(r.s->engine, r.poly, &picture, to.rt, to.w, to.h, pass, nullptr, true, way, sampler, corners.data(), (uint32_t)(corners.size() / door::MESH_CORNER));
}
// obj.setoption "blend" as the door lays it (screen_door.h's blend), as lua.txt's words are read by sashimono-edit
// (MIT, compat/aviutl/raster.py _over): the buffers premultiplied, so "alpha_add" (colours weighed by their alphas,
// the alphas added) is what is there plus what is drawn; "alpha_sub" (colours kept, the alpha drawn taken away)
// Porter-Duff's "out", the same where either is opaque (their a_b - a_t is a_b (1 - a_t) there); "alpha_add2"
// (colours laid over, the alphas added); "screen" (AviUtl's 4) Filament's own screen; AviUtl's 3 (multiply) as
// Motolii's own sheets multiply (flat.mat), what is under taken as opaque. Others not yet: -1.
static int aviutl_way(const std::string& b) {
    if (b.empty() || b == "none" || b == "0") return 0;
    if (b == "add" || b == "1" || b == "rgba_add" || b == "alpha_add") return 1;
    if (b == "alpha_sub") return 3;
    if (b == "alpha_add2") return 4;
    if (b == "screen" || b == "4") return 5;
    if (b == "3") return 6;
    return -1;
}
static int aviutl_sampling(const AviutlRun& r) { return r.sampler == "dot" ? 1 : r.sampler == "loop" ? 2 : r.sampler == "mirror" ? 3 : 0; }
// The object put in depth, as obj.draw and the frame's own placing do with z, rx or ry: its four corners turned about
// its centre (cx, cy) by X, then Y, then Z, in degrees, and moved (sashimono-edit's engine/gpu/compositor.py
// Transform.corners and projection.py rotate: X up tipping away, Y right tipping away, Z clockwise), seen by the camera.
static void aviutl_placed(AviutlRun& r, const AviutlBuf& from, const AviutlBuf& to, double x, double y, double z, double sx, double sy, double rx, double ry, double rz, double cx, double cy, double fade, int way, int sampler) {
    std::vector<AviutlCorner> c;
    const double hw = from.w * sx / 2, hh = from.h * sy / 2;
    static const int signs[4][2] = {{-1, -1}, {1, -1}, {1, 1}, {-1, 1}};
    for (const auto& [kx, ky] : signs) {
        double px = kx * hw - cx, py = ky * hh - cy, pz = 0, cs, sn;
        if (rx) cs = std::cos(rx * M_PI / 180), sn = std::sin(rx * M_PI / 180), std::tie(py, pz) = std::pair{py * cs + pz * sn, -py * sn + pz * cs};
        if (ry) cs = std::cos(ry * M_PI / 180), sn = std::sin(ry * M_PI / 180), std::tie(px, pz) = std::pair{px * cs - pz * sn, px * sn + pz * cs};
        if (rz) cs = std::cos(rz * M_PI / 180), sn = std::sin(rz * M_PI / 180), std::tie(px, py) = std::pair{px * cs - py * sn, px * sn + py * cs};
        c.push_back({px + cx, py + cy, pz, kx > 0 ? (double)from.w : 0.0, ky > 0 ? (double)from.h : 0.0});
    }
    aviutl_mesh(r, from, to, {c}, x, y, z, fade, way, sampler);
}

static int aviutl_draw(lua_State* L) {   // (ox, oy, oz, zoom, alpha, rx, ry, rz): in depth when oz, rx or ry, the object's own added (aviutl_placed)
    AviutlRun& r = aviutl_of(L);
    const int way = aviutl_way(r.blend);
    if (way < 0) return aviutl_no(L, "obj.draw blend " + r.blend);
    lua_getglobal(L, "obj");
    const auto f = [&](const char* k, double otherwise) { lua_getfield(L, -1, k); const double v = aviutl_num(L, -1, otherwise); lua_pop(L, 1); return v; };
    // (into the frame: as the thing stands, its x and y too; into the temporary buffer not where the thing stands (lua.txt:
    //  "オブジェクトの持っている座標等の設定は反映せず"), but as the script has moved it since it began (obj.ox, rz, zoom,
    //  alpha: 0 and 1 at its start here, the thing's own laid outside it): Mathy_Su moves obj.ox, obj.rz and obj.alpha
    //  before each obj.draw() into it, its README's "配置位置でパス上の移動" and "元画像透明度" so made, and 四隅に配置 its four)
    const bool own = r.target == "framebuffer";
    const double zoom = aviutl_num(L, 4, 1) * f("zoom", 1), aspect = f("aspect", 0);
    const AviutlBuf& to = r.bufs[r.target];
    if (!to.t) return aviutl_no(L, "obj.draw into a temporary buffer never made");
    const double z = aviutl_num(L, 3) + f("oz", 0), rx = aviutl_num(L, 6) + f("rx", 0), ry = aviutl_num(L, 7) + f("ry", 0);
    if (z != 0 || rx != 0 || ry != 0) {
        if (!r.poly) return aviutl_no(L, "obj.draw in depth: " + r.trouble);
        aviutl_placed(r, r.bufs["object"], to, aviutl_num(L, 1) + (own ? f("x", 0) : 0) + f("ox", 0), aviutl_num(L, 2) + (own ? f("y", 0) : 0) + f("oy", 0), z, zoom * (aspect > 0 ? 1 - aspect : 1), zoom * (aspect < 0 ? 1 + aspect : 1), rx, ry,
            aviutl_num(L, 8) + f("rz", 0), f("cx", 0), f("cy", 0), aviutl_num(L, 5, 1) * f("alpha", 1), way, aviutl_sampling(r));
    } else aviutl_lay(r, r.bufs["object"], to.rt, to.w, to.h, aviutl_num(L, 1) + (own ? f("x", 0) : 0) + f("ox", 0), aviutl_num(L, 2) + (own ? f("y", 0) : 0) + f("oy", 0), zoom * (aspect > 0 ? 1 - aspect : 1), zoom * (aspect < 0 ? 1 + aspect : 1),
        aviutl_num(L, 8) + f("rz", 0), aviutl_num(L, 5, 1) * f("alpha", 1), f("cx", 0), f("cy", 0), way, aviutl_sampling(r), r.sampler == "clamp" || r.sampler == "loop" || r.sampler == "mirror" ? 2.f : 0.f);
    lua_pop(L, 1);
    if (own) r.drew = true;
    return 0;
}
// obj.drawpoly as lua.txt has it (the AviUtl2 script skill's references/api.md): corners from the object's place into
// the frame (oz too), as they are into the temporary buffer, in depth (aviutl_mesh), the frame's alpha the object's too
// (sashimono-edit's lua_drawpoly); u, v pixels (none: the picture's four corners), the alpha the 13th or 21st; a table
// of faces of 20 ({x0 .. z3, u0 .. v3}[, alpha]), or of corners {x, y, z, u, v} with u, v 0 to 1, or {x, y, z, r, g,
// b, a} coloured, 4 or 3 a face ([, count, alpha]) (sashimono-edit's _drawpoly_table); or faces of 28, coloured
// ({x0 .. z3, r0, g0, b0, a0 .. a3}: 連結ライン.obj2's).
static int aviutl_drawpoly(lua_State* L) {
    AviutlRun& r = aviutl_of(L);
    const AviutlBuf& from = r.bufs["object"];
    std::vector<std::vector<AviutlCorner>> faces;
    double alpha = 1;
    const auto item = [&]() { std::vector<double> v; for (int j = 1; j <= (int)lua_objlen(L, -1); ++j) lua_rawgeti(L, -1, j), v.push_back(aviutl_num(L, -1)), lua_pop(L, 1); return v; };
    const auto face = [&](const double* p) { std::vector<AviutlCorner> c(4); for (int i = 0; i < 4; ++i) c[i] = {p[i * 3], p[i * 3 + 1], p[i * 3 + 2], p[12 + i * 2], p[13 + i * 2]}; return c; };
    if (lua_istable(L, 1)) {
        std::vector<std::vector<double>> items;
        for (int i = 1; i <= (int)lua_objlen(L, 1); ++i) {
            lua_rawgeti(L, 1, i);
            if (!lua_istable(L, -1)) return aviutl_no(L, "obj.drawpoly of a table of numbers");
            items.push_back(item()), lua_pop(L, 1);
        }
        if (items.empty()) return 0;
        const size_t width = items[0].size();
        for (const auto& v : items) if (v.size() != width) return aviutl_no(L, "obj.drawpoly of mixed faces");
        if (width == 20) {   // (faces)
            alpha = aviutl_num(L, 2, 1);
            for (const auto& v : items) faces.push_back(face(v.data()));
        } else if (width == 28) {   // (faces coloured: four corners' places, then their colours, premultiplied 0 to 1, as the 20's places then uv)
            alpha = aviutl_num(L, 2, 1);
            for (const auto& v : items) {
                std::vector<AviutlCorner> c(4);
                for (int i = 0; i < 4; ++i) {
                    c[i] = {v[i * 3], v[i * 3 + 1], v[i * 3 + 2], -2.0 * from.w, -2.0 * from.h};   // (no picture: its uv off it)
                    for (int k = 0; k < 4; ++k) c[i].colour[k] = (float)std::clamp(v[12 + i * 4 + k], 0.0, 1.0);
                }
                faces.push_back(c);
            }
        } else if (width == 5 || width == 7) {   // (corners: pictured, or coloured)
            const int count = lua_isnumber(L, 2) ? (int)lua_tonumber(L, 2) : 4;
            alpha = aviutl_num(L, 3, 1);
            if ((count != 3 && count != 4) || items.size() % count) return aviutl_no(L, "obj.drawpoly of " + std::to_string(count) + "-cornered faces");
            for (size_t f = 0; f < items.size(); f += count) {
                std::vector<AviutlCorner> c;
                for (int i = 0; i < count; ++i) {
                    const auto& v = items[f + i];
                    AviutlCorner one{v[0], v[1], v[2], width == 5 ? v[3] * from.w : -2.0 * from.w, width == 5 ? v[4] * from.h : -2.0 * from.h};   // (coloured: no picture, its uv off it)
                    if (width == 7) for (int k = 0; k < 4; ++k) one.colour[k] = (float)std::clamp(v[3 + k], 0.0, 1.0);
                    c.push_back(one);
                }
                faces.push_back(c);
            }
        } else return aviutl_no(L, "obj.drawpoly of " + std::to_string(width) + " numbers a face");
    } else {
        const int n = lua_gettop(L);
        if (n < 12) return aviutl_no(L, "obj.drawpoly with fewer than four corners");
        double p[20] = {};
        for (int i = 0; i < 12; ++i) p[i] = aviutl_num(L, i + 1);
        if (n >= 20) for (int i = 0; i < 8; ++i) p[12 + i] = aviutl_num(L, 13 + i);
        else p[14] = from.w, p[16] = from.w, p[17] = from.h, p[19] = from.h;
        alpha = n == 13 ? aviutl_num(L, 13, 1) : n >= 21 ? aviutl_num(L, 21, 1) : 1;
        faces.push_back(face(p));
    }
    const int way = aviutl_way(r.blend);
    if (way < 0) return aviutl_no(L, "obj.drawpoly blend " + r.blend);
    const AviutlBuf& to = r.bufs[r.target];
    if (!to.t) return aviutl_no(L, "obj.drawpoly into a temporary buffer never made");
    if (!r.poly) return aviutl_no(L, "obj.drawpoly: " + r.trouble);
    const bool own = r.target == "framebuffer";
    lua_getglobal(L, "obj");
    const auto f = [&](const char* k, double otherwise) { lua_getfield(L, -1, k); const double v = aviutl_num(L, -1, otherwise); lua_pop(L, 1); return v; };
    const double ox = own ? f("x", 0) + f("ox", 0) : 0, oy = own ? f("y", 0) + f("oy", 0) : 0, oz = own ? f("oz", 0) : 0, fade = alpha * (own ? f("alpha", 1) : 1);
    lua_pop(L, 1);
    aviutl_mesh(r, from, to, faces, ox, oy, oz, fade, way, aviutl_sampling(r));
    if (own) r.drew = true;
    return 0;
}
