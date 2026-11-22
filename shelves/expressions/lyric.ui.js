// Custom Inspector card template for `lyric.js`.
// Visualizes the per-letter stagger cascade for Start / End / Centre / Edges / Random.

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

  const draw = [];
  for (let i = 0; i < n; i++) {
    let turn = i / (n - 1);
    if (order === "End") turn = (n - 1 - i) / (n - 1);
    else if (order === "Centre") turn = Math.abs(i - mid) / mid;
    else if (order === "Edges") turn = (mid - Math.abs(i - mid)) / mid;
    else if (order === "Random") turn = rnd[i];

    const y = 0.12 + i * 0.125;
    const isFirst = turn < 0.05;
    draw.push(
      { op: "text", x: 0.05, y: y + 0.03, text: letters[i], fill: "muted" },
      {
        op: "rect",
        x: 0.14 + turn * 0.44,
        y: y - 0.01,
        w: 0.38,
        h: 0.075,
        radius: 2,
        fill: isFirst ? "accent" : (alt && i % 2 === 1 ? "place" : "layout"),
        alpha: isFirst ? 0.95 : 0.72,
      }
    );
  }

  return {
    hide: ["order", "alternate", "out"],
    ui: ui.column([
      ui.select("", order, orders, { id: "order" }),
      ui.canvas(92, draw, { label: "Per-Letter Cascade (" + order + ")" }),
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
