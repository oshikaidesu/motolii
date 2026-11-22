// Custom Inspector card template for spatial falloff `Field.js`.
// Uses standard SVG (`ui.svg`) for radial glow, dashed ring bands, and interactive center drag.

function renderCard(ctx) {
  const p = ctx.params || {};
  const fx = Number(p.field_x ?? 0);
  const fy = Number(p.field_y ?? 0);
  const radius = Math.max(0, Number(p.field_radius ?? 0));
  const band = Math.max(0, Number(p.field_band ?? 0));
  const isRing = band > 1e-4;

  const cx = Math.max(24, Math.min(256, 140 + (fx / 3) * 110));
  const cy = Math.max(14, Math.min(80, 47 - (fy / 2) * 34));
  const rPx = Math.max(8, Math.min(44, (radius / 2) * 44));
  const bandPx = Math.min(28, (band / 2) * 32);

  const rings = isRing
    ? `<circle cx="${cx.toFixed(1)}" cy="${cy.toFixed(1)}" r="${rPx.toFixed(1)}" fill="none" stroke="var(--blend)" stroke-width="${Math.max(4, bandPx).toFixed(1)}" opacity="0.18"/>
       <circle cx="${cx.toFixed(1)}" cy="${cy.toFixed(1)}" r="${(rPx + bandPx * 0.5).toFixed(1)}" fill="none" stroke="var(--blend)" stroke-width="1.1" stroke-dasharray="4 3" opacity="0.8"/>
       <circle cx="${cx.toFixed(1)}" cy="${cy.toFixed(1)}" r="${Math.max(4, rPx - bandPx * 0.5).toFixed(1)}" fill="none" stroke="var(--border)" stroke-width="1" stroke-dasharray="3 2" opacity="0.85"/>`
    : `<circle cx="${cx.toFixed(1)}" cy="${cy.toFixed(1)}" r="${rPx.toFixed(1)}" fill="url(#fieldGlow)" stroke="var(--blend)" stroke-width="1.2" stroke-dasharray="4 3"/>`;

  const dots = [];
  for (let gx = 0; gx < 9; gx++) {
    for (let gy = 0; gy < 4; gy++) {
      const px = 28 + gx * 28;
      const py = 17 + gy * 20;
      const d = Math.hypot(px - cx, py - cy);
      let near = 0;
      if (rPx > 0) {
        near = isRing
          ? 1 - Math.abs(d - rPx) / Math.max(6, bandPx)
          : 1 - d / rPx;
      }
      const s = Math.max(0, Math.min(1, near));
      const smooth = s * s * (3 - 2 * s);
      dots.push(`<circle cx="${px}" cy="${py}" r="${(1.8 + smooth * 3.1).toFixed(1)}" fill="${smooth > 0.2 ? "var(--blend)" : "var(--muted)"}" opacity="${(0.28 + smooth * 0.72).toFixed(2)}"/>`);
    }
  }

  const svg = `<svg viewBox="0 0 280 94">
    <defs>
      <radialGradient id="fieldGlow" cx="${(cx / 280 * 100).toFixed(1)}%" cy="${(cy / 94 * 100).toFixed(1)}%" r="36%">
        <stop offset="0%" stop-color="var(--blend)" stop-opacity="0.34"/>
        <stop offset="100%" stop-color="var(--blend)" stop-opacity="0"/>
      </radialGradient>
    </defs>
    <rect x="0" y="0" width="280" height="94" fill="url(#fieldGlow)" opacity="${isRing ? "0.45" : "0.85"}"/>
    ${rings}
    ${dots.join("")}
    <circle cx="${cx.toFixed(1)}" cy="${cy.toFixed(1)}" r="7" fill="var(--accent)" fill-opacity="0.22"/>
    <circle cx="${cx.toFixed(1)}" cy="${cy.toFixed(1)}" r="3.8" fill="var(--accent)" stroke="var(--well)" stroke-width="1.3"/>
  </svg>`;

  return {
    hide: ["field_x", "field_y", "field_band"],
    ui: ui.column([
      ui.select("", isRing ? "Ring" : "Sphere", ["Sphere", "Ring"], { id: "mode" }),
      ui.svg(94, svg, { id: "map", label: "Field Center & Falloff" }),
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
