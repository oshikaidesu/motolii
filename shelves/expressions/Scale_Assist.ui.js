// Custom Inspector card template for `Scale_Assist.js`.
// Previews volume-preserving squash & stretch live and lets you drag horizontally
// to pull Amount directly.

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

  const bw = Math.max(0.08, Math.min(0.84, 0.28 * sx));
  const bh = Math.max(0.10, Math.min(0.80, 0.44 * sy));

  return {
    hide: ["assist_way", "assist_amount"],
    ui: ui.column([
      ui.select("", way, ways, { id: "way" }),
      ui.canvas(88, [
        { op: "rect", x: 0.36, y: 0.28, w: 0.28, h: 0.44, stroke: "border", width: 1.0, radius: 4 },
        { op: "rect", x: 0.5 - bw * 0.5, y: 0.5 - bh * 0.5, w: bw, h: bh, fill: "time", alpha: 0.24, stroke: "time", width: 1.8, radius: 5 },
        { op: "text", x: 0.5, y: 0.5, text: sx.toFixed(2) + " × " + sy.toFixed(2), fill: "text", align: "center" },
      ], { id: "box" }),
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
