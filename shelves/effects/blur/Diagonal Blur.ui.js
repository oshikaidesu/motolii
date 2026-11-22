// Sidecar custom Inspector card UI for `Diagonal Blur.fs`.
// Uses `ui.canvas` to draw a live polar compass + directional smear preview
// while tucking raw `width` and `angle` into the card's `Parameters` fold so
// keyframes and Macro plugs stay reachable.

function renderCard(ctx) {
  const p = ctx.params || {};
  const width = Math.max(0, Math.min(1, Number(p.width ?? 0)));
  const angle = Number(p.angle ?? 0.125);
  const rad = Math.PI * angle;
  const cx = 0.5;
  const cy = 0.5;
  const rx = 0.42;
  const ry = 0.42;
  const dx = Math.cos(rad) * width * rx;
  const dy = Math.sin(rad) * width * ry;

  const draw = [
    // Outer & inner polar compass rings.
    { op: "circle", x: cx, y: cy, r: 0.42, stroke: "border", width: 1 },
    { op: "circle", x: cx, y: cy, r: 0.21, stroke: "border", width: 0.8, alpha: 0.6 },
    { op: "line", x: 0.08, y: cy, x2: 0.92, y2: cy, stroke: "border", width: 0.8, alpha: 0.6 },
    { op: "line", x: cx, y: 0.08, x2: cx, y2: 0.92, stroke: "border", width: 0.8, alpha: 0.6 },
    // Symmetric smear streak preview showing the real blur direction & span.
    { op: "line", x: cx - dx, y: cy - dy, x2: cx + dx, y2: cy + dy, stroke: "blend", width: 5, alpha: 0.28 },
    { op: "line", x: cx - dx, y: cy - dy, x2: cx + dx, y2: cy + dy, stroke: "accent", width: 1.8 },
    // Center dot + draggable vector handle.
    { op: "circle", x: cx, y: cy, r: 0.025, fill: "muted" },
    { op: "circle", x: cx + dx, y: cy + dy, r: 0.065, fill: "accent", alpha: 0.25 },
    { op: "circle", x: cx + dx, y: cy + dy, r: 0.04, fill: "accent" },
    { op: "text", x: 0.04, y: 0.12, text: Math.round(angle * 180) + "°", fill: "muted" },
    { op: "text", x: 0.96, y: 0.12, text: Math.round(width * 100) + "%", fill: "text", align: "right" },
  ];

  return {
    hide: ["width", "angle"],
    ui: ui.column([
      ui.canvas(88, draw, { id: "compass", label: "Blur Vector" }),
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
    const nx = (Number(action.value.x ?? 0.5) - 0.5) / 0.42;
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
