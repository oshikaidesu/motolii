// Custom Inspector card template for `rise_to_sound.js`.
// Displays the [Start Frequency .. End Frequency] selection window over a
// log-scaled 20Hz–12kHz spectrum bar chart.

function freqToU(hz) {
  const clamped = Math.max(20, Math.min(12000, hz));
  return Math.log(clamped / 20) / Math.log(12000 / 20);
}

function uToFreq(u) {
  const t = Math.max(0, Math.min(1, u));
  return Math.round(20 * Math.pow(12000 / 20, t));
}

function renderCard(ctx) {
  const p = ctx.params || {};
  const lo = Math.max(20, Math.min(12000, Number(p.start ?? 20)));
  const hi = Math.max(lo + 20, Math.min(12000, Number(p.end ?? 2000)));
  const u0 = freqToU(lo);
  const u1 = freqToU(hi);

  const draw = [];
  const count = 24;
  for (let i = 0; i < count; i++) {
    const bu = (i + 0.5) / count;
    const amp = 0.22 + 0.62 * Math.exp(-Math.pow((bu - 0.22) / 0.18, 2)) + 0.35 * Math.exp(-Math.pow((bu - 0.62) / 0.22, 2));
    const inBand = bu >= u0 && bu <= u1;
    draw.push({
      op: "rect",
      x: 0.03 + i * 0.039,
      y: 0.88 - amp * 0.68,
      w: 0.030,
      h: amp * 0.68,
      radius: 1.5,
      fill: inBand ? "blend" : "muted",
      alpha: inBand ? 0.88 : 0.30,
    });
  }
  const bx = 0.03 + u0 * 0.94;
  const bw = Math.max(0.04, (u1 - u0) * 0.94);
  draw.push(
    { op: "rect", x: bx, y: 0.14, w: bw, h: 0.74, fill: "blend", alpha: 0.14, stroke: "blend", width: 1.3, radius: 3 },
    { op: "text", x: 0.04, y: 0.10, text: Math.round(lo) + " Hz", fill: "blend" },
    { op: "text", x: 0.96, y: 0.10, text: Math.round(hi) + " Hz", fill: "blend", align: "right" }
  );

  return {
    hide: ["start", "end"],
    ui: ui.column([
      ui.canvas(88, draw, { id: "band", label: "Frequency Band (20Hz – 12kHz)" }),
      ui.row([
        ui.button("Sub", "preset:sub"),
        ui.button("Bass", "preset:bass"),
        ui.button("Vocal", "preset:vocal"),
        ui.button("Full", "preset:full"),
      ]),
    ]),
  };
}

function onCardAction(action, ctx) {
  if (action.id === "band" && action.value) {
    const center = Math.max(0.05, Math.min(0.95, Number(action.value.x ?? 0.3)));
    const lo = uToFreq(Math.max(0, center - 0.18));
    const hi = uToFreq(Math.min(1, center + 0.18));
    return { set: { start: lo, end: hi } };
  }
  if (action.id === "preset:sub") return { set: { start: 20, end: 180 } };
  if (action.id === "preset:bass") return { set: { start: 60, end: 500 } };
  if (action.id === "preset:vocal") return { set: { start: 300, end: 3400 } };
  if (action.id === "preset:full") return { set: { start: 20, end: 12000 } };
  return {};
}
