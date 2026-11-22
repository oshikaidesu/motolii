// Custom Inspector card template for `lyric.js`.
// Uses standard SVG (`ui.svg`) for the per-letter stagger cascade with timeline guides.

function renderCard(ctx) {
  const p = ctx.params || {};
  const orders = ["Start", "End", "Centre", "Edges", "Random"];
  const orderIdx = Math.round(Number(p.order ?? 0));
  const order = orders[orderIdx] || "Start";
  const alt = Number(p.alternate ?? 0) >= 0.5;
  const out = Number(p.out ?? 1) >= 0.5;

  const letters = ["M", "O", "T", "O", "L", "I", "I"];
  const n = letters.length;
  const mid = (n - 1) / 2;
  const rnd = [0.6, 0.1, 0.9, 0.3, 0.8, 0.0, 0.5];

  const rows = [];
  for (let i = 0; i < n; i++) {
    let turn = i / (n - 1);
    if (order === "End") turn = (n - 1 - i) / (n - 1);
    else if (order === "Centre") turn = Math.abs(i - mid) / mid;
    else if (order === "Edges") turn = (mid - Math.abs(i - mid)) / mid;
    else if (order === "Random") turn = rnd[i];

    const y = 10 + i * 11.4;
    const isFirst = turn < 0.05;
    const x = 34 + turn * 124;
    const fill = isFirst ? "var(--accent)" : (alt && i % 2 === 1 ? "var(--place)" : "var(--layout)");
    rows.push(
      `<text x="16" y="${(y + 6.5).toFixed(1)}" fill="var(--muted)" font-size="8.5" font-family="Inter" text-anchor="middle">${letters[i]}</text>`
      + `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="108" height="7.4" rx="2.2" fill="${fill}" opacity="${isFirst ? "0.95" : "0.76"}"/>`
    );
  }

  const svg = `<svg viewBox="0 0 280 92" preserveAspectRatio="none">
    <g stroke="var(--border)" stroke-width="0.7" stroke-dasharray="3 3" opacity="0.55">
      <line x1="34" y1="6" x2="34" y2="86"/>
      <line x1="150" y1="6" x2="150" y2="86"/>
      <line x1="266" y1="6" x2="266" y2="86"/>
    </g>
    ${rows.join("")}
  </svg>`;

  return {
    hide: ["order", "alternate", "out"],
    ui: ui.column([
      ui.select("", order, orders, { id: "order" }),
      ui.svg(92, svg, { label: "Per-Letter Cascade (" + order + ")", fit: "fill" }),
      ui.row([
        ui.toggle("Alternate", alt, { id: "alternate" }),
        ui.toggle("Animate Out", out, { id: "out" }),
      ]),
    ]),
  };
}

function onCardAction(action) {
  if (action.id === "order") {
    const idx = ["Start", "End", "Centre", "Edges", "Random"].indexOf(action.value);
    if (idx >= 0) return { set: { order: idx } };
  }
  if (action.id === "alternate") return { set: { alternate: action.value ? 1 : 0 } };
  if (action.id === "out") return { set: { out: action.value ? 1 : 0 } };
  return {};
}
