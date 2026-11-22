// Custom Inspector card template for `wave.js`.
// Previews the sine + noise blend across copies and provides 1-click motion presets.

function renderCard(ctx) {
  const p = ctx.params || {};
  const speed = Number(p.wave_speed ?? 1);
  const phase = Number(p.wave_phase ?? 0);
  const noise = Math.max(0, Math.min(1, Number(p.wave_noise ?? 0)));

  const pts = [];
  const dots = [];
  const cycles = Math.max(0.5, Math.abs(phase) > 0.1 ? Math.abs(phase) : 1.5);
  for (let i = 0; i <= 28; i++) {
    const u = i / 28;
    const s = Math.sin(u * Math.PI * 2 * cycles);
    const n = Math.sin(u * 13.7 + speed) * Math.cos(u * 5.3) * 0.85;
    const y = 0.5 - (s * (1 - noise) + n * noise) * 0.34;
    const x = 0.06 + u * 0.88;
    pts.push([x, y]);
    if (i % 4 === 0) dots.push({ op: "circle", x, y, r: 0.036, fill: "accent" });
  }

  return {
    hide: ["wave_speed", "wave_phase"],
    ui: ui.column([
      ui.canvas(84, [
        { op: "line", x: 0.04, y: 0.5, x2: 0.96, y2: 0.5, stroke: "border", width: 0.8 },
        { op: "polyline", points: pts, stroke: "accent", width: 1.8 },
        ...dots,
        { op: "text", x: 0.04, y: 0.14, text: speed.toFixed(1) + " Hz", fill: "muted" },
        { op: "text", x: 0.96, y: 0.14, text: "Noise " + Math.round(noise * 100) + "%", fill: "muted", align: "right" },
      ], { id: "preview" }),
      ui.row([
        ui.slider("Speed", speed, { id: "wave_speed", min: 0, max: 4, step: 0.05, unit: "Hz" }),
        ui.slider("Ripple", phase, { id: "wave_phase", min: -4, max: 4, step: 0.05 }),
      ]),
      ui.row([
        ui.button("Helix", "preset:helix"),
        ui.button("Organic", "preset:organic"),
        ui.button("Pulse", "preset:pulse"),
      ]),
    ]),
  };
}

function onCardAction(action) {
  if (action.id === "preview" && action.value) {
    const spd = Math.round(Math.max(0, Math.min(4, Number(action.value.x ?? 0.25) * 4)) * 20) / 20;
    const rnd = Math.round(Math.max(0, Math.min(1, 1 - Number(action.value.y ?? 0.5))) * 100) / 100;
    return { set: { wave_speed: spd, wave_noise: rnd } };
  }
  if (action.id === "preset:helix") {
    return { set: { wave_y: 0.25, wave_z: 0.25, wave_speed: 1.0, wave_phase: 1.5, wave_noise: 0 } };
  }
  if (action.id === "preset:organic") {
    return { set: { wave_x: 0.12, wave_y: 0.18, wave_rotate: 12, wave_speed: 0.8, wave_noise: 0.65 } };
  }
  if (action.id === "preset:pulse") {
    return { set: { wave_y: 0, wave_size: 0.45, wave_speed: 1.5, wave_phase: 1.0, wave_noise: 0 } };
  }
  return {};
}
