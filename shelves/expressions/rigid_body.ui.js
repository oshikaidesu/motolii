// Custom Inspector card template for Jolt Physics `rigid_body.js`.
// Uses standard SVG (`ui.svg`) for ground hatching, live bounce trajectory,
// and Dynamic vs. Floor (Mass 0) visualization.

function renderCard(ctx) {
  const p = ctx.params || {};
  const mass = Math.max(0, Number(p.mass ?? 1));
  const gravity = Math.max(0, Number(p.gravity ?? 1));
  const bounce = Math.max(0, Math.min(1, Number(p.bounce ?? 0)));
  const friction = Math.max(0, Math.min(1, Number(p.friction ?? 0.2)));
  const isFloor = mass <= 1e-4;

  const floorY = 76;
  const hatches = [];
  for (let hx = 18; hx <= 266; hx += 18) {
    hatches.push(`<line x1="${hx}" y1="${floorY}" x2="${hx - 7}" y2="${floorY + 10}"/>`);
  }

  let bodySvg = "";
  if (isFloor) {
    bodySvg = `
      <rect x="44" y="34" width="192" height="22" rx="4" fill="var(--layout)" fill-opacity="0.18" stroke="var(--layout)" stroke-width="1.5"/>
      <text x="140" y="48" fill="var(--layout)" font-size="9.5" font-family="Inter" text-anchor="middle">Static Collider (Mass 0)</text>
      <text x="140" y="68" fill="var(--muted)" font-size="8.5" font-family="Inter" text-anchor="middle">Holds up &amp; pushes dynamic bodies</text>`;
  } else {
    const pts = [];
    const hits = [];
    let x = 28, y = 20, vy = 0, vx = 4.2;
    const g = Math.max(0.06, gravity * 0.36);
    for (let step = 0; step < 56; step++) {
      const cx = Math.min(266, x);
      const cy = Math.max(10, Math.min(floorY, y));
      pts.push(`${cx.toFixed(1)},${cy.toFixed(1)}`);
      x += vx;
      vy += g;
      y += vy;
      if (y > floorY) {
        y = floorY;
        hits.push(`<circle cx="${Math.min(266, x).toFixed(1)}" cy="${floorY}" r="2.6" fill="var(--place)"/>`);
        vy = -vy * bounce;
        vx *= Math.max(0.25, 1 - friction * 0.45);
      }
    }
    bodySvg = `
      <defs>
        <linearGradient id="rbFill" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="var(--place)" stop-opacity="0.28"/>
          <stop offset="100%" stop-color="var(--place)" stop-opacity="0.02"/>
        </linearGradient>
      </defs>
      <polyline points="${pts.join(" ")} 266,${floorY} 28,${floorY}" fill="url(#rbFill)" stroke="none"/>
      <polyline points="${pts.join(" ")}" fill="none" stroke="var(--place)" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>
      ${hits.join("")}
      <circle cx="28" cy="20" r="8.5" fill="var(--place)" fill-opacity="0.22"/>
      <circle cx="28" cy="20" r="5" fill="var(--place)" stroke="var(--well)" stroke-width="1.4"/>
      <text x="268" y="16" fill="var(--muted)" font-size="9" font-family="Inter" text-anchor="end">${(gravity * 9.8).toFixed(1)} m/s² · e=${bounce.toFixed(2)}</text>`;
  }

  const svg = `<svg viewBox="0 0 280 92" preserveAspectRatio="none">
    <g stroke="var(--border)" stroke-width="0.9" opacity="0.65">${hatches.join("")}</g>
    <line x1="12" y1="${floorY}" x2="268" y2="${floorY}" stroke="var(--border)" stroke-width="1.4"/>
    ${bodySvg}
  </svg>`;

  return {
    hide: ["mass", "gravity", "bounce", "friction"],
    ui: ui.column([
      ui.select("", isFloor ? "Floor (Static)" : "Dynamic", ["Dynamic", "Floor (Static)"], { id: "mode" }),
      ui.svg(92, svg, { id: "preview", fit: "fill" }),
      ui.row([
        ui.button("Rubber", "preset:rubber", { accent: !isFloor && bounce >= 0.6 }),
        ui.button("Ice", "preset:ice"),
        ui.button("Heavy", "preset:heavy"),
        ui.button("Zero-G", "preset:zerog"),
      ]),
      ui.row([
        ui.slider("Mass", mass, { id: "mass", min: 0, max: 10, step: 0.05, unit: "kg" }),
        ui.slider("Bounce", bounce, { id: "bounce", min: 0, max: 1, step: 0.01 }),
      ]),
    ]),
  };
}

function onCardAction(action) {
  if (action.id === "mode") {
    return { set: { mass: action.value === "Floor (Static)" ? 0 : 1 } };
  }
  if (action.id === "preview" && action.value) {
    const b = Math.round(Math.max(0, Math.min(1, 1 - Number(action.value.y ?? 0.5))) * 100) / 100;
    return { set: { bounce: b } };
  }
  if (action.id === "preset:rubber") return { set: { mass: 1, gravity: 1, bounce: 0.78, friction: 0.4 } };
  if (action.id === "preset:ice") return { set: { mass: 1, gravity: 1, bounce: 0.1, friction: 0.02 } };
  if (action.id === "preset:heavy") return { set: { mass: 6, gravity: 1.6, bounce: 0.08, friction: 0.7 } };
  if (action.id === "preset:zerog") return { set: { mass: 1, gravity: 0, bounce: 0.5, friction: 0.05 } };
  return {};
}
