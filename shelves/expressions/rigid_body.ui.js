// Custom Inspector card template for Jolt Physics `rigid_body.js`.
// Surfaces Dynamic vs. Floor (Mass 0), simulates bounce trajectory live, and
// offers one-click material presets while keeping raw sliders in `Parameters >`.

function renderCard(ctx) {
  const p = ctx.params || {};
  const mass = Math.max(0, Number(p.mass ?? 1));
  const gravity = Math.max(0, Number(p.gravity ?? 1));
  const bounce = Math.max(0, Math.min(1, Number(p.bounce ?? 0)));
  const friction = Math.max(0, Math.min(1, Number(p.friction ?? 0.2)));
  const isFloor = mass <= 1e-4;

  const floorY = 0.84;
  const draw = [
    { op: "line", x: 0.05, y: floorY, x2: 0.95, y2: floorY, stroke: "border", width: 1.4 },
    { op: "rect", x: 0.05, y: floorY, w: 0.90, h: 0.10, fill: "surface", alpha: 0.85 },
  ];

  if (isFloor) {
    // Static collider / kinematic floor illustration.
    draw.push(
      { op: "rect", x: 0.16, y: 0.44, w: 0.68, h: 0.16, fill: "layout", alpha: 0.22, stroke: "layout", width: 1.5, radius: 4 },
      { op: "text", x: 0.50, y: 0.52, text: "Static Collider (Mass 0)", fill: "layout", align: "center" },
      { op: "text", x: 0.50, y: 0.72, text: "Holds up & pushes dynamic bodies", fill: "muted", align: "center" }
    );
  } else {
    // Simulate a quick 2D bounce curve so gravity + bounce + friction read visually.
    const pts = [];
    let x = 0.10, y = 0.20, vy = 0, vx = 0.015;
    const g = Math.max(0.0004, gravity * 0.0036);
    for (let step = 0; step < 54; step++) {
      pts.push([Math.min(0.94, x), Math.max(0.10, Math.min(floorY, y))]);
      x += vx;
      vy += g;
      y += vy;
      if (y > floorY) {
        y = floorY;
        vy = -vy * bounce;
        vx *= Math.max(0.25, 1 - friction * 0.45);
      }
    }
    draw.push(
      { op: "polyline", points: pts, stroke: "place", width: 1.8 },
      { op: "circle", x: 0.10, y: 0.20, r: 0.072, fill: "place" },
      { op: "text", x: 0.94, y: 0.14, text: (gravity * 9.8).toFixed(1) + " m/s² · e=" + bounce.toFixed(2), fill: "muted", align: "right" }
    );
  }

  return {
    hide: ["mass", "gravity", "bounce", "friction"],
    ui: ui.column([
      ui.select("", isFloor ? "Floor (Static)" : "Dynamic", ["Dynamic", "Floor (Static)"], { id: "mode" }),
      ui.canvas(94, draw, { id: "preview" }),
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
    // Vertical drag on preview adjusts Bounciness; horizontal adjusts Gravity.
    const b = Math.round(Math.max(0, Math.min(1, 1 - Number(action.value.y ?? 0.5))) * 100) / 100;
    return { set: { bounce: b } };
  }
  if (action.id === "preset:rubber") return { set: { mass: 1, gravity: 1, bounce: 0.78, friction: 0.4 } };
  if (action.id === "preset:ice") return { set: { mass: 1, gravity: 1, bounce: 0.1, friction: 0.02 } };
  if (action.id === "preset:heavy") return { set: { mass: 6, gravity: 1.6, bounce: 0.08, friction: 0.7 } };
  if (action.id === "preset:zerog") return { set: { mass: 1, gravity: 0, bounce: 0.5, friction: 0.05 } };
  return {};
}
