// --title: Quick Rig
// --about: 9-point anchor snap, brand swatches, and 1-click Audio Bounce macro rig.
// --acts: Layer
// --tone: place

const PALETTE = [
  "#59C3E8", "#FF5A79", "#FFB84D", "#C8E64C", "#A78BFA", "#F4F4F5"
];

function render(ctx) {
  const picked = ctx.selected || [];
  const active = (ctx.layers || []).find((l) => l.id === picked[0]);
  const ax = active ? (active.anchor_x ?? 0) : 0;
  const ay = active ? (active.anchor_y ?? 0) : 0;

  return ui.column([
    ui.row([
      ui.badge(active ? active.name : "No layer", { tone: active ? "place" : "muted" }),
      ui.spacer(4),
      ui.button("Reset", "reset", { disabled: !active }),
    ]),
    ui.xy("Anchor", ax, ay, { id: "anchor", min: -1, max: 1, snap9: true }),
    ui.section("Palette", [
      ui.grid(
        PALETTE.map((hex) => ui.swatch(hex, { id: "fill:" + hex, active: active && active.fill === hex })),
        { cols: 6 }
      ),
    ], { open: true }),
    ui.row([
      ui.button("Audio Bounce", "audio_bounce", { accent: true, disabled: !active }),
      ui.button("Wave Spin", "wave_spin", { disabled: !active }),
    ]),
  ]);
}

function onAction(action, ctx) {
  const picked = ctx.selected || [];
  if (picked.length === 0) return {};
  const id = picked[0];

  if (action.id === "anchor" && action.value) {
    return {
      ops: [
        { op: "set", layer: id, name: "anchor_x", value: Number(action.value.x || 0) },
        { op: "set", layer: id, name: "anchor_y", value: Number(action.value.y || 0) },
      ],
    };
  }

  if (action.id === "reset") {
    return {
      notice: "Centered transform",
      ops: [
        { op: "set", layer: id, name: "x", value: 0 },
        { op: "set", layer: id, name: "y", value: 0 },
        { op: "set", layer: id, name: "rotate", value: 0 },
        { op: "set", layer: id, name: "scale_x", value: 1 },
        { op: "set", layer: id, name: "scale_y", value: 1 },
      ],
    };
  }

  if (action.id && action.id.startsWith("fill:")) {
    const hex = action.id.slice(5);
    return {
      ops: [{ op: "say", layer: id, name: "fill", word: hex }],
    };
  }

  if (action.id === "audio_bounce") {
    return {
      notice: "Rigged Audio Bounce on Macro 1",
      ops: [
        { op: "say", layer: id, name: "macro_sources", word: "1 audio 0 1.8 0.05" },
        { op: "say", layer: id, name: "macro_names", word: "1\tBounce" },
        { op: "say", layer: id, name: "macro_map", word: "1 scale_x 1 1.25\n1 scale_y 1 1.25" },
      ],
    };
  }

  if (action.id === "wave_spin") {
    return {
      notice: "Rigged Wave Spin on Macro 2",
      ops: [
        { op: "say", layer: id, name: "macro_sources", word: "2 wave sine 0.5 0" },
        { op: "say", layer: id, name: "macro_names", word: "2\tSpin" },
        { op: "say", layer: id, name: "macro_map", word: "2 rotate -25 25" },
      ],
    };
  }

  return {};
}
