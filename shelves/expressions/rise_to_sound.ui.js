// Custom Inspector card template for `rise_to_sound.js`.
// Demonstrates all third-party DX capabilities:
// - Standard SVG (`ui.svg`) with `var(--token)` skin colors
// - Live 24-band audio FFT spectrum (`ctx.audio`) when playing back an audio track
// - Ephemeral multi-handle drag state (`ctx.state.drag`: "lo" | "hi" | "pan")

function freqToU(hz) {
  const clamped = Math.max(20, Math.min(12000, hz));
  return Math.log(clamped / 20) / Math.log(12000 / 20);
}

function uToFreq(u) {
  const t = Math.max(0, Math.min(1, u));
  return Math.round(20 * Math.pow(12000 / 20, t));
}

function renderCard(ctx) {
  const p = ctx.params || {};
  const st = ctx.state || {};
  const lo = Math.max(20, Math.min(11800, Number(p.start ?? 20)));
  const hi = Math.max(lo + 20, Math.min(12000, Number(p.end ?? 2000)));
  const u0 = freqToU(lo);
  const u1 = freqToU(hi);
  const live = Array.isArray(ctx.audio) && ctx.audio.length >= 8 ? ctx.audio : null;
  const drag = st.drag || "";

  const bars = [];
  const count = live ? live.length : 24;
  const pitch = 260 / count;
  const barW = Math.max(3, pitch - 2.6);
  for (let i = 0; i < count; i++) {
    const bu = (i + 0.5) / count;
    const amp = live
      ? Math.max(0.06, Math.min(1, Number(live[i] ?? 0)))
      : (0.20 + 0.62 * Math.exp(-Math.pow((bu - 0.22) / 0.18, 2)) + 0.35 * Math.exp(-Math.pow((bu - 0.62) / 0.22, 2)));
    const inBand = bu >= u0 && bu <= u1;
    const h = amp * 58;
    const x = 10 + i * pitch;
    bars.push(`<rect x="${x.toFixed(1)}" y="${(80 - h).toFixed(1)}" width="${barW.toFixed(1)}" height="${h.toFixed(1)}" rx="1.6" fill="${inBand ? "url(#barOn)" : "var(--muted)"}" opacity="${inBand ? "0.95" : "0.26"}"/>`);
  }

  const bx = 10 + u0 * 260;
  const bw = Math.max(12, (u1 - u0) * 260);
  const bx2 = bx + bw;
  const loActive = drag === "lo" || drag === "pan";
  const hiActive = drag === "hi" || drag === "pan";

  const svg = `<svg viewBox="0 0 280 88" preserveAspectRatio="none">
    <defs>
      <linearGradient id="barOn" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color="var(--accent)"/>
        <stop offset="100%" stop-color="var(--blend)"/>
      </linearGradient>
      <linearGradient id="winFill" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color="var(--blend)" stop-opacity="0.24"/>
        <stop offset="100%" stop-color="var(--blend)" stop-opacity="0.03"/>
      </linearGradient>
    </defs>
    <g stroke="var(--border)" stroke-width="0.7" stroke-dasharray="3 3" opacity="0.6">
      <line x1="10" y1="30" x2="270" y2="30"/>
      <line x1="10" y1="55" x2="270" y2="55"/>
    </g>
    <rect x="${bx.toFixed(1)}" y="16" width="${bw.toFixed(1)}" height="64" rx="4" fill="url(#winFill)" stroke="var(--blend)" stroke-width="1.2" stroke-dasharray="4 2"/>
    ${bars.join("")}
    <line x1="${bx.toFixed(1)}" y1="16" x2="${bx.toFixed(1)}" y2="80" stroke="${loActive ? "var(--accent)" : "var(--blend)"}" stroke-width="${loActive ? "2.2" : "1.4"}"/>
    <line x1="${bx2.toFixed(1)}" y1="16" x2="${bx2.toFixed(1)}" y2="80" stroke="${hiActive ? "var(--accent)" : "var(--blend)"}" stroke-width="${hiActive ? "2.2" : "1.4"}"/>
    <circle cx="${bx.toFixed(1)}" cy="48" r="${loActive ? "4.6" : "3.6"}" fill="${loActive ? "var(--accent)" : "var(--blend)"}" stroke="var(--well)" stroke-width="1.2"/>
    <circle cx="${bx2.toFixed(1)}" cy="48" r="${hiActive ? "4.6" : "3.6"}" fill="${hiActive ? "var(--accent)" : "var(--blend)"}" stroke="var(--well)" stroke-width="1.2"/>
    <text x="10" y="12" fill="var(--blend)" font-size="9" font-family="Inter">${Math.round(lo)} Hz${live ? " · LIVE" : ""}</text>
    <text x="270" y="12" fill="var(--accent)" font-size="9" font-family="Inter" text-anchor="end">${Math.round(hi)} Hz</text>
  </svg>`;

  return {
    hide: ["start", "end"],
    ui: ui.column([
      ui.svg(88, svg, { id: "band", label: "Frequency Band (drag edges or center)", fit: "fill" }),
      ui.row([
        ui.button("Sub", "preset:sub"),
        ui.button("Bass", "preset:bass"),
        ui.button("Vocal", "preset:vocal"),
        ui.button("Full", "preset:full"),
      ]),
    ]),
  };
}

function onCardAction(action, ctx) {
  const p = (ctx && ctx.params) || {};
  const st = (ctx && ctx.state) || {};
  if (action.id === "band" && action.value) {
    const x = Math.max(0, Math.min(1, Number(action.value.x ?? 0.3)));
    const phase = action.value.phase || "down";
    const lo = Math.max(20, Math.min(11800, Number(p.start ?? 20)));
    const hi = Math.max(lo + 20, Math.min(12000, Number(p.end ?? 2000)));
    const u0 = freqToU(lo);
    const u1 = freqToU(hi);

    if (phase === "up") {
      return { state: { drag: null, anchor: null, span: null } };
    }

    let mode = st.drag;
    let span = typeof st.span === "number" ? st.span : (u1 - u0);
    let anchor = typeof st.anchor === "number" ? st.anchor : 0.5;
    if (phase === "down" || !mode) {
      const dLo = Math.abs(x - u0);
      const dHi = Math.abs(x - u1);
      if (dLo <= 0.08 && dLo <= dHi) {
        mode = "lo";
      } else if (dHi <= 0.08) {
        mode = "hi";
      } else if (x > u0 && x < u1) {
        mode = "pan";
        span = Math.max(0.06, u1 - u0);
        anchor = x - u0;
      } else {
        mode = "pan";
        span = Math.max(0.08, u1 - u0);
        anchor = span * 0.5;
      }
    }

    if (mode === "lo") {
      const nextLo = uToFreq(Math.min(u1 - 0.04, x));
      return { set: { start: nextLo }, state: { drag: "lo" } };
    }
    if (mode === "hi") {
      const nextHi = uToFreq(Math.max(u0 + 0.04, x));
      return { set: { end: nextHi }, state: { drag: "hi" } };
    }
    const nextU0 = Math.max(0, Math.min(1 - span, x - anchor));
    return {
      set: { start: uToFreq(nextU0), end: uToFreq(nextU0 + span) },
      state: { drag: "pan", span, anchor },
    };
  }
  if (action.id === "preset:sub") return { set: { start: 20, end: 180 } };
  if (action.id === "preset:bass") return { set: { start: 60, end: 500 } };
  if (action.id === "preset:vocal") return { set: { start: 300, end: 3400 } };
  if (action.id === "preset:full") return { set: { start: 20, end: 12000 } };
  return {};
}
