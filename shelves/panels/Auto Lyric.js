// --title: Auto Lyric
// --about: Tactile Vism lyric & text motion console (Texflow-compatible: modes, Bezier curve, Kanji/Kana rules, GG strokes, zabuton, echo, beat sync & JSON presets)
// --acts: Layer
// --tone: accent

const MODES = ["Slide", "Bounce", "Hang", "Scatter"];
const ORDERS = ["Start", "End", "Centre", "Edges", "Random"];
const AXES = ["Y", "X", "XY"];

const CURVE_PRESETS = {
  Expo: [0.16, 1.0, 0.3, 1.0],
  Back: [0.34, 1.45, 0.64, 1.0],
  Snap: [0.05, 0.9, 0.1, 1.0],
  Smooth: [0.45, 0.0, 0.55, 1.0],
  Linear: [0.0, 0.0, 1.0, 1.0],
};

const ZABUTON_COLORS = [
  "#18181B", "#FFFFFF", "#FF3B7F", "#00D4FF", "#FFE600", "#A855F7",
];

const BUILTIN_PRESETS = {
  "Pop Bounce": {
    mode: 1, order: 0, axis: 0, distance: 1.4, length: 0.48, delay: 0.05,
    out: 1, alternate: 0, x1: 0.16, y1: 1.35, x2: 0.3, y2: 1.0,
    kanji_scale: 1.15, kanji_delay: 0.03, kana_delay: 0,
    bounce_freq: 3.2, bounce_decay: 4.2, scatter_spread: 1.8, scatter_seed: 17,
    scale_from: 0.35, rotate_from: -14, opacity_from: 0,
  },
  "Lyric Slide": {
    mode: 0, order: 0, axis: 1, distance: 1.6, length: 0.45, delay: 0.04,
    out: 1, alternate: 0, x1: 0.12, y1: 1.0, x2: 0.25, y2: 1.0,
    kanji_scale: 1.0, kanji_delay: 0, kana_delay: 0,
    bounce_freq: 3.0, bounce_decay: 4.5, scatter_spread: 1.8, scatter_seed: 17,
    scale_from: 1.0, rotate_from: 0, opacity_from: 0,
  },
  "Kanji Impact": {
    mode: 0, order: 2, axis: 0, distance: 1.5, length: 0.55, delay: 0.05,
    out: 0, alternate: 0, x1: 0.18, y1: 1.45, x2: 0.32, y2: 1.0,
    kanji_scale: 1.35, kanji_delay: 0.07, kana_delay: 0,
    bounce_freq: 3.0, bounce_decay: 4.5, scatter_spread: 1.8, scatter_seed: 17,
    scale_from: 0.45, rotate_from: -8, opacity_from: 0,
  },
  "GG Scatter": {
    mode: 3, order: 4, axis: 2, distance: 1.8, length: 0.6, delay: 0.02,
    out: 1, alternate: 0, x1: 0.1, y1: 1.0, x2: 0.22, y2: 1.0,
    kanji_scale: 1.0, kanji_delay: 0, kana_delay: 0,
    bounce_freq: 3.0, bounce_decay: 4.5, scatter_spread: 2.2, scatter_seed: 29,
    scale_from: 0.25, rotate_from: 90, opacity_from: 0,
  },
  "Hang Swing": {
    mode: 2, order: 0, axis: 0, distance: 1.2, length: 0.65, delay: 0.05,
    out: 1, alternate: 1, x1: 0.22, y1: 1.3, x2: 0.36, y2: 1.0,
    kanji_scale: 1.0, kanji_delay: 0, kana_delay: 0,
    bounce_freq: 2.8, bounce_decay: 3.6, scatter_spread: 1.8, scatter_seed: 17,
    scale_from: 0.85, rotate_from: 42, opacity_from: 0,
  },
  "Kinetic Snap": {
    mode: 0, order: 3, axis: 0, distance: 2.2, length: 0.32, delay: 0.025,
    out: 1, alternate: 1, x1: 0.05, y1: 0.9, x2: 0.1, y2: 1.0,
    kanji_scale: 1.1, kanji_delay: 0, kana_delay: 0,
    bounce_freq: 3.0, bounce_decay: 4.5, scatter_spread: 1.8, scatter_seed: 17,
    scale_from: 0.7, rotate_from: 0, opacity_from: 0,
  },
  "Soft Float": {
    mode: 0, order: 0, axis: 0, distance: 0.8, length: 0.85, delay: 0.06,
    out: 1, alternate: 0, x1: 0.45, y1: 0.0, x2: 0.55, y2: 1.0,
    kanji_scale: 1.0, kanji_delay: 0, kana_delay: 0.02,
    bounce_freq: 2.0, bounce_decay: 4.0, scatter_spread: 1.2, scatter_seed: 17,
    scale_from: 0.92, rotate_from: -4, opacity_from: 0,
  },
  "MV Beat Drop": {
    mode: 1, order: 2, axis: 2, distance: 2.0, length: 0.42, delay: 0.03,
    out: 0, alternate: 1, x1: 0.28, y1: 1.5, x2: 0.38, y2: 1.0,
    kanji_scale: 1.28, kanji_delay: 0.04, kana_delay: -0.01,
    bounce_freq: 4.0, bounce_decay: 5.0, scatter_spread: 2.0, scatter_seed: 42,
    scale_from: 0.2, rotate_from: -22, opacity_from: 0,
  },
};

const PARAM_DEFAULTS = {
  mode: 0,
  order: 0,
  axis: 0,
  distance: 1.5,
  length: 0.55,
  delay: 0.05,
  out: 1,
  alternate: 0,
  x1: 0.16,
  y1: 1.0,
  x2: 0.3,
  y2: 1.0,
  kanji_scale: 1.0,
  kanji_delay: 0.0,
  kana_delay: 0.0,
  bounce_freq: 3.0,
  bounce_decay: 4.5,
  scatter_spread: 1.8,
  scatter_seed: 17,
  scale_from: 0.65,
  rotate_from: -18,
  opacity_from: 0.0,
};

const PARAM_KEYS = Object.keys(PARAM_DEFAULTS);

const COPY = {
  en: {
    apply: "Apply Flow",
    newLyric: "+ New Lyric",
    beatSync: "Beat Sync",
    noText: "Select or create a text layer",
    curveLabel: "Easing Curve (drag P1 / P2)",
    out: "Out",
    alt: "Alternate",
    charRules: "Character Class (Kanji / Kana)",
    kanjiScale: "Kanji Scale",
    kanjiDelay: "Kanji Delay",
    kanaDelay: "Kana Delay",
    tools: "Explode / Zabuton / Echo",
    splitLetters: "Split Letters",
    ggStrokes: "GG Strokes",
    zabuton: "Zabuton",
    echo: "Echo x3",
    bake: "Bake Keys",
    presets: "Presets (JSON)",
    save: "Save",
    noPresets: "No user presets saved",
    lyricPlaceholder: "Type lyric line...",
  },
  ja: {
    apply: "適用する",
    newLyric: "+ 歌詞を追加",
    beatSync: "ビート同期",
    noText: "テキストを選択または新規作成",
    curveLabel: "イージング曲線（点をドラッグ）",
    out: "退場あり",
    alt: "交互反転",
    charRules: "文字種ルール（漢字 / かな）",
    kanjiScale: "漢字サイズ",
    kanjiDelay: "漢字ディレイ",
    kanaDelay: "かなディレイ",
    tools: "分解 / ザブトン / 残像エコー",
    splitLetters: "1文字分解",
    ggStrokes: "GG ストローク",
    zabuton: "ザブトン",
    echo: "残像 x3",
    bake: "キーをベイク",
    presets: "プリセット (JSON)",
    save: "保存",
    noPresets: "保存済みプリセットなし",
    lyricPlaceholder: "歌詞を入力...",
  },
};

function _clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

function _state(ctx) {
  const raw = (ctx && ctx.state) || {};
  const out = Object.assign({
    lang: "ja",
    lyricText: "離れていた表現の交差点",
    presetName: "MyFlow",
    zabutonColor: "#18181B",
    zabutonPad: 0.36,
    echoCount: 3,
    echoStep: 0.04,
    handle: 0,
  }, PARAM_DEFAULTS, raw);
  return out;
}

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

function _selectedLayers(ctx) {
  const all = (ctx && ctx.layers) || [];
  const sel = (ctx && ctx.selected) || [];
  const byId = {};
  for (const l of all) byId[l.id] = l;
  return sel.map((id) => byId[id]).filter(Boolean);
}

function _activeTextLayer(ctx) {
  const picked = _selectedLayers(ctx);
  return picked.find((l) => l.kind === "text") || picked[0] || null;
}

function _explodedChildren(ctx, lay) {
  const all = (ctx && ctx.layers) || [];
  if (!lay) return [];
  const base = lay.name || lay.text || "";
  const grp = all.slice().reverse().find(
    (l) => l.name === base + " (Strokes)" || l.name === base + " (Letters)"
  );
  if (!grp) return [];
  return all.filter((l) => l.parent === grp.id);
}

function _hexNoHash(hex) {
  return String(hex || "#18181B").replace(/^#/, "");
}

function _previewAndCurveSvg(st, sampleText) {
  const x1 = Number(st.x1), y1 = Number(st.y1);
  const x2 = Number(st.x2), y2 = Number(st.y2);
  const modeIdx = Math.round(Number(st.mode));
  const orderIdx = Math.round(Number(st.order));
  const order = ORDERS[orderIdx] || "Start";
  const alt = Number(st.alternate) >= 0.5;

  const padX = 20, padY = 16, w = 240, h = 68;
  const sx = (x) => padX + x * w;
  const sy = (y) => padY + (1 - (y + 0.35) / 2.0) * h;
  const x0 = sx(0), y0 = sy(0), x3 = sx(1), y3 = sy(1);
  const px1 = sx(x1), py1 = sy(y1), px2 = sx(x2), py2 = sy(y2);
  const path = `M ${x0.toFixed(1)} ${y0.toFixed(1)} C ${px1.toFixed(1)} ${py1.toFixed(1)} ${px2.toFixed(1)} ${py2.toFixed(1)} ${x3.toFixed(1)} ${y3.toFixed(1)}`;

  // Mini per-letter cascade strip along the bottom of the OLED screen
  const rawChars = Array.from(String(sampleText || "AUTOLYRIC").replace(/[\r\n\s]/g, "")).slice(0, 8);
  const chars = rawChars.length ? rawChars : ["A", "U", "T", "O"];
  const n = chars.length;
  const mid = (n - 1) / 2;
  const bars = [];
  for (let i = 0; i < n; i++) {
    let turn = n > 1 ? i / (n - 1) : 0;
    if (order === "End") turn = n > 1 ? (n - 1 - i) / (n - 1) : 0;
    else if (order === "Centre") turn = mid > 0 ? Math.abs(i - mid) / mid : 0;
    else if (order === "Edges") turn = mid > 0 ? (mid - Math.abs(i - mid)) / mid : 0;
    else if (order === "Random") turn = _hash(Number(st.scatter_seed) + 3, i);

    const cls = _charClass(chars[i]);
    const clsBias = cls === "kanji" ? Number(st.kanji_delay) : (cls === "hiragana" || cls === "katakana") ? Number(st.kana_delay) : 0;
    const norm = _clamp(turn + clsBias * 0.8, 0, 1);
    const bx = padX + norm * (w - 44);
    const by = 92 + (i % 4) * 5.2;
    const fill = cls === "kanji" ? "#FF3B7F" : (alt && i % 2 === 1 ? "#38BDF8" : "#3ED9A4");
    bars.push(`<rect x="${bx.toFixed(1)}" y="${by.toFixed(1)}" width="44" height="3.6" rx="1.8" fill="${fill}" opacity="0.88"/>`);
  }

  const accent = modeIdx === 1 ? "#FF3B7F" : modeIdx === 2 ? "#FFB547" : modeIdx === 3 ? "#A855F7" : "#3ED9A4";
  return `<svg viewBox="0 0 280 116" preserveAspectRatio="none">
    <rect x="0" y="0" width="280" height="116" rx="6" fill="#0B0F17"/>
    <rect x="${padX}" y="${sy(1).toFixed(1)}" width="${w}" height="${(sy(0) - sy(1)).toFixed(1)}" fill="#131B2A" opacity="0.85"/>
    <g stroke="#243047" stroke-width="0.7" stroke-dasharray="2 3">
      <line x1="${sx(0.25).toFixed(1)}" y1="${padY}" x2="${sx(0.25).toFixed(1)}" y2="${padY + h}"/>
      <line x1="${sx(0.5).toFixed(1)}" y1="${padY}" x2="${sx(0.5).toFixed(1)}" y2="${padY + h}"/>
      <line x1="${sx(0.75).toFixed(1)}" y1="${padY}" x2="${sx(0.75).toFixed(1)}" y2="${padY + h}"/>
    </g>
    <line x1="${padX}" y1="${y0.toFixed(1)}" x2="${padX + w}" y2="${y0.toFixed(1)}" stroke="#334155" stroke-width="0.9"/>
    <line x1="${padX}" y1="${y3.toFixed(1)}" x2="${padX + w}" y2="${y3.toFixed(1)}" stroke="#334155" stroke-width="0.9"/>
    <line x1="${x0.toFixed(1)}" y1="${y0.toFixed(1)}" x2="${px1.toFixed(1)}" y2="${py1.toFixed(1)}" stroke="#38BDF8" stroke-width="1.3" opacity="0.9"/>
    <line x1="${x3.toFixed(1)}" y1="${y3.toFixed(1)}" x2="${px2.toFixed(1)}" y2="${py2.toFixed(1)}" stroke="#FF3B7F" stroke-width="1.3" opacity="0.9"/>
    <path d="${path}" fill="none" stroke="${accent}" stroke-width="2.4" stroke-linecap="round"/>
    <circle cx="${px1.toFixed(1)}" cy="${py1.toFixed(1)}" r="${st.handle === 1 ? 6 : 4.8}" fill="#38BDF8" stroke="#0B0F17" stroke-width="1.5"/>
    <circle cx="${px2.toFixed(1)}" cy="${py2.toFixed(1)}" r="${st.handle === 2 ? 6 : 4.8}" fill="#FF3B7F" stroke="#0B0F17" stroke-width="1.5"/>
    <text x="${padX}" y="11" fill="#94A3B8" font-size="8.2" font-family="monospace">BEZIER ${x1.toFixed(2)}, ${y1.toFixed(2)}, ${x2.toFixed(2)}, ${y2.toFixed(2)} · ${MODES[modeIdx]} / ${order}</text>
    ${bars.join("")}
  </svg>`;
}

function _texflowOpsForLayer(layerId, st, existingFx) {
  const ops = [];
  const hasTexflow = String(existingFx || "").indexOf("texflow.js") >= 0;
  ops.push({ op: "say", layer: layerId, name: "split", word: "letters" });
  if (!hasTexflow) {
    ops.push({ op: "fx", layer: layerId, file: "expressions/texflow.js" });
  }
  // Custom curve uses ease_preset=0 ("Custom") so Bezier handles always take effect.
  ops.push({ op: "set", layer: layerId, name: "js_ease_preset", value: 0 });
  for (const k of PARAM_KEYS) {
    ops.push({ op: "set", layer: layerId, name: "js_" + k, value: Number(st[k]) });
  }
  return ops;
}

function render(ctx) {
  const st = _state(ctx);
  const t = COPY[st.lang === "en" ? "en" : "ja"];
  const active = _activeTextLayer(ctx);
  const isText = !!active && active.kind === "text";
  const pickedCount = (ctx.selected || []).length;
  const parts = _explodedChildren(ctx, active);

  const modeIdx = Math.round(Number(st.mode));
  const mode = MODES[modeIdx] || "Slide";
  const order = ORDERS[Math.round(Number(st.order))] || "Start";
  const axis = AXES[Math.round(Number(st.axis))] || "Y";
  const bpm = Math.round(Number(ctx.bpm || 0));
  const userPresets = Object.keys((ctx && ctx.presets) || {});

  const modeAccent = modeIdx === 1 ? "#FF3B7F" : modeIdx === 2 ? "#FFB547" : modeIdx === 3 ? "#A855F7" : "#3ED9A4";

  const modeButtons = MODES.map((m, idx) =>
    ui.button(m, "mode:" + idx, {
      style: idx === modeIdx
        ? { bg: modeAccent, fg: "#0B0F17", border: modeAccent, borderWidth: 1.4, radius: 6, mono: true, fontSize: 9.5 }
        : { bg: "#141A26", fg: "#94A3B8", border: "#263147", borderWidth: 1, radius: 6, mono: true, fontSize: 9.5 },
    })
  );

  // Mode-adaptive 2nd row of tactile rotary knobs
  let extraKnobs;
  if (mode === "Bounce" || mode === "Hang") {
    extraKnobs = [
      ui.knob("FREQ", Number(st.bounce_freq), { id: "bounce_freq", min: 0.5, max: 10, def: 3.0, dec: 1, look: "arc", size: 38, color: "#FF3B7F", capColor: "#141A26", trackColor: "#222C40" }),
      ui.knob("DECAY", Number(st.bounce_decay), { id: "bounce_decay", min: 0.5, max: 12, def: 4.5, dec: 1, look: "arc", size: 38, color: "#FFB547", capColor: "#141A26", trackColor: "#222C40" }),
      ui.knob("SCALE", Number(st.scale_from), { id: "scale_from", min: 0, max: 2.5, def: 0.65, dec: 2, look: "arc", size: 38, color: "#38BDF8", capColor: "#141A26", trackColor: "#222C40" }),
      ui.knob("OPAC", Number(st.opacity_from), { id: "opacity_from", min: 0, max: 1, def: 0, dec: 2, look: "arc", size: 38, color: "#A855F7", capColor: "#141A26", trackColor: "#222C40" }),
    ];
  } else if (mode === "Scatter") {
    extraKnobs = [
      ui.knob("SPREAD", Number(st.scatter_spread), { id: "scatter_spread", min: 0, max: 8, def: 1.8, dec: 1, look: "arc", size: 38, color: "#A855F7", capColor: "#141A26", trackColor: "#222C40" }),
      ui.knob("SEED", Number(st.scatter_seed), { id: "scatter_seed", min: 1, max: 999, def: 17, step: 1, dec: 0, look: "arc", size: 38, color: "#FF3B7F", capColor: "#141A26", trackColor: "#222C40" }),
      ui.knob("SCALE", Number(st.scale_from), { id: "scale_from", min: 0, max: 2.5, def: 0.65, dec: 2, look: "arc", size: 38, color: "#38BDF8", capColor: "#141A26", trackColor: "#222C40" }),
      ui.knob("OPAC", Number(st.opacity_from), { id: "opacity_from", min: 0, max: 1, def: 0, dec: 2, look: "arc", size: 38, color: "#3ED9A4", capColor: "#141A26", trackColor: "#222C40" }),
    ];
  } else {
    extraKnobs = [
      ui.knob("SCALE", Number(st.scale_from), { id: "scale_from", min: 0, max: 2.5, def: 0.65, dec: 2, look: "arc", size: 38, color: "#38BDF8", capColor: "#141A26", trackColor: "#222C40" }),
      ui.knob("OPAC", Number(st.opacity_from), { id: "opacity_from", min: 0, max: 1, def: 0, dec: 2, look: "arc", size: 38, color: "#A855F7", capColor: "#141A26", trackColor: "#222C40" }),
      ui.knob("KANJI", Number(st.kanji_scale), { id: "kanji_scale", min: 0.5, max: 2.5, def: 1.0, dec: 2, look: "arc", size: 38, color: "#FF3B7F", capColor: "#141A26", trackColor: "#222C40" }),
      ui.knob("SEED", Number(st.scatter_seed), { id: "scatter_seed", min: 1, max: 999, def: 17, step: 1, dec: 0, look: "arc", size: 38, color: "#FFB547", capColor: "#141A26", trackColor: "#222C40" }),
    ];
  }

  return ui.box([
    // Header bar
    ui.row([
      ui.badge("AUTO LYRIC", {
        style: { bg: modeAccent, fg: "#0B0F17", borderWidth: 0, radius: 5, mono: true, fontSize: 9 },
      }),
      ui.badge(
        isText ? (active.name || "Text") : (pickedCount > 0 ? pickedCount + " sel" : "READY"),
        { style: { bg: "#141B29", fg: isText ? "#E2F4FF" : "#7D93B0", border: "#26324A", borderWidth: 1, radius: 5, fontSize: 8.5 } }
      ),
      ui.spacer(),
      bpm > 0
        ? ui.badge(bpm + " BPM", { style: { bg: "#1E1629", fg: "#C084FC", border: "#4C2E70", borderWidth: 1, radius: 5, mono: true, fontSize: 8.5 } })
        : ui.spacer(2),
      ui.button(st.lang === "ja" ? "EN" : "JP", "toggle_lang", {
        style: { bg: "#141A26", fg: "#94A3B8", border: "#263147", borderWidth: 1, radius: 5, mono: true, fontSize: 8.5 },
      }),
    ]),

    // Quick lyric line creator when no text layer is picked (or anytime!)
    ui.row([
      ui.input("", st.lyricText, {
        id: "lyricText",
        placeholder: t.lyricPlaceholder,
        style: { bg: "#0B0F17", fg: "#E2F4FF", border: "#25324A", radius: 6 },
      }),
      ui.button(t.newLyric, "new_lyric", {
        style: { bg: "#1C2538", fg: "#3ED9A4", border: "#3ED9A466", borderWidth: 1.2, radius: 6, fontSize: 9.5 },
      }),
    ]),

    // Mode deck (Texflow 4 core modes)
    ui.row(modeButtons),

    // Live OLED Bezier + per-letter cascade screen
    ui.svg(116, _previewAndCurveSvg(st, isText ? (active.text || active.name) : st.lyricText), {
      id: "curve",
      label: t.curveLabel,
      fit: "fill",
      framed: false,
    }),

    // Curve quick presets
    ui.row(
      Object.keys(CURVE_PRESETS).map((name) =>
        ui.button(name, "curve_preset:" + name, {
          style: { bg: "#141A26", fg: "#CBD5E1", border: "#25324A", borderWidth: 1, radius: 5, fontSize: 8.5, mono: true },
        })
      )
    ),

    // Order (full width so all 5 options read cleanly) + Axis
    ui.select("Order", order, ORDERS, { id: "order", style: { bg: "#111723", fg: "#E2F4FF", border: "#25324A", radius: 6 } }),
    ui.row([
      ui.select("Axis", axis, AXES, { id: "axis", style: { bg: "#111723", fg: "#E2F4FF", border: "#25324A", radius: 6 } }),
      ui.column([
        ui.toggle(t.out, Number(st.out) >= 0.5, { id: "out" }),
        ui.toggle(t.alt, Number(st.alternate) >= 0.5, { id: "alternate" }),
      ]),
    ]),

    // Primary VST knob row
    ui.row([
      ui.knob("DIST", Number(st.distance), { id: "distance", min: -10, max: 10, def: 1.5, dec: 2, look: "arc", size: 40, color: "#3ED9A4", capColor: "#141A26", trackColor: "#222C40" }),
      ui.knob("LEN", Number(st.length), { id: "length", min: 0.05, max: 4.0, def: 0.55, dec: 2, unit: "s", look: "arc", size: 40, color: "#38BDF8", capColor: "#141A26", trackColor: "#222C40" }),
      ui.knob("DELAY", Number(st.delay), { id: "delay", min: 0, max: 1.0, def: 0.05, dec: 2, unit: "s", look: "arc", size: 40, color: "#FF3B7F", capColor: "#141A26", trackColor: "#222C40" }),
      ui.knob("ROT", Number(st.rotate_from), { id: "rotate_from", min: -180, max: 180, def: -18, step: 1, dec: 0, unit: "°", look: "arc", size: 40, color: "#FFB547", capColor: "#141A26", trackColor: "#222C40" }),
    ]),

    // Secondary adaptive knob row
    ui.row(extraKnobs),

    // Main action bar: Apply Flow + Beat Sync
    ui.row([
      ui.button(t.apply, "apply", {
        accent: true,
        disabled: pickedCount === 0,
        style: { bg: modeAccent, fg: "#0B0F17", borderWidth: 0, radius: 7, fontSize: 10 },
      }),
      ui.button(t.beatSync, "beat_sync", {
        disabled: pickedCount === 0,
        style: { bg: "#1E1629", fg: "#D8B4FE", border: "#6B21A8", borderWidth: 1.2, radius: 7, fontSize: 9.5 },
      }),
    ]),

    // Character-class rules (Kanji / Kana)
    ui.section(t.charRules, [
      ui.slider(t.kanjiScale, Number(st.kanji_scale), { id: "kanji_scale", min: 0.5, max: 2.5, step: 0.05 }),
      ui.row([
        ui.slider(t.kanjiDelay, Number(st.kanji_delay), { id: "kanji_delay", min: -0.5, max: 0.5, step: 0.01, unit: "s" }),
        ui.slider(t.kanaDelay, Number(st.kana_delay), { id: "kana_delay", min: -0.5, max: 0.5, step: 0.01, unit: "s" }),
      ]),
    ], { open: false }),

    // Explode, Zabuton backplate, Echo trail & Keyframe Bake
    ui.section(t.tools, [
      ui.row([
        ui.button(t.splitLetters, "explode:letters", { disabled: !isText }),
        ui.button(t.ggStrokes, "explode:strokes", { tone: "place", disabled: !isText }),
      ]),
      ui.row([
        ui.button(t.zabuton, "backplate", { disabled: !active }),
        ui.button(t.echo, "echo", { disabled: !isText }),
      ]),
      ui.button(
        parts.length > 0 ? t.bake + " (" + parts.length + ")" : t.bake,
        "bake_parts",
        { accent: parts.length > 0, disabled: parts.length === 0 }
      ),
      ui.grid(
        ZABUTON_COLORS.map((hex) =>
          ui.swatch(hex, { id: "zabuton_color:" + hex, active: st.zabutonColor === hex })
        ),
        { cols: 6 }
      ),
    ], { open: true }),

    // Presets (8 built-ins + user JSON persistence)
    ui.section(t.presets, [
      ui.grid(
        Object.keys(BUILTIN_PRESETS).map((n) => ui.button(n, "load_builtin:" + n)),
        { cols: 2 }
      ),
      userPresets.length === 0
        ? ui.text(t.noPresets, { muted: true })
        : ui.column(
            userPresets.map((n) =>
              ui.row([
                ui.button(n, "load_user:" + n),
                ui.button("×", "del_user:" + n, { tone: "muted" }),
              ])
            )
          ),
      ui.row([
        ui.input("Name", st.presetName, { id: "presetName", placeholder: "Preset name" }),
        ui.button(t.save, "save_preset", { tone: "time" }),
      ]),
    ], { open: false }),
  ], {
    bg: "#0E131D",
    bg2: "#151D2C",
    fg: "#E8F1FF",
    muted: "#7D93B0",
    accent: modeAccent,
    border: "#26334D",
    borderWidth: 1.4,
    radius: 12,
    pad: 10,
    gap: 8,
  });
}

function _exportParams(st) {
  const out = {};
  for (const k of PARAM_KEYS) out[k] = Number(st[k]);
  return out;
}

function onAction(action, ctx) {
  const st = _state(ctx);
  const id = String(action.id || "");
  const picked = _selectedLayers(ctx);
  const active = _activeTextLayer(ctx);

  // Live-sync helper: when editing a parameter while a texflow-enabled layer is selected, update both state and layer.
  function commitParam(patch, notice) {
    const next = Object.assign({}, st, patch);
    const ops = [];
    for (const l of picked) {
      if (String(l.fx || "").indexOf("texflow.js") >= 0) {
        ops.push({ op: "set", layer: l.id, name: "js_ease_preset", value: 0 });
        for (const k of Object.keys(patch)) {
          if (PARAM_DEFAULTS[k] !== undefined) {
            ops.push({ op: "set", layer: l.id, name: "js_" + k, value: Number(patch[k]) });
          }
        }
      }
    }
    const res = { state: next };
    if (ops.length) res.ops = ops;
    if (notice) res.notice = notice;
    return res;
  }

  if (id === "toggle_lang") {
    return { state: Object.assign({}, st, { lang: st.lang === "ja" ? "en" : "ja" }) };
  }
  if (id === "lyricText") {
    return { state: Object.assign({}, st, { lyricText: String(action.value ?? "") }) };
  }
  if (id === "presetName") {
    return { state: Object.assign({}, st, { presetName: String(action.value ?? "") }) };
  }
  if (id.indexOf("zabuton_color:") === 0) {
    return { state: Object.assign({}, st, { zabutonColor: id.slice(14) }) };
  }
  if (id.indexOf("mode:") === 0) {
    return commitParam({ mode: Number(id.slice(5)) });
  }
  if (id === "order") {
    const idx = ORDERS.indexOf(action.value);
    if (idx >= 0) return commitParam({ order: idx });
  }
  if (id === "axis") {
    const idx = AXES.indexOf(action.value);
    if (idx >= 0) return commitParam({ axis: idx });
  }
  if (id === "out" || id === "alternate") {
    return commitParam({ [id]: action.value ? 1 : 0 });
  }
  if (PARAM_DEFAULTS[id] !== undefined) {
    return commitParam({ [id]: Number(action.value) });
  }

  if (id.indexOf("curve_preset:") === 0) {
    const c = CURVE_PRESETS[id.slice(13)];
    if (c) return commitParam({ x1: c[0], y1: c[1], x2: c[2], y2: c[3] });
  }

  if (id === "curve" && action.value) {
    const ptr = action.value;
    const bx = _clamp((ptr.x * 280 - 20) / 240, 0, 1);
    const by = _clamp(1.65 - ((ptr.y * 116 - 16) / 68) * 2.0, -0.35, 1.65);
    let handle = st.handle || 0;
    if (ptr.phase === "down" || !handle) {
      const d1 = Math.hypot(bx - Number(st.x1), by - Number(st.y1));
      const d2 = Math.hypot(bx - Number(st.x2), by - Number(st.y2));
      handle = d1 <= d2 ? 1 : 2;
    }
    const patch = handle === 1
      ? { x1: Number(bx.toFixed(2)), y1: Number(by.toFixed(2)) }
      : { x2: Number(bx.toFixed(2)), y2: Number(by.toFixed(2)) };
    const nextHandle = ptr.phase === "up" ? 0 : handle;
    const res = commitParam(patch);
    res.state.handle = nextHandle;
    return res;
  }

  // Create a brand-new lyric text layer at playhead with Auto Lyric (texflow.js) attached
  if (id === "new_lyric") {
    const text = String(st.lyricText || "").trim() || "Auto Lyric";
    const startAt = Math.max(0, Number(ctx.time || 0));
    const ops = [
      { op: "add", kind: "text", file: "" },
      { op: "say", layer: -1, name: "name", word: text.slice(0, 24) },
      { op: "say", layer: -1, name: "text", word: text },
      { op: "set", layer: -1, name: "start", value: startAt },
      { op: "set", layer: -1, name: "duration", value: 3.0 },
    ].concat(_texflowOpsForLayer(-1, st, ""));
    return { ops: ops, notice: "Created Auto Lyric: " + text.slice(0, 20) };
  }

  // Apply non-destructive Auto Lyric (texflow.js) to all selected layers
  if (id === "apply") {
    if (picked.length === 0) return { notice: "Select a text layer first" };
    let ops = [];
    for (const l of picked) {
      ops = ops.concat(_texflowOpsForLayer(l.id, st, l.fx));
    }
    return {
      ops: ops,
      notice: "Applied Auto Lyric (" + MODES[Math.round(Number(st.mode))] + ") to " + picked.length + " layer(s)",
    };
  }

  // Sync selected lyric layers onto timeline markers, audio beat strikes, or project BPM grid
  if (id === "beat_sync") {
    if (picked.length === 0) return { notice: "Select layers to beat-sync" };
    const marks = (ctx.marks || []).map((m) => Number(m.time)).filter((x) => !isNaN(x)).sort((a, b) => a - b);
    const strikes = (ctx.strikes || []).map(Number).filter((x) => !isNaN(x)).sort((a, b) => a - b);
    const bpm = Number(ctx.bpm || 120);
    const beatSec = 60 / (bpm > 0 ? bpm : 120);
    const startAt = Number(ctx.time || 0);

    let anchors = marks.filter((t) => t >= startAt - 0.01);
    let source = "markers";
    if (anchors.length < picked.length) {
      const futureStrikes = strikes.filter((t) => t >= startAt - 0.01);
      if (futureStrikes.length >= picked.length) {
        anchors = futureStrikes;
        source = "audio strikes";
      } else {
        anchors = picked.map((_, i) => startAt + i * beatSec * 2);
        source = Math.round(bpm > 0 ? bpm : 120) + " BPM grid";
      }
    }

    const ops = [];
    for (let i = 0; i < picked.length; i++) {
      const t0 = anchors[i];
      const nextT = i + 1 < anchors.length ? anchors[i + 1] : t0 + beatSec * 2;
      ops.push({ op: "set", layer: picked[i].id, name: "start", value: t0 });
      ops.push({ op: "set", layer: picked[i].id, name: "duration", value: Math.max(0.3, nextT - t0) });
    }
    return { ops: ops, notice: "Synced " + picked.length + " layer(s) to " + source };
  }

  // Presets (built-in + JSON persisted user presets)
  if (id.indexOf("load_builtin:") === 0) {
    const name = id.slice(13);
    const preset = BUILTIN_PRESETS[name];
    if (preset) return commitParam(preset, "Loaded preset: " + name);
  }
  if (id.indexOf("load_user:") === 0) {
    const name = id.slice(10);
    const preset = ((ctx && ctx.presets) || {})[name];
    if (preset && typeof preset === "object") {
      const res = commitParam(preset, "Loaded preset: " + name);
      res.state.presetName = name;
      return res;
    }
  }
  if (id.indexOf("del_user:") === 0) {
    const name = id.slice(9);
    return { ops: [{ op: "preset_delete", name: name }], notice: "Deleted preset: " + name };
  }
  if (id === "save_preset") {
    const name = String(st.presetName || "").trim() || "Preset";
    return {
      ops: [{ op: "preset_save", name: name, word: JSON.stringify(_exportParams(st)) }],
      notice: "Saved JSON preset: " + name,
    };
  }

  // Explode into editable letters or GG stroke parts
  if ((id === "explode:letters" || id === "explode:strokes") && active && active.kind === "text") {
    const mode = id === "explode:strokes" ? "strokes" : "letters";
    return {
      ops: [{ op: "explode", layer: active.id, mode: mode }],
      notice: mode === "strokes" ? "Exploded into GG stroke parts" : "Exploded into editable letters",
    };
  }

  // Auto-generate Zabuton backplate matte behind the selected text layer
  if (id === "backplate" && active) {
    const chars = Array.from(String(active.text || "")).length || 3;
    const sz = active.size || 0.7;
    const pad = Number(st.zabutonPad || 0.36);
    const w = active.width > 0.05 ? active.width + pad : Math.max(1.2, chars * sz * 0.9 + pad);
    const h = active.height > 0.05 ? active.height + pad * 0.65 : Math.max(0.4, sz * 1.35);
    const effOrder = (l) => (l.order ? l.order : l.id);
    const all = ctx.layers || [];
    const idx = all.findIndex((l) => l.id === active.id);
    const layOrder = effOrder(active);
    const behind = idx >= 0 && idx + 1 < all.length ? all[idx + 1] : null;
    const plateOrder = behind && effOrder(behind) < layOrder
      ? (effOrder(behind) + layOrder) / 2
      : layOrder - 0.5;
    return {
      notice: "Added Zabuton behind " + (active.name || "text"),
      ops: [
        { op: "add", kind: "shape", file: "rect" },
        { op: "say", layer: -1, name: "name", word: (active.name || "Lyric") + " Zabuton" },
        { op: "say", layer: -1, name: "fill", word: _hexNoHash(st.zabutonColor) },
        { op: "set", layer: -1, name: "parent", value: active.id },
        { op: "set", layer: -1, name: "order", value: plateOrder },
        { op: "set", layer: -1, name: "x", value: 0 },
        { op: "set", layer: -1, name: "y", value: 0 },
        { op: "set", layer: -1, name: "z", value: -0.01 },
        { op: "set", layer: -1, name: "scale_x", value: w },
        { op: "set", layer: -1, name: "scale_y", value: h },
        { op: "set", layer: -1, name: "round", value: 0.08 },
        { op: "set", layer: -1, name: "opacity", value: 0.88 },
        { op: "set", layer: -1, name: "start", value: active.start || 0 },
        { op: "set", layer: -1, name: "duration", value: active.duration ?? -1 },
      ],
    };
  }

  // Generate delayed afterimage Echo trail copies behind the selected text layer
  if (id === "echo" && active && active.kind === "text") {
    const count = Math.max(1, Math.min(5, Math.round(Number(st.echoCount || 3))));
    const dt = Number(st.echoStep || 0.04);
    const baseOrder = active.order ? active.order : active.id;
    const tints = ["FF3B7F", "38BDF8", "A855F7", "FFB547", "3ED9A4"];
    let ops = [];
    for (let e = 1; e <= count; e++) {
      ops.push({ op: "add", kind: "text", file: "" });
      ops.push({ op: "say", layer: -1, name: "name", word: (active.name || "Lyric") + " Echo " + e });
      ops.push({ op: "say", layer: -1, name: "text", word: active.text || active.name || "Lyric" });
      if (active.font) ops.push({ op: "say", layer: -1, name: "file", word: active.font });
      ops.push({ op: "say", layer: -1, name: "fill", word: tints[(e - 1) % tints.length] });
      ops.push({ op: "set", layer: -1, name: "size", value: active.size || 1 });
      ops.push({ op: "set", layer: -1, name: "x", value: active.x || 0 });
      ops.push({ op: "set", layer: -1, name: "y", value: active.y || 0 });
      ops.push({ op: "set", layer: -1, name: "z", value: (active.z || 0) - 0.005 * e });
      ops.push({ op: "set", layer: -1, name: "order", value: baseOrder - 0.05 * e });
      ops.push({ op: "set", layer: -1, name: "opacity", value: Math.max(0.14, (active.opacity ?? 1) * (0.65 - 0.16 * (e - 1))) });
      ops.push({ op: "set", layer: -1, name: "start", value: (active.start || 0) + dt * e });
      ops.push({ op: "set", layer: -1, name: "duration", value: active.duration ?? -1 });
      ops = ops.concat(_texflowOpsForLayer(-1, st, ""));
    }
    return { ops: ops, notice: "Created " + count + " echo trail layer(s)" };
  }

  // Bake current Auto Lyric settings as keyframes onto exploded letter / GG stroke parts
  if (id === "bake_parts" && active) {
    const parts = _explodedChildren(ctx, active);
    if (parts.length === 0) return { notice: "Explode into Letters or GG Strokes first" };
    const mode = MODES[Math.round(Number(st.mode))] || "Slide";
    const order = ORDERS[Math.round(Number(st.order))] || "Start";
    const axis = AXES[Math.round(Number(st.axis))] || "Y";
    const dist = Number(st.distance) * 0.35;
    const len = Math.max(0.05, Number(st.length));
    const step = Math.max(0, Number(st.delay));
    const outOn = Number(st.out) >= 0.5;
    const alt = Number(st.alternate) >= 0.5;
    const x1 = Number(st.x1), y1 = Number(st.y1);
    const x2 = Number(st.x2), y2 = Number(st.y2);
    const kScale = Number(st.kanji_scale);
    const kDelay = Number(st.kanji_delay);
    const hDelay = Number(st.kana_delay);
    const scaleFrom = Number(st.scale_from);
    const rotFrom = Number(st.rotate_from);
    const opFrom = Number(st.opacity_from);
    const seed = Number(st.scatter_seed);
    const spread = Number(st.scatter_spread) * 0.4;

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
