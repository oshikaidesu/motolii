// Custom Inspector card for `texflow.js` (single source of truth in the Inspector):
// - Non-destructive per-letter animation (Mode, Order, interactive Bezier curve, Kanji/Kana rules)
// - One-click Split Letters / GG Strokes explosion, Backplate matte, Bake Keys to exploded parts
// - Built-in & user-saved JSON presets (~/.motolii/panel_presets/card_texflow.json)

const MODES = ["Slide", "Bounce", "Hang", "Scatter"];
const ORDERS = ["Start", "End", "Centre", "Edges", "Random"];
const AXES = ["Y", "X", "XY"];
const EASES = ["Custom", "VerySlowOut", "SlowOut", "Overshoot", "SpringOut", "BounceOut", "SlowInSlowOut", "Linear"];

const CURVE_PRESETS = {
  Expo: [0.16, 1.0, 0.3, 1.0],
  Back: [0.34, 1.45, 0.64, 1.0],
  Snap: [0.05, 0.9, 0.1, 1.0],
  Smooth: [0.45, 0.0, 0.55, 1.0],
};

const BUILTIN_PRESETS = {
  "Pop Bounce": {
    mode: 1, order: 0, axis: 0, distance: 1.4, length: 0.48, delay: 0.05,
    out: 1, alternate: 0, ease_preset: 0, x1: 0.16, y1: 1.35, x2: 0.3, y2: 1.0,
    kanji_scale: 1.15, kanji_delay: 0.03, kana_delay: 0, scale_from: 0.35, rotate_from: -14, opacity_from: 0,
  },
  "Lyric Slide": {
    mode: 0, order: 0, axis: 1, distance: 1.6, length: 0.45, delay: 0.04,
    out: 1, alternate: 0, ease_preset: 0, x1: 0.12, y1: 1.0, x2: 0.25, y2: 1.0,
    kanji_scale: 1.0, kanji_delay: 0, kana_delay: 0, scale_from: 1.0, rotate_from: 0, opacity_from: 0,
  },
  "Kanji Impact": {
    mode: 0, order: 2, axis: 0, distance: 1.5, length: 0.55, delay: 0.05,
    out: 0, alternate: 0, ease_preset: 0, x1: 0.18, y1: 1.45, x2: 0.32, y2: 1.0,
    kanji_scale: 1.3, kanji_delay: 0.07, kana_delay: 0, scale_from: 0.45, rotate_from: -8, opacity_from: 0,
  },
  "GG Scatter": {
    mode: 3, order: 4, axis: 2, distance: 1.8, length: 0.6, delay: 0.02,
    out: 1, alternate: 0, ease_preset: 0, x1: 0.1, y1: 1.0, x2: 0.22, y2: 1.0,
    kanji_scale: 1.0, kanji_delay: 0, kana_delay: 0, scale_from: 0.25, rotate_from: 90, opacity_from: 0,
  },
  "Hang Swing": {
    mode: 2, order: 0, axis: 0, distance: 1.2, length: 0.65, delay: 0.05,
    out: 1, alternate: 1, ease_preset: 0, x1: 0.22, y1: 1.3, x2: 0.36, y2: 1.0,
    kanji_scale: 1.0, kanji_delay: 0, kana_delay: 0, scale_from: 0.85, rotate_from: 42, opacity_from: 0,
  },
};

function _clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

function _charClass(textOrName) {
  if (!textOrName) return "other";
  const ch = Array.from(String(textOrName).trim())[0];
  if (!ch) return "other";
  const cp = ch.codePointAt(0);
  if ((cp >= 0x4E00 && cp <= 0x9FFF) || (cp >= 0x3400 && cp <= 0x4DBF) || cp === 0x3005) return "kanji";
  if (cp >= 0x3040 && cp <= 0x309F) return "hiragana";
  if (cp >= 0x30A0 && cp <= 0x30FF) return "katakana";
  return "other";
}

function _hash(seed, idx) {
  const h = Math.sin(seed * 127.1 + idx * 311.7) * 43758.5453;
  return h - Math.floor(h);
}

function _bezierSvg(x1, y1, x2, y2, activeHandle) {
  const padX = 22, padY = 18, w = 236, h = 66;
  const sx = (x) => padX + x * w;
  const sy = (y) => padY + (1 - (y + 0.3) / 1.9) * h;
  const x0 = sx(0), y0 = sy(0), x3 = sx(1), y3 = sy(1);
  const px1 = sx(x1), py1 = sy(y1), px2 = sx(x2), py2 = sy(y2);
  const path = `M ${x0.toFixed(1)} ${y0.toFixed(1)} C ${px1.toFixed(1)} ${py1.toFixed(1)} ${px2.toFixed(1)} ${py2.toFixed(1)} ${x3.toFixed(1)} ${y3.toFixed(1)}`;
  return `<svg viewBox="0 0 280 102" preserveAspectRatio="none">
    <rect x="${padX}" y="${sy(1).toFixed(1)}" width="${w}" height="${(sy(0) - sy(1)).toFixed(1)}" fill="var(--well)" opacity="0.65"/>
    <line x1="${padX}" y1="${y0.toFixed(1)}" x2="${padX + w}" y2="${y0.toFixed(1)}" stroke="var(--border)" stroke-width="0.8"/>
    <line x1="${padX}" y1="${y3.toFixed(1)}" x2="${padX + w}" y2="${y3.toFixed(1)}" stroke="var(--border)" stroke-width="0.8"/>
    <line x1="${x0.toFixed(1)}" y1="${y0.toFixed(1)}" x2="${px1.toFixed(1)}" y2="${py1.toFixed(1)}" stroke="var(--place)" stroke-width="1.2" opacity="0.85"/>
    <line x1="${x3.toFixed(1)}" y1="${y3.toFixed(1)}" x2="${px2.toFixed(1)}" y2="${py2.toFixed(1)}" stroke="var(--time)" stroke-width="1.2" opacity="0.85"/>
    <path d="${path}" fill="none" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
    <circle cx="${px1.toFixed(1)}" cy="${py1.toFixed(1)}" r="${activeHandle === 1 ? 6 : 4.8}" fill="var(--place)" stroke="var(--surface)" stroke-width="1.5"/>
    <circle cx="${px2.toFixed(1)}" cy="${py2.toFixed(1)}" r="${activeHandle === 2 ? 6 : 4.8}" fill="var(--time)" stroke="var(--surface)" stroke-width="1.5"/>
    <text x="${padX}" y="12" fill="var(--muted)" font-size="8.5" font-family="Inter">Bezier(${x1.toFixed(2)}, ${y1.toFixed(2)}, ${x2.toFixed(2)}, ${y2.toFixed(2)})</text>
  </svg>`;
}

// Finds children of the most recently exploded Letters/Strokes group for this text layer.
function _explodedChildren(ctx) {
  const lay = ctx.layer;
  const all = ctx.layers || [];
  if (!lay) return [];
  const base = lay.name || lay.text || "";
  const grp = all.slice().reverse().find(
    (l) => l.name === base + " (Strokes)" || l.name === base + " (Letters)"
  );
  if (!grp) return [];
  return all.filter((l) => l.parent === grp.id);
}

function renderCard(ctx) {
  const p = ctx.params || {};
  const st = ctx.state || {};
  const lay = ctx.layer || {};
  const isText = lay.kind === "text";
  const splitOn = lay.split === "letters";
  const parts = _explodedChildren(ctx);

  const mode = MODES[Math.round(Number(p.mode ?? 0))] || "Slide";
  const order = ORDERS[Math.round(Number(p.order ?? 0))] || "Start";
  const easeName = EASES[Math.round(Number(p.ease_preset ?? 0))] || "Custom";
  const x1 = Number(p.x1 ?? 0.16), y1 = Number(p.y1 ?? 1.0);
  const x2 = Number(p.x2 ?? 0.3), y2 = Number(p.y2 ?? 1.0);
  const outOn = Number(p.out ?? 1) >= 0.5;
  const altOn = Number(p.alternate ?? 0) >= 0.5;
  const kScale = Number(p.kanji_scale ?? 1.0);
  const kDelay = Number(p.kanji_delay ?? 0.0);
  const hDelay = Number(p.kana_delay ?? 0.0);
  const presetName = String(st.presetName ?? "MyPreset");
  const userPresets = Object.keys(ctx.presets || {});

  const children = [];
  if (isText && !splitOn) {
    children.push(
      ui.button("Enable Per-Letter Split", "enable_split", { accent: true })
    );
  }

  children.push(
    ui.select("Mode", mode, MODES, { id: "mode" }),
    ui.select("Order", order, ORDERS, { id: "order" }),
    ui.svg(102, _bezierSvg(x1, y1, x2, y2, st.handle || 0), {
      id: "curve",
      label: "Custom Easing (drag handles)",
      fit: "fill",
    }),
    ui.row([
      ui.button("Expo", "curve_preset:Expo"),
      ui.button("Back", "curve_preset:Back"),
      ui.button("Snap", "curve_preset:Snap"),
      ui.button("Smooth", "curve_preset:Smooth"),
    ]),
    ui.row([
      ui.toggle("Animate Out", outOn, { id: "out" }),
      ui.toggle("Alternate", altOn, { id: "alternate" }),
    ]),
    ui.section("Character Class (漢字 / かな)", [
      ui.slider("Kanji Scale", kScale, { id: "kanji_scale", min: 0.5, max: 2.5, step: 0.05 }),
      ui.row([
        ui.slider("Kanji Delay", kDelay, { id: "kanji_delay", min: -0.5, max: 0.5, step: 0.01, unit: "s" }),
        ui.slider("Kana Delay", hDelay, { id: "kana_delay", min: -0.5, max: 0.5, step: 0.01, unit: "s" }),
      ]),
    ], { open: false }),
    ui.section("Explode & Backplate", [
      ui.row([
        ui.button("Split Letters", "explode:letters", { disabled: !isText }),
        ui.button("GG Strokes", "explode:strokes", { tone: "place", disabled: !isText }),
      ]),
      ui.row([
        ui.button("Add Backplate", "backplate", { disabled: !lay.id }),
        ui.button(
          parts.length > 0 ? "Bake Keys (" + parts.length + ")" : "Bake Keys",
          "bake_parts",
          { accent: parts.length > 0, disabled: parts.length === 0 }
        ),
      ]),
    ], { open: true }),
    ui.section("Presets (JSON)", [
      ui.grid(
        Object.keys(BUILTIN_PRESETS).map((n) => ui.button(n, "load_builtin:" + n)),
        { cols: 2 }
      ),
      userPresets.length === 0
        ? ui.text("No user presets saved", { muted: true })
        : ui.column(
            userPresets.map((n) =>
              ui.row([
                ui.button(n, "load_user:" + n),
                ui.button("×", "del_user:" + n, { tone: "muted" }),
              ])
            )
          ),
      ui.row([
        ui.input("Name", presetName, { id: "presetName", placeholder: "Preset name" }),
        ui.button("Save", "save_preset", { tone: "time" }),
      ]),
    ], { open: false })
  );

  return {
    hide: ["mode", "order", "ease_preset", "x1", "y1", "x2", "y2", "out", "alternate", "kanji_scale", "kanji_delay", "kana_delay"],
    ui: ui.column(children),
  };
}

function _exportParams(p) {
  const keys = [
    "mode", "order", "axis", "distance", "length", "delay", "out", "alternate",
    "ease_preset", "x1", "y1", "x2", "y2", "kanji_scale", "kanji_delay", "kana_delay",
    "bounce_freq", "bounce_decay", "scatter_spread", "scatter_seed",
    "scale_from", "rotate_from", "opacity_from",
  ];
  const out = {};
  for (const k of keys) {
    if (p[k] !== undefined) out[k] = Number(p[k]);
  }
  return out;
}

function onCardAction(action, ctx) {
  const p = ctx.params || {};
  const st = Object.assign({}, ctx.state);
  const lay = ctx.layer || {};
  const id = action.id;

  if (id === "presetName") return { state: Object.assign(st, { presetName: String(action.value ?? "") }) };
  if (id === "mode") { const i = MODES.indexOf(action.value); if (i >= 0) return { set: { mode: i } }; }
  if (id === "order") { const i = ORDERS.indexOf(action.value); if (i >= 0) return { set: { order: i } }; }
  if (id === "ease_preset") { const i = EASES.indexOf(action.value); if (i >= 0) return { set: { ease_preset: i } }; }
  if (id === "out") return { set: { out: action.value ? 1 : 0 } };
  if (id === "alternate") return { set: { alternate: action.value ? 1 : 0 } };
  if (id === "kanji_scale" || id === "kanji_delay" || id === "kana_delay") {
    return { set: { [id]: Number(action.value) } };
  }

  if (id === "enable_split" && lay.id) {
    return {
      ops: [{ op: "say", layer: lay.id, name: "split", word: "letters" }],
      notice: "Enabled per-letter split",
    };
  }

  if (id.indexOf("curve_preset:") === 0) {
    const c = CURVE_PRESETS[id.slice(13)];
    if (c) return { set: { ease_preset: 0, x1: c[0], y1: c[1], x2: c[2], y2: c[3] } };
  }

  if (id === "curve" && action.value) {
    const ptr = action.value;
    const bx = _clamp((ptr.x * 280 - 22) / 236, 0, 1);
    const by = _clamp(1.6 - ((ptr.y * 102 - 18) / 66) * 1.9, -0.4, 1.6);
    let handle = st.handle || 0;
    if (ptr.phase === "down" || !handle) {
      const d1 = Math.hypot(bx - Number(p.x1 ?? 0.16), by - Number(p.y1 ?? 1.0));
      const d2 = Math.hypot(bx - Number(p.x2 ?? 0.3), by - Number(p.y2 ?? 1.0));
      handle = d1 <= d2 ? 1 : 2;
    }
    const nextState = Object.assign({}, st, { handle: ptr.phase === "up" ? 0 : handle });
    const patch = handle === 1
      ? { ease_preset: 0, x1: Number(bx.toFixed(2)), y1: Number(by.toFixed(2)) }
      : { ease_preset: 0, x2: Number(bx.toFixed(2)), y2: Number(by.toFixed(2)) };
    return { set: patch, state: nextState };
  }

  // Presets (built-in + JSON persisted user presets)
  if (id.indexOf("load_builtin:") === 0) {
    const name = id.slice(13);
    const preset = BUILTIN_PRESETS[name];
    if (preset) return { set: preset, notice: "Loaded preset: " + name };
  }
  if (id.indexOf("load_user:") === 0) {
    const name = id.slice(10);
    const preset = (ctx.presets || {})[name];
    if (preset && typeof preset === "object") {
      return { set: preset, state: Object.assign(st, { presetName: name }), notice: "Loaded preset: " + name };
    }
  }
  if (id.indexOf("del_user:") === 0) {
    const name = id.slice(9);
    return { ops: [{ op: "preset_delete", name: name }], notice: "Deleted preset: " + name };
  }
  if (id === "save_preset") {
    const name = String(st.presetName || "").trim() || "Preset";
    return {
      ops: [{ op: "preset_save", name: name, word: JSON.stringify(_exportParams(p)) }],
      notice: "Saved JSON preset: " + name,
    };
  }

  // Explode into editable letters or gg contour stroke parts
  if ((id === "explode:letters" || id === "explode:strokes") && lay.id) {
    const mode = id === "explode:strokes" ? "strokes" : "letters";
    return {
      ops: [{ op: "explode", layer: lay.id, mode: mode }],
      notice: mode === "strokes" ? "Exploded into GG stroke parts" : "Exploded into editable letters",
    };
  }

  // Auto-generate backplate matte behind this text layer
  if (id === "backplate" && lay.id) {
    const chars = Array.from(String(lay.text || "")).length || 3;
    const sz = lay.size || 0.7;
    const w = lay.width > 0.05 ? lay.width + 0.36 : Math.max(1.2, chars * sz * 0.9 + 0.36);
    const h = lay.height > 0.05 ? lay.height + 0.24 : Math.max(0.4, sz * 1.35);
    return {
      notice: "Added backplate behind " + (lay.name || "text"),
      ops: [
        { op: "add", kind: "shape", file: "rect" },
        { op: "say", layer: -1, name: "name", word: (lay.name || "Text") + " Plate" },
        { op: "say", layer: -1, name: "fill", word: "18181b" },
        { op: "set", layer: -1, name: "parent", value: lay.id },
        { op: "set", layer: -1, name: "x", value: 0 },
        { op: "set", layer: -1, name: "y", value: 0 },
        { op: "set", layer: -1, name: "z", value: -0.01 },
        { op: "set", layer: -1, name: "scale_x", value: w },
        { op: "set", layer: -1, name: "scale_y", value: h },
        { op: "set", layer: -1, name: "round", value: 0.08 },
        { op: "set", layer: -1, name: "opacity", value: 0.85 },
        { op: "set", layer: -1, name: "start", value: lay.start || 0 },
        { op: "set", layer: -1, name: "duration", value: lay.duration ?? -1 },
      ],
    };
  }

  // Bake current Texflow parameters as keyframes onto the exploded letter / GG stroke child layers
  if (id === "bake_parts") {
    const parts = _explodedChildren(ctx);
    if (parts.length === 0) return { notice: "Explode into Letters or GG Strokes first" };
    const mode = MODES[Math.round(Number(p.mode ?? 0))] || "Slide";
    const order = ORDERS[Math.round(Number(p.order ?? 0))] || "Start";
    const axis = AXES[Math.round(Number(p.axis ?? 0))] || "Y";
    const dist = Number(p.distance ?? 1.5) * 0.35;
    const len = Math.max(0.05, Number(p.length ?? 0.55));
    const step = Math.max(0, Number(p.delay ?? 0.05));
    const outOn = Number(p.out ?? 1) >= 0.5;
    const alt = Number(p.alternate ?? 0) >= 0.5;
    const x1 = Number(p.x1 ?? 0.16), y1 = Number(p.y1 ?? 1.0);
    const x2 = Number(p.x2 ?? 0.3), y2 = Number(p.y2 ?? 1.0);
    const kScale = Number(p.kanji_scale ?? 1.0);
    const kDelay = Number(p.kanji_delay ?? 0.0);
    const hDelay = Number(p.kana_delay ?? 0.0);
    const scaleFrom = Number(p.scale_from ?? 0.65);
    const rotFrom = Number(p.rotate_from ?? -18);
    const opFrom = Number(p.opacity_from ?? 0);
    const seed = Number(p.scatter_seed ?? 17);
    const spread = Number(p.scatter_spread ?? 1.8) * 0.4;

    const easeIn = mode === "Bounce"
      ? "Bounce 0.35 0.65"
      : ("Bezier " + x1.toFixed(3) + " " + y1.toFixed(3) + " " + x2.toFixed(3) + " " + y2.toFixed(3));
    const easeOut = "Bezier " + (1 - x2).toFixed(3) + " " + _clamp(1 - y2, -0.4, 1.6).toFixed(3) +
      " " + (1 - x1).toFixed(3) + " " + _clamp(1 - y1, -0.4, 1.6).toFixed(3);

    const fps = ctx.fps || 60;
    const baseT = ctx.time || 0;
    const n = parts.length;
    const mid = (n - 1) / 2;
    const ops = [];

    for (let i = 0; i < n; i++) {
      const l = parts[i];
      const cls = _charClass(l.text || l.name);
      const turn = order === "End" ? (n - 1 - i)
        : order === "Centre" ? Math.abs(i - mid)
        : order === "Edges" ? (mid - Math.abs(i - mid))
        : order === "Random" ? _hash(seed + 3, i) * Math.max(1, n - 1)
        : i;
      const extraDelay = cls === "kanji" ? kDelay
        : (cls === "hiragana" || cls === "katakana") ? hDelay : 0;
      const t0 = Math.max(0, baseT + turn * step + extraDelay);
      const t1 = t0 + len;
      const side = (alt && i % 2 === 1) ? -1 : 1;

      let dx = 0, dy = 0, dRot = rotFrom * side;
      if (mode === "Scatter") {
        const ang = _hash(seed, i) * Math.PI * 2;
        const rad = (0.4 + 0.8 * _hash(seed + 11, i)) * spread;
        dx = Math.cos(ang) * rad;
        dy = Math.sin(ang) * rad;
        dRot = (_hash(seed + 23, i) - 0.5) * 360;
      } else if (mode === "Hang") {
        dy = Math.abs(dist) * 0.65;
        dRot = (rotFrom !== 0 ? rotFrom : 40) * side;
      } else {
        if (axis === "X" || axis === "XY") dx = side * dist;
        if (axis === "Y" || axis === "XY") dy = -side * dist;
      }

      const endSx = (l.scale_x || 1) * (cls === "kanji" ? kScale : 1);
      const endSy = (l.scale_y || 1) * (cls === "kanji" ? kScale : 1);
      const endOp = l.opacity ?? 1;

      if (dx !== 0) {
        ops.push({ op: "key", layer: l.id, name: "x", at: t0, value: l.x + dx, ease: easeIn });
        ops.push({ op: "key", layer: l.id, name: "x", at: t1, value: l.x });
      }
      if (dy !== 0) {
        ops.push({ op: "key", layer: l.id, name: "y", at: t0, value: l.y + dy, ease: easeIn });
        ops.push({ op: "key", layer: l.id, name: "y", at: t1, value: l.y });
      }
      if (scaleFrom !== 1 || cls === "kanji") {
        ops.push({ op: "key", layer: l.id, name: "scale_x", at: t0, value: endSx * scaleFrom, ease: easeIn });
        ops.push({ op: "key", layer: l.id, name: "scale_x", at: t1, value: endSx });
        ops.push({ op: "key", layer: l.id, name: "scale_y", at: t0, value: endSy * scaleFrom, ease: easeIn });
        ops.push({ op: "key", layer: l.id, name: "scale_y", at: t1, value: endSy });
      }
      if (dRot !== 0) {
        ops.push({ op: "key", layer: l.id, name: "rotate", at: t0, value: (l.rotate || 0) + dRot, ease: easeIn });
        ops.push({ op: "key", layer: l.id, name: "rotate", at: t1, value: l.rotate || 0 });
      }
      ops.push({ op: "key", layer: l.id, name: "opacity", at: t0, value: opFrom, ease: easeIn });
      ops.push({ op: "key", layer: l.id, name: "opacity", at: t1, value: endOp });

      if (outOn) {
        const layerEnd = (l.duration > 0 ? (l.start || 0) + l.duration : ((ctx.duration || 480) / fps)) - 1 / fps;
        const lastTurn = (order === "Centre" || order === "Edges") ? mid : Math.max(0, n - 1);
        const outStart = Math.max(t1 + 0.1, layerEnd - lastTurn * step - len) + turn * step;
        const outEnd = outStart + len;
        if (dx !== 0) {
          ops.push({ op: "key", layer: l.id, name: "x", at: outStart, value: l.x, ease: easeOut });
          ops.push({ op: "key", layer: l.id, name: "x", at: outEnd, value: l.x - dx });
        }
        if (dy !== 0) {
          ops.push({ op: "key", layer: l.id, name: "y", at: outStart, value: l.y, ease: easeOut });
          ops.push({ op: "key", layer: l.id, name: "y", at: outEnd, value: l.y - dy });
        }
        ops.push({ op: "key", layer: l.id, name: "opacity", at: outStart, value: endOp, ease: easeOut });
        ops.push({ op: "key", layer: l.id, name: "opacity", at: outEnd, value: opFrom });
      }
    }
    return { ops: ops, notice: "Baked " + mode + " keyframes to " + n + " part(s)" };
  }

  return {};
}
