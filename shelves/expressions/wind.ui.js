// Custom Inspector card template for Jolt Physics `wind.js`.
// Uses standard SVG (`ui.svg`) for a true-circle 2D force compass with bending streamlines.

function renderCard(ctx) {
  const p = ctx.params || {};
  const wind = Math.max(-50, Math.min(50, Number(p.wind ?? 0)));
  const lift = Math.max(-50, Math.min(50, Number(p.lift ?? 0)));
  const cx = 140, cy = 48, r = 36;
  const vx = cx + (wind / 50) * r;
  const vy = cy - (lift / 50) * r;
  const mag = Math.min(1, Math.hypot(wind, lift) / 50);

  const sy = -(lift / 50) * 14;
  const streams = [24, 48, 72].map((ry) => {
    const y0 = (ry - sy * 0.45).toFixed(1);
    const y1 = (ry + sy * 0.75).toFixed(1);
    const ax = wind >= 0 ? 246 : 34;
    const dir = wind >= 0 ? -5 : 5;
    return `<path d="M 34 ${y0} C 106 ${(ry - sy * 0.1).toFixed(1)}, 174 ${(ry + sy * 0.25).toFixed(1)}, 246 ${y1}" fill="none" stroke="var(--layout)" stroke-width="1.1" opacity="${(0.2 + mag * 0.5).toFixed(2)}"/>`
      + (Math.abs(wind) > 3 ? `<path d="M ${(ax + dir).toFixed(1)} ${(Number(y1) - 3).toFixed(1)} L ${ax} ${y1} L ${(ax + dir).toFixed(1)} ${(Number(y1) + 3).toFixed(1)}" fill="none" stroke="var(--layout)" stroke-width="1.1" opacity="${(0.25 + mag * 0.55).toFixed(2)}"/>` : "");
  }).join("");

  const svg = `<svg viewBox="0 0 280 96">
    <defs>
      <radialGradient id="windGlow" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="var(--layout)" stop-opacity="${(0.08 + mag * 0.18).toFixed(2)}"/>
        <stop offset="100%" stop-color="var(--layout)" stop-opacity="0"/>
      </radialGradient>
    </defs>
    <circle cx="${cx}" cy="${cy}" r="${r + 8}" fill="url(#windGlow)"/>
    <circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="var(--border)" stroke-width="1"/>
    <circle cx="${cx}" cy="${cy}" r="${r * 0.5}" fill="none" stroke="var(--border)" stroke-width="0.8" stroke-dasharray="3 3" opacity="0.7"/>
    <line x1="${cx - r - 6}" y1="${cy}" x2="${cx + r + 6}" y2="${cy}" stroke="var(--border)" stroke-width="0.8" opacity="0.55"/>
    <line x1="${cx}" y1="${cy - r - 4}" x2="${cx}" y2="${cy + r + 4}" stroke="var(--border)" stroke-width="0.8" opacity="0.55"/>
    ${streams}
    <line x1="${cx}" y1="${cy}" x2="${vx.toFixed(1)}" y2="${vy.toFixed(1)}" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
    <circle cx="${cx}" cy="${cy}" r="2.5" fill="var(--muted)"/>
    <circle cx="${vx.toFixed(1)}" cy="${vy.toFixed(1)}" r="8" fill="var(--accent)" fill-opacity="0.22"/>
    <circle cx="${vx.toFixed(1)}" cy="${vy.toFixed(1)}" r="4.2" fill="var(--accent)" stroke="var(--well)" stroke-width="1.4"/>
    <text x="10" y="15" fill="var(--text)" font-size="9.5" font-family="Inter">Wind ${Math.round(wind)}N</text>
    <text x="270" y="15" fill="var(--layout)" font-size="9.5" font-family="Inter" text-anchor="end">Lift ${Math.round(lift)}N</text>
  </svg>`;

  return {
    hide: ["wind", "lift"],
    ui: ui.column([
      ui.svg(96, svg, { id: "vector", label: "Jolt Force Vector (N)" }),
      ui.row([
        ui.button("Gust →", "preset:gust", { accent: wind > 10 }),
        ui.button("Updraft ↑", "preset:up"),
        ui.button("Calm", "preset:calm"),
      ]),
    ]),
  };
}

function onCardAction(action) {
  if (action.id === "vector" && action.value) {
    const w = Math.round(((Number(action.value.x ?? 0.5) - 0.5) / 0.28) * 50 * 10) / 10;
    const l = Math.round(((0.5 - Number(action.value.y ?? 0.5)) / 0.38) * 50 * 10) / 10;
    return {
      set: {
        wind: Math.max(-50, Math.min(50, w)),
        lift: Math.max(-50, Math.min(50, l)),
      },
    };
  }
  if (action.id === "preset:gust") return { set: { wind: 24, lift: 6 } };
  if (action.id === "preset:up") return { set: { wind: 0, lift: 22 } };
  if (action.id === "preset:calm") return { set: { wind: 0, lift: 0 } };
  return {};
}
