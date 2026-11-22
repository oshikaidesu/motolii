// --title: Stagger
// --about: Sequence and align selected layers in time (like AE Rift / Motion Stagger).
// --acts: Selection
// --tone: layout

function render(ctx) {
  const st = ctx.state || {};
  const step = st.step ?? 4;
  const order = st.order ?? "top";
  const fromPlayhead = st.fromPlayhead ?? true;
  const picked = ctx.selected || [];

  return ui.column([
    ui.row([
      ui.badge(
        picked.length === 0
          ? "Pick layers"
          : picked.length + (picked.length === 1 ? " layer" : " layers"),
        { tone: picked.length > 0 ? "accent" : "muted" }
      ),
      ui.spacer(4),
      ui.text("FPS " + Math.round(ctx.fps || 60), { muted: true }),
    ]),
    ui.row([
      ui.number("Step", step, { id: "step", min: 1, max: 120, step: 1, unit: "f" }),
      ui.select("Order", order, ["top", "bottom", "random"], { id: "order" }),
    ]),
    ui.toggle("Start at playhead", fromPlayhead, { id: "fromPlayhead" }),
    ui.row([
      ui.button("Stagger", "stagger", { accent: true, disabled: picked.length < 2 }),
      ui.button("Align Start", "align", { disabled: picked.length === 0 }),
    ]),
  ]);
}

function onAction(action, ctx) {
  const st = Object.assign({ step: 4, order: "top", fromPlayhead: true }, ctx.state);
  if (action.id === "step") return { state: Object.assign(st, { step: Math.max(1, action.value) }) };
  if (action.id === "order") return { state: Object.assign(st, { order: action.value }) };
  if (action.id === "fromPlayhead") return { state: Object.assign(st, { fromPlayhead: !!action.value }) };

  const picked = (ctx.selected || []).slice();
  if (picked.length === 0) return { notice: "Select at least one layer" };

  const fps = ctx.fps || 60;
  const byId = {};
  for (const l of (ctx.layers || [])) byId[l.id] = l;
  const base = st.fromPlayhead ? (ctx.time || 0) : (byId[picked[0]]?.start || 0);

  if (action.id === "align") {
    return {
      notice: "Aligned " + picked.length + " layer(s)",
      ops: picked.map((id) => ({ op: "set", layer: id, name: "start", value: base })),
    };
  }

  if (action.id === "stagger") {
    let ids = picked.slice();
    if (st.order === "bottom") ids.reverse();
    if (st.order === "random") {
      // Deterministic Fisher-Yates seeded by playhead frame so repeat clicks vary cleanly.
      let seed = Math.floor((ctx.time || 0) * fps) + ids.length * 31;
      for (let i = ids.length - 1; i > 0; i--) {
        seed = (seed * 1664525 + 1013904223) >>> 0;
        const j = seed % (i + 1);
        const tmp = ids[i]; ids[i] = ids[j]; ids[j] = tmp;
      }
    }
    const dt = st.step / fps;
    return {
      notice: "Staggered " + ids.length + " layers by " + st.step + "f",
      ops: ids.map((id, i) => ({ op: "set", layer: id, name: "start", value: base + i * dt })),
    };
  }
  return {};
}
