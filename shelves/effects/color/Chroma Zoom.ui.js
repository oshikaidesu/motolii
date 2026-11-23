// Sidecar Vism custom card UI for `Chroma Zoom.fs` — Flat-Pop RGB chromatic zoom deck.
function renderCard(ctx) {
  const p = ctx.params || {};
  const master = Number(p.master_zoom ?? 1);
  const r = Number(p.red_zoom ?? 1);
  const g = Number(p.green_zoom ?? 1);
  const b = Number(p.blue_zoom ?? 1);

  return {
    hide: ["master_zoom", "red_zoom", "green_zoom", "blue_zoom"],
    surface: {
      bg: "#FFF4C4",
      fg: "#141414",
      muted: "#4F4628",
      accent: "#FF3B7F",
      border: "#141414",
      borderWidth: 2.2,
      radius: 12,
      pad: 9,
      shadow: { x: 3, y: 3, blur: 0, color: "#141414" },
    },
    ui: ui.column([
      ui.row([
        ui.badge("CHROMA ZOOM", {
          style: {
            bg: "#FFE600",
            fg: "#141414",
            border: "#141414",
            borderWidth: 1.8,
            radius: 5,
            shadow: { x: 2, y: 2, blur: 0, color: "#141414" },
          },
        }),
        ui.spacer(),
        ui.text(master.toFixed(2) + "x", {
          bold: true,
          style: { fg: "#141414", fontSize: 10, mono: true },
        }),
      ]),
      ui.row([
        ui.knob("ZOOM", master, {
          id: "master_zoom",
          min: 0.1,
          max: 2.0,
          def: 1.0,
          look: "pop",
          size: 38,
          color: "#FFE600",
          capColor: "#FFFFFF",
          borderColor: "#141414",
        }),
        ui.knob("RED", r, {
          id: "red_zoom",
          min: 1.0,
          max: 1.5,
          def: 1.0,
          look: "pop",
          size: 38,
          color: "#FF3B7F",
          capColor: "#FFFFFF",
          borderColor: "#141414",
        }),
        ui.knob("GRN", g, {
          id: "green_zoom",
          min: 1.0,
          max: 1.5,
          def: 1.0,
          look: "pop",
          size: 38,
          color: "#B8FF2C",
          capColor: "#FFFFFF",
          borderColor: "#141414",
        }),
        ui.knob("BLU", b, {
          id: "blue_zoom",
          min: 1.0,
          max: 1.5,
          def: 1.0,
          look: "pop",
          size: 38,
          color: "#00D4FF",
          capColor: "#FFFFFF",
          borderColor: "#141414",
        }),
      ]),
      ui.row([
        ui.button("Punch", "p:punch", {
          style: {
            bg: "#FF3B7F",
            fg: "#FFFFFF",
            border: "#141414",
            borderWidth: 1.8,
            radius: 7,
          },
        }),
        ui.button("RGB Split", "p:split", {
          style: {
            bg: "#00D4FF",
            fg: "#141414",
            border: "#141414",
            borderWidth: 1.8,
            radius: 7,
          },
        }),
        ui.button("Reset", "p:reset", {
          style: {
            bg: "#FFFFFF",
            fg: "#141414",
            border: "#141414",
            borderWidth: 1.8,
            radius: 7,
          },
        }),
      ]),
    ], { gap: 7 }),
  };
}

function onCardAction(action) {
  if (action.id === "p:punch") {
    return { set: { master_zoom: 1.18, red_zoom: 1.12, green_zoom: 1.04, blue_zoom: 1.0 } };
  }
  if (action.id === "p:split") {
    return { set: { master_zoom: 1.0, red_zoom: 1.24, green_zoom: 1.08, blue_zoom: 1.0 } };
  }
  if (action.id === "p:reset") {
    return { set: { master_zoom: 1.0, red_zoom: 1.0, green_zoom: 1.0, blue_zoom: 1.0 } };
  }
  return {};
}
