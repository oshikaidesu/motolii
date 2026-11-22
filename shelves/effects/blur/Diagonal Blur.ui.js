// Sidecar custom Inspector card UI for `Diagonal Blur.fs`.
// Uses standard SVG (`ui.svg`) for a true-circle polar compass + directional smear gradient.

function renderCard(ctx) {
  const p = ctx.params || {};
  const width = Math.max(0, Math.min(1, Number(p.width ?? 0)));
  const angle = Number(p.angle ?? 0.125);
  const deg = angle * 180;
  const rad = Math.PI * angle;
  const cx = 140, cy = 44, r = 37;
  const span = width * r;
  const dx = Math.cos(rad) * span;
  const dy = Math.sin(rad) * span;

  const svg = `<svg viewBox="0 0 280 88">
    <defs>
      <linearGradient id="smear" x1="0" y1="0" x2="1" y2="0">
        <stop offset="0%" stop-color="var(--blend)" stop-opacity="0"/>
        <stop offset="50%" stop-color="var(--blend)" stop-opacity="0.45"/>
        <stop offset="100%" stop-color="var(--blend)" stop-opacity="0"/>
      </linearGradient>
    </defs>
    <circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="var(--border)" stroke-width="1"/>
    <circle cx="${cx}" cy="${cy}" r="${r * 0.5}" fill="none" stroke="var(--border)" stroke-width="0.8" stroke-dasharray="3 3" opacity="0.7"/>
    <line x1="${cx - r - 6}" y1="${cy}" x2="${cx + r + 6}" y2="${cy}" stroke="var(--border)" stroke-width="0.8" opacity="0.55"/>
    <line x1="${cx}" y1="${cy - r - 4}" x2="${cx}" y2="${cy + r + 4}" stroke="var(--border)" stroke-width="0.8" opacity="0.55"/>
    <g transform="translate(${cx} ${cy}) rotate(${deg.toFixed(1)})">
      <rect x="${(-span).toFixed(1)}" y="-6" width="${(span * 2).toFixed(1)}" height="12" rx="6" fill="url(#smear)"/>
    </g>
    <line x1="${(cx - dx).toFixed(1)}" y1="${(cy - dy).toFixed(1)}" x2="${(cx + dx).toFixed(1)}" y2="${(cy + dy).toFixed(1)}" stroke="var(--accent)" stroke-width="2" stroke-linecap="round"/>
    <circle cx="${cx}" cy="${cy}" r="2.4" fill="var(--muted)"/>
    <circle cx="${(cx + dx).toFixed(1)}" cy="${(cy + dy).toFixed(1)}" r="7.5" fill="var(--accent)" fill-opacity="0.24"/>
    <circle cx="${(cx + dx).toFixed(1)}" cy="${(cy + dy).toFixed(1)}" r="4" fill="var(--accent)" stroke="var(--well)" stroke-width="1.3"/>
    <text x="10" y="15" fill="var(--muted)" font-size="9.5" font-family="Inter">${Math.round(deg)}°</text>
    <text x="270" y="15" fill="var(--text)" font-size="9.5" font-family="Inter" text-anchor="end">${Math.round(width * 100)}%</text>
  </svg>`;

  return {
    hide: ["width", "angle"],
    ui: ui.column([
      ui.svg(88, svg, { id: "compass", label: "Blur Vector" }),
      ui.row([
        ui.button("Horiz", "preset:h"),
        ui.button("Vert", "preset:v"),
        ui.button("45°", "preset:d"),
        ui.button("Off", "preset:off"),
      ]),
    ]),
  };
}

function onCardAction(action) {
  if (action.id === "compass" && action.value) {
    const nx = (Number(action.value.x ?? 0.5) - 0.5) / 0.25;
    const ny = (Number(action.value.y ?? 0.5) - 0.5) / 0.42;
    const w = Math.round(Math.min(1, Math.hypot(nx, ny)) * 1000) / 1000;
    const a = w < 0.02 ? 0 : Math.round((Math.atan2(ny, nx) / Math.PI) * 1000) / 1000;
    return { set: { width: w, angle: a } };
  }
  if (action.id === "preset:h") return { set: { width: 0.25, angle: 0 } };
  if (action.id === "preset:v") return { set: { width: 0.25, angle: 0.5 } };
  if (action.id === "preset:d") return { set: { width: 0.25, angle: 0.25 } };
  if (action.id === "preset:off") return { set: { width: 0 } };
  return {};
}
