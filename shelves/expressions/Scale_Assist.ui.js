// Custom Inspector card template for `Scale_Assist.js`.
// Uses standard SVG (`ui.svg`) to overlay the volume-preserving squash/stretch
// gradient box on top of the dashed 1.0 × 1.0 reference frame.

function renderCard(ctx) {
  const p = ctx.params || {};
  const wayIdx = Math.round(Number(p.assist_way ?? 0));
  const ways = ["Both", "X", "Y"];
  const way = ways[wayIdx] || "Both";
  const amount = Math.max(0.1, Math.min(4, Number(p.assist_amount ?? 1)));
  const damp = Math.max(1, Math.min(3, Number(p.assist_damp ?? 1)));

  let sx = 1, sy = 1;
  if (way === "X") sx = amount;
  else if (way === "Y") sy = amount;
  else {
    sx = amount;
    sy = 1 / Math.max(0.15, Math.pow(amount, 1.71) * Math.pow(damp, 1 + 2.75 * Math.pow(damp - 1, 1.93)));
  }

  const bw = Math.max(24, Math.min(236, 76 * sx));
  const bh = Math.max(14, Math.min(72, 44 * sy));
  const bx = 140 - bw * 0.5;
  const by = 44 - bh * 0.5;

  const svg = `<svg viewBox="0 0 280 88" preserveAspectRatio="none">
    <defs>
      <linearGradient id="sqFill" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="var(--time)" stop-opacity="0.34"/>
        <stop offset="100%" stop-color="var(--accent)" stop-opacity="0.16"/>
      </linearGradient>
    </defs>
    <line x1="140" y1="6" x2="140" y2="82" stroke="var(--border)" stroke-width="0.7" stroke-dasharray="2 3" opacity="0.6"/>
    <line x1="14" y1="44" x2="266" y2="44" stroke="var(--border)" stroke-width="0.7" stroke-dasharray="2 3" opacity="0.6"/>
    <rect x="102" y="22" width="76" height="44" rx="4" fill="none" stroke="var(--border)" stroke-width="1.1" stroke-dasharray="4 3"/>
    <rect x="${bx.toFixed(1)}" y="${by.toFixed(1)}" width="${bw.toFixed(1)}" height="${bh.toFixed(1)}" rx="5" fill="url(#sqFill)" stroke="var(--time)" stroke-width="1.8"/>
    <text x="140" y="47.5" fill="var(--text)" font-size="10" font-family="Inter" text-anchor="middle">${sx.toFixed(2)} × ${sy.toFixed(2)}</text>
    <text x="10" y="14" fill="var(--muted)" font-size="8.5" font-family="Inter">1.00 × 1.00 ref</text>
  </svg>`;

  return {
    hide: ["assist_way", "assist_amount"],
    ui: ui.column([
      ui.select("", way, ways, { id: "way" }),
      ui.svg(88, svg, { id: "box", fit: "fill" }),
      ui.row([
        ui.button("Squash", "preset:squash"),
        ui.button("Reset", "preset:reset"),
        ui.button("Stretch", "preset:stretch"),
      ]),
    ]),
  };
}

function onCardAction(action) {
  if (action.id === "way") {
    const idx = { Both: 0, X: 1, Y: 2 }[action.value] ?? 0;
    return { set: { assist_way: idx } };
  }
  if (action.id === "box" && action.value) {
    const amt = Math.round((0.3 + Number(action.value.x ?? 0.5) * 2.2) * 100) / 100;
    return { set: { assist_amount: Math.max(0.1, Math.min(4, amt)) } };
  }
  if (action.id === "preset:squash") return { set: { assist_way: 0, assist_amount: 1.55 } };
  if (action.id === "preset:reset") return { set: { assist_way: 0, assist_amount: 1.0, assist_damp: 1.0 } };
  if (action.id === "preset:stretch") return { set: { assist_way: 0, assist_amount: 0.65 } };
  return {};
}
