// Custom Inspector card template for Jolt Physics `wind.js`.
// Turns `wind` (X) and `lift` (Y) newtons into an interactive 2D force compass.

function renderCard(ctx) {
  const p = ctx.params || {};
  const wind = Math.max(-50, Math.min(50, Number(p.wind ?? 0)));
  const lift = Math.max(-50, Math.min(50, Number(p.lift ?? 0)));
  const cx = 0.5, cy = 0.5;
  const vx = cx + (wind / 50) * 0.40;
  const vy = cy - (lift / 50) * 0.40;

  const draw = [
    { op: "circle", x: cx, y: cy, r: 0.40, stroke: "border", width: 0.9 },
    { op: "line", x: 0.08, y: cy, x2: 0.92, y2: cy, stroke: "border", width: 0.7, alpha: 0.5 },
    { op: "line", x: cx, y: 0.08, x2: cx, y2: 0.92, stroke: "border", width: 0.7, alpha: 0.5 },
  ];

  // Streamlines bending gently in the force direction.
  const sx = (wind / 50) * 0.16;
  const sy = -(lift / 50) * 0.14;
  for (const rowY of [0.28, 0.50, 0.72]) {
    draw.push({
      op: "bezier",
      x: 0.14, y: rowY - sy * 0.5,
      cx1: 0.38, cy1: rowY - sy * 0.1,
      cx2: 0.62, cy2: rowY + sy * 0.2,
      x2: 0.86, y2: rowY + sy,
      stroke: "layout", width: 1.0, alpha: Math.min(0.75, 0.18 + Math.hypot(sx, sy) * 3),
    });
  }

  draw.push(
    { op: "line", x: cx, y: cy, x2: vx, y2: vy, stroke: "accent", width: 2.2 },
    { op: "circle", x: vx, y: vy, r: 0.06, fill: "accent" },
    { op: "text", x: 0.04, y: 0.14, text: "Wind " + Math.round(wind) + "N", fill: "text" },
    { op: "text", x: 0.96, y: 0.14, text: "Lift " + Math.round(lift) + "N", fill: "layout", align: "right" }
  );

  return {
    hide: ["wind", "lift"],
    ui: ui.column([
      ui.canvas(96, draw, { id: "vector", label: "Jolt Force Vector (N)" }),
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
    const w = Math.round(((Number(action.value.x ?? 0.5) - 0.5) / 0.40) * 50 * 10) / 10;
    const l = Math.round(((0.5 - Number(action.value.y ?? 0.5)) / 0.40) * 50 * 10) / 10;
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
