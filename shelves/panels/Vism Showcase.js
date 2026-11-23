// --title: Vism Showcase
// --about: Design vectors for Vism custom panels (Flat-Pop, Synth 3D, Hardware, Beat Sync, GPU Shader, Rig Picker, Pro Curve, Kawaii)
// --acts: Panel
// --tone: accent

// Live interactive gallery demonstrating Motolii's VST-grade custom UI primitives:
// `ui.box`, `ui.stack`, `ui.knob`, `ui.scene3d`, `ui.svg`, and custom faceplates.
function render(ctx) {
  const s = ctx.state || {};
  const skin = String(s.skin || "Pop 3D");
  const yaw = Number(s.yaw ?? 0.62);
  const pitch = Number(s.pitch ?? 0.38);
  const a = Number(s.a ?? 0.68);
  const b = Number(s.b ?? 0.42);
  const c = Number(s.c ?? 0.80);
  const mode = String(s.mode || "JELLY");

  const picker = ui.select("Vector", skin, [
    "Pop 3D",
    "Wavetable",
    "Hardware",
    "Beat Sync",
    "GPU Shader",
    "Rig Picker",
    "Pro Curve",
    "Kawaii",
  ], { id: "skin" });

  let card;
  if (skin === "Pop 3D") {
    card = ui.box([
      ui.row([
        ui.badge("NEUBRUTAL · 3D", {
          style: { bg: "#FF3B7F", fg: "#FFFFFF", border: "#141414", borderWidth: 2, radius: 99, shadow: { x: 2, y: 2, blur: 0, color: "#141414" } },
        }),
        ui.spacer(4),
        ui.text("DRAG TO SPIN", {
          bold: true,
          style: { fg: "#141414", fontSize: 9.5, letterSpacing: 1.0 },
        }),
      ]),
      ui.stack([
        ui.scene3d(132, {
          id: "orbit",
          shape: "cube",
          look: "toon",
          yaw: yaw,
          pitch: pitch,
          zoom: 0.92,
          color: "#00D4FF",
          color2: "#B8FF2C",
          outline: "#141414",
          outlineWidth: 2.2,
          bg: "#FFFFFF",
          grid: true,
          objects: [
            { shape: "ring", x: 0, y: 0, z: 0, scale: 1.28, rx: 1.1, ry: yaw * 0.5, color: "#FF3B7F", look: "toon" },
          ],
          style: {
            border: "#141414",
            borderWidth: 2.5,
            radius: 10,
            shadow: { x: 4, y: 4, blur: 0, color: "#141414" },
          },
        }),
        ui.badge("POP!", {
          align: "topRight",
          inset: 8,
          style: { bg: "#FFE600", fg: "#141414", border: "#141414", borderWidth: 2, radius: 6, shadow: { x: 2, y: 2, blur: 0, color: "#141414" } },
        }),
      ]),
      ui.row([
        ui.knob("BOUNCE", a, { id: "a", min: 0, max: 1, def: 0.68, look: "pop", size: 46, color: "#FF3B7F", capColor: "#FFFFFF", borderColor: "#141414" }),
        ui.knob("SQUASH", b, { id: "b", min: 0, max: 1, def: 0.42, look: "pop", size: 46, color: "#00D4FF", capColor: "#FFFFFF", borderColor: "#141414" }),
        ui.knob("POP", c, { id: "c", min: 0, max: 1, def: 0.80, look: "pop", size: 46, color: "#B8FF2C", capColor: "#FFFFFF", borderColor: "#141414" }),
      ]),
      ui.select("", mode, ["JELLY", "COMIC", "SPRING"], {
        id: "mode",
        style: {
          bg: "#FFFFFF",
          fg: "#141414",
          accent: "#FF3B7F",
          border: "#141414",
          borderWidth: 2,
          radius: 8,
          height: 26,
          shadow: { x: 2, y: 2, blur: 0, color: "#141414" },
        },
      }),
    ], {
      bg: "#FFF4C4",
      fg: "#141414",
      muted: "#3B3520",
      accent: "#FF3B7F",
      border: "#141414",
      borderWidth: 2.5,
      radius: 14,
      pad: 12,
      gap: 9,
      shadow: { x: 5, y: 5, blur: 0, color: "#141414" },
    });
  } else if (skin === "Wavetable") {
    card = ui.box([
      ui.stack([
        ui.scene3d(132, {
          id: "orbit",
          shape: "wavetable",
          look: "holo",
          yaw: yaw,
          pitch: pitch,
          zoom: 1.0,
          color: "#00F0FF",
          color2: "#A855F7",
          bg: "#070B12",
          bg2: "#101829",
          warp: a,
          phase: b * 6.28,
          harmonics: 1 + c * 4,
          style: {
            border: "#00F0FF55",
            borderWidth: 1.2,
            radius: 8,
            shadow: { x: 0, y: 0, blur: 14, color: "#00F0FF33" },
          },
        }),
        ui.badge("WT-3D · LIVE", {
          align: "topLeft",
          inset: 7,
          style: { bg: "#0B1628CC", fg: "#00F0FF", border: "#00F0FF88", borderWidth: 1, radius: 4, mono: true, fontSize: 8.5 },
        }),
      ]),
      ui.row([
        ui.knob("WARP", a, { id: "a", min: 0, max: 1, def: 0.68, look: "arc", size: 42, color: "#00F0FF", capColor: "#141B29", trackColor: "#1E293B" }),
        ui.knob("PHASE", b, { id: "b", min: 0, max: 1, def: 0.42, look: "arc", size: 42, color: "#A855F7", capColor: "#141B29", trackColor: "#1E293B" }),
        ui.knob("HARM", c, { id: "c", min: 0, max: 1, def: 0.80, look: "arc", size: 42, color: "#38BDF8", capColor: "#141B29", trackColor: "#1E293B" }),
      ]),
      ui.meter(a, { label: "HARMONIC ENERGY", style: { bg: "#111827", accent: "#00F0FF", height: 7, radius: 99 } }),
    ], {
      bg: "#0D1119",
      bg2: "#151D2E",
      fg: "#E2F4FF",
      muted: "#7D93B0",
      accent: "#00F0FF",
      border: "#25324A",
      borderWidth: 1.2,
      radius: 10,
      pad: 12,
      gap: 8,
      mono: true,
    });
  } else if (skin === "Hardware") {
    card = ui.box([
      ui.box([
        ui.row([
          ui.text("OP-FIELD 3D", { bold: true, style: { fg: "#F4F4EE", fontSize: 9.5, letterSpacing: 1.2, mono: true } }),
          ui.spacer(4),
          ui.text(`Y:${(yaw * 57.3).toFixed(0)}° P:${(pitch * 57.3).toFixed(0)}°`, { style: { fg: "#FF521B", fontSize: 9, mono: true } }),
        ]),
        ui.scene3d(106, {
          id: "orbit",
          shape: "icosahedron",
          look: "wireframe",
          yaw: yaw,
          pitch: pitch,
          zoom: 0.96,
          color: "#F4F4EE",
          axes: true,
          framed: false,
        }),
      ], { bg: "#111311", border: "#2B2E2B", borderWidth: 1.5, radius: 6, pad: 8, gap: 4 }),
      ui.row([
        ui.knob("DRIVE", a, { id: "a", min: 0, max: 1, def: 0.68, look: "hardware", size: 42, color: "#FF521B" }),
        ui.knob("TILT", b, { id: "b", min: 0, max: 1, def: 0.42, look: "hardware", size: 42, color: "#246BCE" }),
        ui.knob("SNAP", c, { id: "c", min: 0, max: 1, def: 0.80, look: "hardware", size: 42, color: "#E5A918" }),
      ]),
    ], {
      bg: "#ECECE6",
      fg: "#1D1D1B",
      muted: "#6B6B64",
      accent: "#FF521B",
      border: "#C7C7BD",
      borderWidth: 1.5,
      radius: 10,
      pad: 12,
      gap: 10,
    });
  } else if (skin === "Beat Sync") {
    const wf = Array.isArray(ctx.waveform) && ctx.waveform.length >= 8
      ? ctx.waveform
      : Array.from({ length: 48 }, (_, i) => 0.18 + 0.35 * Math.abs(Math.sin(i * 0.45 + ctx.time * 4)) + ((i % 12 === 2) ? 0.4 : 0));
    const steps = Array.isArray(s.steps) ? s.steps : [1, 0, 0.5, 0, 1, 1, 0, 0.5, 1, 0, 0.8, 0, 1, 0, 0.5, 1];
    const bpm = Number(ctx.bpm || 128);
    const activeStep = Math.floor((ctx.time || 0) * (bpm / 60) * 4) % 16;
    const thr = Number(s.thr ?? 0.62);
    const audioPeak = Array.isArray(ctx.audio) && ctx.audio.length ? Math.max(...ctx.audio) : a;
    card = ui.box([
      ui.row([
        ui.badge(`${Math.round(bpm)} BPM`, { style: { bg: "#FF5E3A", fg: "#FFFFFF", borderWidth: 0, radius: 4, mono: true } }),
        ui.spacer(),
        ui.text(`THR ${Math.round(thr * 100)}%`, { style: { fg: "#FFB547", mono: true, fontSize: 9 } }),
      ]),
      ui.waveform(74, wf, {
        id: "wave",
        playhead: 0.5,
        threshold: thr,
        strikes: [0.16, 0.42, 0.68, 0.90],
        color: "#38BDF8",
        peakColor: "#FF5E3A",
        style: { bg: "#0A0D13", border: "#273046", radius: 6 },
      }),
      ui.sequencer(steps, {
        id: "seq",
        label: "16-STEP BEAT TRIGGER",
        cols: 8,
        activeStep: activeStep,
        color: "#FF5E3A",
        style: { bg: "#0D1018", border: "#293247", radius: 4, height: 22 },
      }),
      ui.vu(audioPeak, { right: audioPeak * 0.92, peak: Math.min(1, audioPeak + 0.12), label: "STEREO LEVEL", segments: 18 }),
    ], {
      bg: "#11141C", bg2: "#1A1F2E", fg: "#EDF2FF", muted: "#818EA8",
      accent: "#FF5E3A", border: "#2C3448", borderWidth: 1.4, radius: 10, pad: 10, gap: 8, mono: true,
    });
  } else if (skin === "GPU Shader") {
    const preset = String(s.shaderPreset || "metaball");
    const stops = Array.isArray(s.stops) ? s.stops : [
      { pos: 0.0, color: "#FF4DCA" },
      { pos: 0.5, color: "#8B5CF6" },
      { pos: 1.0, color: "#38BDF8" },
    ];
    card = ui.box([
      ui.shader(124, preset, {
        id: "shader",
        time: Number(ctx.time || 1.2),
        paramA: a,
        paramB: b,
        mouseX: Number(s.mx ?? 0.6),
        mouseY: Number(s.my ?? 0.45),
        color: stops[0]?.color || "#FF4DCA",
        color2: stops[stops.length - 1]?.color || "#38BDF8",
        color3: stops[1]?.color || "#8B5CF6",
        style: { border: "#E879F966", borderWidth: 1.4, radius: 8 },
      }),
      ui.gradient(stops, { id: "grad", label: "PALETTE STOPS", height: 20 }),
      ui.row([
        ui.knob("MORPH", a, { id: "a", min: 0, max: 1, def: 0.68, look: "arc", size: 40, color: "#FF4DCA", capColor: "#1F1830" }),
        ui.knob("WARP", b, { id: "b", min: 0, max: 1, def: 0.42, look: "arc", size: 40, color: "#38BDF8", capColor: "#1F1830" }),
        ui.knob("GLOW", c, { id: "c", min: 0, max: 1, def: 0.80, look: "arc", size: 40, color: "#A78BFA", capColor: "#1F1830" }),
      ]),
      ui.select("", preset, ["holo", "metaball", "vhs", "scope", "aurora", "grid"], {
        id: "shaderPreset",
        style: { bg: "#141022", fg: "#B4A4D4", accent: "#E879F9", border: "#382C54", radius: 5, height: 22 },
      }),
    ], {
      bg: "#12101A", bg2: "#1B1628", fg: "#F5ECFF", muted: "#9A8CB5",
      accent: "#E879F9", border: "#382C54", borderWidth: 1.4, radius: 12, pad: 10, gap: 8,
    });
  } else if (skin === "Rig Picker") {
    const pins = Array.isArray(s.pins) ? s.pins : [
      { id: "head", label: "Head", x: 0.50, y: 0.24, color: "#FF66A8", active: true },
      { id: "eyes", label: "Eyes", x: 0.36, y: 0.42, color: "#38BDF8" },
      { id: "mouth", label: "Mouth", x: 0.50, y: 0.55, color: "#F59E0B" },
      { id: "hair", label: "Hair", x: 0.26, y: 0.66, color: "#A855F7" },
      { id: "body", label: "Body", x: 0.50, y: 0.80, color: "#10B981" },
    ];
    const rigSvg = `<svg viewBox="0 0 220 156"><circle cx="110" cy="76" r="64" fill="#181C28" stroke="#2D354C" stroke-dasharray="3 3"/><path d="M62 154 C64 118 82 104 110 104 C138 104 156 118 158 154 Z" fill="#32394E"/><ellipse cx="110" cy="64" rx="30" ry="33" fill="#F7DDD0"/><path d="M78 58 C82 28 138 28 142 58 C134 45 122 44 110 52 C98 44 86 46 78 58 Z" fill="#FF66A8"/></svg>`;
    card = ui.box([
      ui.picker(148, pins, { id: "rig", label: "DRAG CHARACTER PINS", svg: rigSvg, style: { bg: "#10131C", border: "#2D354C", radius: 8 } }),
      ui.row([
        ui.knob("BLINK", a, { id: "a", min: 0, max: 1, def: 0.2, look: "minimal", size: 38, color: "#38BDF8" }),
        ui.knob("SMILE", b, { id: "b", min: 0, max: 1, def: 0.78, look: "minimal", size: 38, color: "#FF66A8" }),
        ui.knob("SWAY", c, { id: "c", min: 0, max: 1, def: 0.62, look: "minimal", size: 38, color: "#A855F7" }),
      ]),
    ], {
      bg: "#191D28", bg2: "#12151E", fg: "#F1F5FF", muted: "#8E99B5",
      accent: "#FF66A8", border: "#323A52", borderWidth: 1.4, radius: 12, pad: 10, gap: 8,
    });
  } else if (skin === "Pro Curve") {
    const pts = Array.isArray(s.pts) ? s.pts : [
      { x: 0.04, y: 0.35 }, { x: 0.28, y: 0.78 }, { x: 0.54, y: 0.42 }, { x: 0.78, y: 0.86 }, { x: 0.96, y: 0.60 },
    ];
    card = ui.box([
      ui.curve(92, pts, { id: "eq", label: "RESPONSE CURVE (DRAG NODES)", color: "#F59E0B", style: { bg: "#0A0C10", border: "#272D38", radius: 6 } }),
      ui.row([
        ui.fader("SUB", a, { id: "a", min: 0, max: 1, def: 0.68, height: 92, color: "#F59E0B" }),
        ui.fader("LOW", b, { id: "b", min: 0, max: 1, def: 0.42, height: 92, color: "#38BDF8" }),
        ui.fader("MID", c, { id: "c", min: 0, max: 1, def: 0.80, height: 92, color: "#A855F7" }),
      ]),
      ui.vu(a, { right: c, peak: Math.max(a, c), segments: 18 }),
    ], {
      bg: "#15181E", bg2: "#0E1015", fg: "#E8EEF5", muted: "#7F8B9C",
      accent: "#F59E0B", border: "#2A303C", borderWidth: 1.4, radius: 10, pad: 10, gap: 8, mono: true,
    });
  } else if (skin === "Studio") {
    const lx = Math.cos(a * 6.28) * 1.15;
    const lz = Math.sin(a * 6.28) * 1.15;
    card = ui.box([
      ui.scene3d(132, {
        id: "orbit",
        shape: "sphere",
        look: "studio",
        yaw: yaw,
        pitch: pitch,
        zoom: 0.92,
        color: "#6C7A94",
        rimColor: "#48C9FF",
        lightYaw: a * 6.28,
        lightPitch: 0.25 + b * 1.1,
        bg: "#13161D",
        bg2: "#0B0D12",
        grid: true,
        shadow: true,
        objects: [
          { shape: "icosahedron", x: lx, y: 0.55 + (b - 0.5) * 0.8, z: lz, scale: 0.14, color: "#FFB547", look: "toon" },
        ],
        style: { border: "#2B313D", borderWidth: 1, radius: 8 },
      }),
      ui.row([
        ui.knob("KEY AZ", a, { id: "a", min: 0, max: 1, def: 0.68, look: "arc", size: 42, color: "#FFB547", capColor: "#1D212B" }),
        ui.knob("KEY EL", b, { id: "b", min: 0, max: 1, def: 0.42, look: "arc", size: 42, color: "#48C9FF", capColor: "#1D212B" }),
        ui.knob("GLOSS", c, { id: "c", min: 0, max: 1, def: 0.80, look: "arc", size: 42, color: "#E2E8F0", capColor: "#1D212B" }),
      ]),
    ], {
      bg: "#191C24",
      bg2: "#111319",
      fg: "#F1F5F9",
      muted: "#8B95A8",
      accent: "#FFB547",
      border: "#2E3442",
      borderWidth: 1.2,
      radius: 10,
      pad: 12,
      gap: 9,
    });
  } else if (skin === "Retro 98") {
    card = ui.box([
      ui.box([
        ui.text("GLITCH98.VST — [CRT 3D]", { bold: true, style: { fg: "#FFFFFF", fontSize: 10, mono: true } }),
      ], { bg: "#0A246A", bg2: "#3A6EA5", gradAngle: 0, radius: 0, padX: 8, padY: 4, borderWidth: 0 }),
      ui.scene3d(118, {
        id: "orbit",
        shape: "torus",
        look: "wireframe",
        yaw: yaw,
        pitch: pitch,
        zoom: 0.96,
        color: "#00FF66",
        bg: "#051409",
        grid: true,
        style: { border: "#404040", borderWidth: 2, radius: 0 },
      }),
      ui.row([
        ui.button("8-BIT", "m1", { style: { bg: "#D4D0C8", fg: "#000000", border: "#404040", borderWidth: 1.5, radius: 0, mono: true } }),
        ui.button("CRT", "m2", { style: { bg: "#0A246A", fg: "#FFFFFF", border: "#000000", borderWidth: 1.5, radius: 0, mono: true } }),
        ui.button("VHS", "m3", { style: { bg: "#D4D0C8", fg: "#000000", border: "#404040", borderWidth: 1.5, radius: 0, mono: true } }),
      ]),
    ], {
      bg: "#D4D0C8",
      fg: "#000000",
      muted: "#404040",
      accent: "#0A246A",
      border: "#404040",
      borderWidth: 2,
      radius: 0,
      pad: 8,
      gap: 7,
      shadow: { x: 3, y: 3, blur: 0, color: "#00000088" },
    });
  } else {
    card = ui.box([
      ui.stack([
        ui.scene3d(128, {
          id: "orbit",
          shape: "crystal",
          look: "studio",
          yaw: yaw,
          pitch: pitch,
          zoom: 0.96,
          color: "#FF85C0",
          color2: "#93B4FF",
          rimColor: "#FFFFFF",
          ambientColor: "#F6D5FF",
          ambient: 0.58,
          gloss: 0.95,
          bg: "#FFF5FA",
          bg2: "#EEF2FF",
          shadow: true,
          style: { border: "#FFB8DA", borderWidth: 1.6, radius: 14 },
        }),
        ui.badge("★ PRISM", {
          align: "topLeft",
          inset: 8,
          style: { bg: "#FFFFFFE6", fg: "#E14B95", border: "#FFB8DA", borderWidth: 1.4, radius: 99 },
        }),
      ]),
      ui.row([
        ui.knob("PRISM", a, { id: "a", min: 0, max: 1, def: 0.68, look: "minimal", size: 42, color: "#FF66A8", trackColor: "#F9D5E8" }),
        ui.knob("BLOOM", b, { id: "b", min: 0, max: 1, def: 0.42, look: "minimal", size: 42, color: "#9C7BFF", trackColor: "#E4DCFF" }),
        ui.knob("GLOW", c, { id: "c", min: 0, max: 1, def: 0.80, look: "minimal", size: 42, color: "#5CC8FF", trackColor: "#D6F0FF" }),
      ]),
    ], {
      bg: "#FFF0F7",
      bg2: "#EEF2FF",
      fg: "#4A2740",
      muted: "#9B6D8E",
      accent: "#FF66A8",
      border: "#FFB8DA",
      borderWidth: 1.8,
      radius: 18,
      pad: 12,
      gap: 9,
      shadow: { x: 0, y: 6, blur: 16, color: "#FF66A833" },
    });
  }

  return ui.column([picker, card]);
}

function onAction(action, ctx) {
  const s = (ctx && ctx.state) || {};
  if (action.id === "skin") return { state: { skin: String(action.value) } };
  if (action.id === "mode") return { state: { mode: String(action.value) } };
  if (action.id === "shaderPreset") return { state: { shaderPreset: String(action.value) } };
  if (action.id === "a" || action.id === "b" || action.id === "c") {
    return { state: { [action.id]: Number(action.value) } };
  }
  if (action.id === "orbit" && action.value) {
    return { state: { yaw: Number(action.value.yaw), pitch: Number(action.value.pitch) } };
  }
  if (action.id === "wave" && action.value) {
    return { state: { thr: Number(action.value.threshold ?? 0.62) } };
  }
  if (action.id === "seq" && action.value && Array.isArray(action.value.steps)) {
    return { state: { steps: action.value.steps } };
  }
  if (action.id === "shader" && action.value) {
    return { state: { mx: Number(action.value.x), my: Number(action.value.y) } };
  }
  if (action.id === "grad" && action.value && Array.isArray(action.value.stops)) {
    return { state: { stops: action.value.stops } };
  }
  if (action.id === "eq" && action.value && Array.isArray(action.value.points)) {
    return { state: { pts: action.value.points } };
  }
  if (action.id === "rig" && action.value) {
    const cur = Array.isArray(s.pins) ? s.pins : [
      { id: "head", label: "Head", x: 0.50, y: 0.24, color: "#FF66A8", active: true },
      { id: "eyes", label: "Eyes", x: 0.36, y: 0.42, color: "#38BDF8" },
      { id: "mouth", label: "Mouth", x: 0.50, y: 0.55, color: "#F59E0B" },
      { id: "hair", label: "Hair", x: 0.26, y: 0.66, color: "#A855F7" },
      { id: "body", label: "Body", x: 0.50, y: 0.80, color: "#10B981" },
    ];
    const next = cur.map((p) => p.id === action.value.pin
      ? Object.assign({}, p, { x: Number(action.value.x), y: Number(action.value.y), active: true })
      : Object.assign({}, p, { active: false }));
    return { state: { pins: next } };
  }
  return {};
}
