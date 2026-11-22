// Custom Inspector card template for spatial falloff `Field.js`.
// Visualizes Sphere vs. Ring influence over sample copies and lets you drag
// the field's (At X, At Y) center directly on a 2D map.

function renderCard(ctx) {
  const p = ctx.params || {};
  const fx = Number(p.field_x ?? 0);
  const fy = Number(p.field_y ?? 0);
  const radius = Math.max(0, Number(p.field_radius ?? 0));
  const band = Math.max(0, Number(p.field_band ?? 0));
  const isRing = band > 1e-4;

  const cx = Math.max(0.08, Math.min(0.92, 0.5 + fx / 6));
  const cy = Math.max(0.12, Math.min(0.88, 0.5 - fy / 4));
  const rNorm = Math.max(0.06, Math.min(0.46, radius / 4));
  const bandNorm = Math.min(0.35, band / 4);

  const draw = [];
  if (isRing) {
    draw.push(
      { op: "circle", x: cx, y: cy, r: rNorm, stroke: "blend", width: Math.max(3, bandNorm * 32), alpha: 0.18 },
      { op: "circle", x: cx, y: cy, r: Math.min(0.48, rNorm + bandNorm * 0.5), stroke: "blend", width: 1.1, alpha: 0.7 },
      { op: "circle", x: cx, y: cy, r: Math.max(0.03, rNorm - bandNorm * 0.5), stroke: "border", width: 0.9, alpha: 0.7 }
    );
  } else {
    draw.push(
      { op: "circle", x: cx, y: cy, r: rNorm, fill: "blend", alpha: 0.14, stroke: "blend", width: 1.2 }
    );
  }

  for (let gx = 0; gx < 9; gx++) {
    for (let gy = 0; gy < 4; gy++) {
      const px = 0.10 + gx * 0.10;
      const py = 0.20 + gy * 0.20;
      const d = Math.hypot((px - cx) * 1.4, py - cy);
      let near = 0;
      if (rNorm > 0) {
        near = isRing
          ? 1 - Math.abs(d - rNorm) / Math.max(0.04, bandNorm)
          : 1 - d / rNorm;
      }
      const s = Math.max(0, Math.min(1, near));
      const smooth = s * s * (3 - 2 * s);
      draw.push({
        op: "circle",
        x: px, y: py,
        r: 0.02 + smooth * 0.034,
        fill: smooth > 0.2 ? "blend" : "muted",
        alpha: 0.30 + smooth * 0.70,
      });
    }
  }
  draw.push({ op: "circle", x: cx, y: cy, r: 0.042, fill: "accent" });

  return {
    hide: ["field_x", "field_y", "field_band"],
    ui: ui.column([
      ui.select("", isRing ? "Ring" : "Sphere", ["Sphere", "Ring"], { id: "mode" }),
      ui.canvas(94, draw, { id: "map", label: "Field Center & Falloff" }),
    ]),
  };
}

function onCardAction(action, ctx) {
  const p = (ctx && ctx.params) || {};
  if (action.id === "mode") {
    const r = Number(p.field_radius ?? 0);
    return {
      set: {
        field_band: action.value === "Ring" ? 0.45 : 0,
        field_radius: r > 0.05 ? r : 1.0,
      },
    };
  }
  if (action.id === "map" && action.value) {
    const nx = Math.round((Number(action.value.x ?? 0.5) - 0.5) * 6 * 100) / 100;
    const ny = Math.round((0.5 - Number(action.value.y ?? 0.5)) * 4 * 100) / 100;
    return { set: { field_x: nx, field_y: ny } };
  }
  return {};
}
