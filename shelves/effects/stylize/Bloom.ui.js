// Sidecar Vism custom card UI for `Bloom.fs` — Studio optical bloom faceplate.
function renderCard(ctx) {
  const p = ctx.params || {};
  const blur = Number(p.blurAmount ?? 12);
  const intensity = Number(p.intensity ?? 0);
  const audio = ctx.audio || [];
  const energy = audio.length
    ? audio.reduce((a, b) => a + Number(b), 0) / audio.length
    : intensity * 0.65;

  return {
    hide: ["blurAmount", "intensity"],
    surface: {
      bg: "#171422",
      bg2: "#0E0C16",
      fg: "#F7F0FF",
      muted: "#9A8CB5",
      accent: "#FFB547",
      border: "#342B4A",
      borderWidth: 1.4,
      radius: 10,
      pad: 9,
    },
    ui: ui.column([
      ui.stack([
        ui.shader(76, "holo", {
          id: "halo",
          time: Number(ctx.time ?? 0),
          paramA: Math.min(1, intensity),
          paramB: Math.min(1, blur / 12),
          color: "#FFB547",
          color2: "#FF5E9C",
          color3: "#7C3AED",
          style: { border: "#FFB54744", borderWidth: 1.2, radius: 7 },
        }),
        ui.badge("OPTICAL BLOOM", {
          align: "topLeft",
          inset: 6,
          style: {
            bg: "#120E1ECC",
            fg: "#FFB547",
            border: "#FFB54766",
            radius: 4,
            fontSize: 8.5,
            mono: true,
          },
        }),
      ]),
      ui.row([
        ui.knob("SPREAD", blur, {
          id: "blurAmount",
          min: 0,
          max: 12,
          def: 6,
          look: "arc",
          size: 42,
          color: "#FF5E9C",
          capColor: "#1F1A2E",
        }),
        ui.knob("GLOW", intensity, {
          id: "intensity",
          min: 0,
          max: 1,
          def: 0.45,
          look: "arc",
          size: 42,
          color: "#FFB547",
          capColor: "#1F1A2E",
        }),
      ]),
      ui.vu(Math.min(1, Math.max(0.05, intensity * 0.8 + energy * 0.4)), {
        label: "BLOOM DRIVE",
        segments: 16,
        height: 10,
      }),
      ui.row([
        ui.button("Subtle", "p:subtle"),
        ui.button("Dreamy", "p:dreamy", { accent: true }),
        ui.button("Overdrive", "p:over"),
      ]),
    ], { gap: 7 }),
  };
}

function onCardAction(action) {
  if (action.id === "halo" && action.value) {
    const x = Math.max(0, Math.min(1, Number(action.value.x ?? 0.5)));
    const y = Math.max(0, Math.min(1, Number(action.value.y ?? 0.5)));
    return { set: { blurAmount: x * 12, intensity: 1 - y } };
  }
  if (action.id === "p:subtle") return { set: { blurAmount: 4.5, intensity: 0.25 } };
  if (action.id === "p:dreamy") return { set: { blurAmount: 10.0, intensity: 0.58 } };
  if (action.id === "p:over") return { set: { blurAmount: 12.0, intensity: 0.95 } };
  return {};
}
