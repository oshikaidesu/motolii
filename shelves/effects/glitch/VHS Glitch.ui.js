// Sidecar Vism custom card UI for `VHS Glitch.fs` — Retro CRT tape deck faceplate.
function renderCard(ctx) {
  const p = ctx.params || {};
  const distort = Number(p.analogDistort ?? 1.0);
  const grain = Number(p.grainLevel ?? 0.0);
  const bleed = Number(p.bleedAmount ?? 1.0);
  const scan = Number(p.xScanline ?? 0.5);
  const autoScan = Number(p.autoScan ?? 1) >= 0.5;
  const t = Number(ctx.time ?? 0);

  return {
    hide: ["analogDistort", "grainLevel", "bleedAmount", "xScanline", "autoScan"],
    surface: {
      bg: "#16181F",
      bg2: "#0E1016",
      fg: "#E6FFF0",
      muted: "#7B9989",
      accent: "#00FF88",
      border: "#2B3833",
      borderWidth: 1.6,
      radius: 8,
      pad: 9,
      mono: true,
    },
    ui: ui.column([
      ui.stack([
        ui.shader(78, "vhs", {
          id: "crt",
          time: t + scan * 2.0,
          paramA: Math.min(1, distort / 10),
          paramB: Math.min(1, grain / 3),
          color: "#00FF88",
          color2: "#FF3B7F",
          color3: "#00D4FF",
          style: { border: "#2B3833", borderWidth: 1.4, radius: 5 },
        }),
        ui.badge(autoScan ? "VHS · AUTO TRACK" : "VHS · MANUAL", {
          align: "topLeft",
          inset: 6,
          style: {
            bg: "#0A140ECC",
            fg: "#00FF88",
            border: "#00FF8866",
            radius: 3,
            fontSize: 8.5,
            mono: true,
          },
        }),
      ]),
      ui.row([
        ui.knob("DISTORT", distort, {
          id: "analogDistort",
          min: 0,
          max: 10,
          def: 1,
          look: "hardware",
          size: 40,
          color: "#00FF88",
        }),
        ui.knob("GRAIN", grain, {
          id: "grainLevel",
          min: 0,
          max: 3,
          def: 0,
          look: "hardware",
          size: 40,
          color: "#FF3B7F",
        }),
        ui.knob("BLEED", bleed, {
          id: "bleedAmount",
          min: 0,
          max: 3,
          def: 1,
          look: "hardware",
          size: 40,
          color: "#00D4FF",
        }),
      ]),
      ui.row([
        ui.button("Clean", "p:clean"),
        ui.button("Tracking", "p:track", { accent: true }),
        ui.button("Destroy", "p:destroy"),
      ]),
    ], { gap: 7 }),
  };
}

function onCardAction(action) {
  if (action.id === "crt" && action.value) {
    const x = Math.max(0, Math.min(1, Number(action.value.x ?? 0.5)));
    const y = Math.max(0, Math.min(1, Number(action.value.y ?? 0.5)));
    return { set: { analogDistort: x * 10, grainLevel: (1 - y) * 3 } };
  }
  if (action.id === "p:clean") {
    return { set: { analogDistort: 0.4, grainLevel: 0.15, bleedAmount: 0.6, autoScan: 1 } };
  }
  if (action.id === "p:track") {
    return { set: { analogDistort: 3.5, grainLevel: 0.9, bleedAmount: 1.6, autoScan: 1 } };
  }
  if (action.id === "p:destroy") {
    return { set: { analogDistort: 8.5, grainLevel: 2.4, bleedAmount: 2.8, autoScan: 1 } };
  }
  return {};
}
