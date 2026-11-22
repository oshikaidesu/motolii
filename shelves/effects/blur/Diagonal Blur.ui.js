// Sidecar custom Inspector card UI for `Diagonal Blur.fs`.
// Turns flat `width` + `angle` sliders into a 2D direction vector pad + presets
// without modifying the original ISF shader file.

function renderCard(ctx) {
  const p = ctx.params || {};
  const width = Number(p.width ?? 0);
  const angle = Number(p.angle ?? 0.125);
  const rad = Math.PI * angle;
  const dx = Math.cos(rad) * width;
  const dy = Math.sin(rad) * width;

  return {
    hide: ["width", "angle"],
    ui: ui.column([
      ui.xy("Blur Vector", dx, dy, { id: "vector", min: -1, max: 1 }),
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
  if (action.id === "vector" && action.value) {
    const x = Number(action.value.x || 0);
    const y = Number(action.value.y || 0);
    const w = Math.min(1, Math.hypot(x, y));
    const a = w < 1e-4 ? 0 : Math.atan2(y, x) / Math.PI;
    return { set: { width: w, angle: a } };
  }
  if (action.id === "preset:h") return { set: { width: 0.25, angle: 0 } };
  if (action.id === "preset:v") return { set: { width: 0.25, angle: 0.5 } };
  if (action.id === "preset:d") return { set: { width: 0.25, angle: 0.25 } };
  if (action.id === "preset:off") return { set: { width: 0 } };
  return {};
}
