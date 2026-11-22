// Custom Inspector card template for `wave.js`.
// Uses standard SVG (`ui.svg`) for a gradient-filled sine + noise curve and sample markers.

function renderCard(ctx) {
  const p = ctx.params || {};
  const speed = Number(p.wave_speed ?? 1);
  const phase = Number(p.wave_phase ?? 0);
  const noise = Math.max(0, Math.min(1, Number(p.wave_noise ?? 0)));
  const t = Number(ctx.time ?? 0);

  const pts = [];
  const dots = [];
  const cycles = Math.max(0.5, Math.abs(phase) > 0.1 ? Math.abs(phase) : 1.5);
  for (let i = 0; i <= 32; i++) {
    const u = i / 32;
    const s = Math.sin((u * cycles + t * speed) * Math.PI * 2);
    const n = Math.sin(u * 13.7 + speed + t * 3.1) * Math.cos(u * 5.3 - t * 1.7) * 0.85;
    const x = 14 + u * 252;
    const y = 46 - (s * (1 - noise) + n * noise) * 28;
    pts.push(`${x.toFixed(1)},${y.toFixed(1)}`);
    if (i % 4 === 0) {
      dots.push(`<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="3.2" fill="var(--accent)" stroke="var(--well)" stroke-width="1.2"/>`);
    }
  }

  const svg = `<svg viewBox="0 0 280 84" preserveAspectRatio="none">
    <defs>
      <linearGradient id="waveFill" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color="var(--accent)" stop-opacity="0.32"/>
        <stop offset="100%" stop-color="var(--accent)" stop-opacity="0.02"/>
      </linearGradient>
    </defs>
    <line x1="10" y1="46" x2="270" y2="46" stroke="var(--border)" stroke-width="0.9" stroke-dasharray="3 3"/>
    <polyline points="${pts.join(" ")} 266,84 14,84" fill="url(#waveFill)" stroke="none"/>
    <polyline points="${pts.join(" ")}" fill="none" stroke="var(--accent)" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>
    ${dots.join("")}
    <text x="10" y="14" fill="var(--muted)" font-size="9" font-family="Inter">${speed.toFixed(1)} Hz</text>
    <text x="270" y="14" fill="var(--muted)" font-size="9" font-family="Inter" text-anchor="end">Noise ${Math.round(noise * 100)}%</text>
  </svg>`;

  return {
    hide: ["wave_speed", "wave_phase"],
    ui: ui.column([
      ui.svg(84, svg, { id: "preview", fit: "fill" }),
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
