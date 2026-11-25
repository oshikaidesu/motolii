// Inspector Vism card for the `Kinetic Array` multi-code pack (motion.js + aura.fs).
// Visualizes the live array wave/spread/tilt/aura and lets the user drag directly.

function _clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v));
}

function renderCard(ctx) {
  const p = ctx.params || {};
  const t = Number(ctx.time || 0);
  const spread = Number(p.spread ?? 0.22);
  const wave = Number(p.wave ?? 0.14);
  const spin = Number(p.spin ?? 6);
  const tempo = Number(p.tempo ?? 0.45);
  const phase = Number(p.phase ?? 0.22);
  const fade = Number(p.fade ?? 0.15);
  const glow = Number(p.aura_glow ?? p.glow ?? 0.35);
  const halo = Number(p.aura_halo ?? p.halo ?? 0.012);

  const lay = ctx.layer || {};
  const all = ctx.layers || [];
  const childCount = all.filter((l) => l.parent === lay.id).length;
  const n = childCount >= 2 ? Math.min(9, childCount) : 5;
  const center = (n - 1) * 0.5;

  const nodes = [];
  const pts = [];
  for (let i = 0; i < n; i++) {
    const rel = i - center;
    const norm = n > 1 ? rel / center : 0;
    const ang = t * Math.PI * 2 * tempo - i * phase * Math.PI * 2;
    const s = Math.sin(ang);
    const c = Math.cos(ang);
    const px = 140 + rel * spread * 54;
    const py = 54 - s * wave * 48;
    const rot = c * spin;
    const op = _clamp(1 - Math.abs(norm) * fade, 0.15, 1);
    const r = 7.5 + glow * 6.5;
    pts.push(`${px.toFixed(1)},${py.toFixed(1)}`);
    nodes.push(
      `<g transform="translate(${px.toFixed(1)},${py.toFixed(1)}) rotate(${rot.toFixed(1)})" opacity="${op.toFixed(2)}">
        <circle r="${r.toFixed(1)}" fill="var(--blend)" opacity="${(0.18 * glow).toFixed(2)}"/>
        <rect x="-7" y="-5" width="14" height="10" rx="2.5" fill="var(--surface)" stroke="var(--accent)" stroke-width="1.4"/>
      </g>`
    );
  }

  const svg = `<svg viewBox="0 0 280 108">
    <line x1="16" y1="54" x2="264" y2="54" stroke="var(--border)" stroke-width="0.9" stroke-dasharray="3 3"/>
    <polyline points="${pts.join(" ")}" fill="none" stroke="var(--blend)" stroke-width="1.3" opacity="0.7"/>
    ${nodes.join("")}
    <text x="10" y="14" fill="var(--muted)" font-size="8.5" font-family="Inter">${childCount >= 2 ? childCount + " group children" : "array preview"} · drag XY = spread / wave</text>
  </svg>`;

  return {
    hide: ["spread", "wave", "spin", "tempo", "phase", "fade", "aura_glow", "aura_halo"],
    surface: {
      bg: "#10161E",
      bg2: "#16202C",
      fg: "#E8EEF5",
      muted: "#8C9AA8",
      accent: "#4ECDC4",
      border: "#263445",
      borderWidth: 1.2,
      radius: 10,
      pad: 10,
      gap: 8,
    },
    ui: ui.column([
      ui.row([
        ui.badge("VISM PACK", {
          style: {
            bg: "#173136",
            fg: "#4ECDC4",
            border: "#4ECDC455",
            borderWidth: 1,
            radius: 4,
            mono: true,
            fontSize: 9,
          },
        }),
        ui.spacer(6),
        ui.text("motion.js + aura.fs", { muted: true }),
      ]),
      ui.svg(108, svg, { id: "stage_xy", label: "Array Wave & Spread" }),
      ui.row([
        ui.knob("TEMPO", tempo, { id: "tempo", min: 0, max: 2, def: 0.45, step: 0.01, dec: 2, unit: "Hz", look: "arc", size: 40, color: "#4ECDC4" }),
        ui.knob("PHASE", phase, { id: "phase", min: 0, max: 1, def: 0.22, step: 0.01, dec: 2, look: "arc", size: 40, color: "#FF9F43" }),
        ui.knob("SPIN", spin, { id: "spin", min: -45, max: 45, def: 6, step: 0.5, dec: 1, unit: "°", look: "arc", size: 40, color: "#E8EEF5" }),
        ui.knob("GLOW", glow, { id: "aura_glow", min: 0, max: 1.2, def: 0.35, step: 0.01, dec: 2, look: "arc", size: 40, color: "#7C9CBF" }),
      ]),
      ui.row([
        ui.button("Ripple", "preset:ripple", { accent: true }),
        ui.button("Fan", "preset:fan"),
        ui.button("Subtle", "preset:subtle"),
      ]),
    ]),
  };
}

function onCardAction(action, ctx) {
  if (action.id === "stage_xy" && action.value) {
    const x = _clamp(Number(action.value.x ?? 0.5), 0, 1);
    const y = _clamp(Number(action.value.y ?? 0.5), 0, 1);
    return {
      set: {
        spread: Math.round(((x - 0.5) * 2.4) * 100) / 100,
        wave: Math.round(((1 - y) * 0.7) * 100) / 100,
      },
    };
  }
  if (action.id === "preset:ripple") {
    return { set: { spread: 0.22, wave: 0.16, spin: 6, tempo: 0.5, phase: 0.22, aura_glow: 0.4 } };
  }
  if (action.id === "preset:fan") {
    return { set: { spread: 0.42, wave: 0.08, spin: 18, tempo: 0.3, phase: 0.35, aura_glow: 0.55 } };
  }
  if (action.id === "preset:subtle") {
    return { set: { spread: 0.08, wave: 0.05, spin: 2, tempo: 0.28, phase: 0.18, aura_glow: 0.2 } };
  }
  return {};
}
