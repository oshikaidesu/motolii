// Custom Inspector card template for `rise_to_sound.js`.
// Uses standard SVG (`ui.svg`) for a log-scaled 20Hz–12kHz spectrum with gradient band highlight.

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
  const lo = Math.max(20, Math.min(12000, Number(p.start ?? 20)));
  const hi = Math.max(lo + 20, Math.min(12000, Number(p.end ?? 2000)));
  const u0 = freqToU(lo);
  const u1 = freqToU(hi);

  const bars = [];
  const count = 24;
  for (let i = 0; i < count; i++) {
    const bu = (i + 0.5) / count;
    const amp = 0.20 + 0.62 * Math.exp(-Math.pow((bu - 0.22) / 0.18, 2)) + 0.35 * Math.exp(-Math.pow((bu - 0.62) / 0.22, 2));
    const inBand = bu >= u0 && bu <= u1;
    const h = amp * 58;
    const x = 10 + i * 10.9;
    bars.push(`<rect x="${x.toFixed(1)}" y="${(80 - h).toFixed(1)}" width="8" height="${h.toFixed(1)}" rx="1.8" fill="${inBand ? "url(#barOn)" : "var(--muted)"}" opacity="${inBand ? "0.95" : "0.26"}"/>`);
  }

  const bx = 10 + u0 * 260;
  const bw = Math.max(12, (u1 - u0) * 260);
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
    <text x="10" y="12" fill="var(--blend)" font-size="9" font-family="Inter">${Math.round(lo)} Hz</text>
    <text x="270" y="12" fill="var(--accent)" font-size="9" font-family="Inter" text-anchor="end">${Math.round(hi)} Hz</text>
  </svg>`;

  return {
    hide: ["start", "end"],
    ui: ui.column([
      ui.svg(88, svg, { id: "band", label: "Frequency Band (20Hz – 12kHz)", fit: "fill" }),
      ui.row([
        ui.button("Sub", "preset:sub"),
        ui.button("Bass", "preset:bass"),
        ui.button("Vocal", "preset:vocal"),
        ui.button("Full", "preset:full"),
      ]),
    ]),
  };
}

function onCardAction(action) {
  if (action.id === "band" && action.value) {
    const center = Math.max(0.05, Math.min(0.95, Number(action.value.x ?? 0.3)));
    const lo = uToFreq(Math.max(0, center - 0.18));
    const hi = uToFreq(Math.min(1, center + 0.18));
    return { set: { start: lo, end: hi } };
  }
  if (action.id === "preset:sub") return { set: { start: 20, end: 180 } };
  if (action.id === "preset:bass") return { set: { start: 60, end: 500 } };
  if (action.id === "preset:vocal") return { set: { start: 300, end: 3400 } };
  if (action.id === "preset:full") return { set: { start: 20, end: 12000 } };
  return {};
}
