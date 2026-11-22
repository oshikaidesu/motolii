# Custom Inspector Card Specification (`.ui.js`)

[日本語](CUSTOM_CARDS.ja.md)

This specification describes how third-party authors attach dedicated, native Inspector card UIs to any Motolii effect (`.wgsl`, `.fs`, `.js`, TSL) or expression (`shelves/expressions/*.js`) with **no WebView and no build step**.

> **Two extension points**
> - **Custom Cards (this document)**: Per-effect / per-expression UI rendered at the top of an Inspector card, directly driving the effect's own parameters.
> - **Custom Tabs (`shelves/panels/*.js`)**: Composition-wide tools and batch utilities in the Tool Panel and dockable tabs. They share the same `ui.*` builder, with `render(ctx)` and `onAction(action, ctx)` entry points.

---

## 1. File Discovery

Leave the original shader or script untouched and place a matching `.ui.js` sidecar next to it:

```text
shelves/effects/blur/
  Diagonal Blur.fs       # original shader (untouched)
  Diagonal Blur.ui.js    # custom Inspector card UI

shelves/expressions/
  rigid_body.js          # expression script
  rigid_body.ui.js       # custom Inspector card UI
```

- **Sidecar first**: `<dir>/<stem>.ui.js` takes precedence when present.
- **Co-located fallback**: A `.js` / `.mjs` effect may also define `function renderCard(ctx)` directly inside the same file.
- **Hidden from shelves**: `*.ui.js` files are excluded from effect and expression shelf listings.
- **User folder**: The same layout works inside the user's custom shelves directory.

---

## 2. Minimal Example

```js
// my_blur.ui.js — placed next to my_blur.fs or my_blur.wgsl
function renderCard(ctx) {
  const width = Number(ctx.params.width ?? 0.25);
  const angle = Number(ctx.params.angle ?? 0);
  const deg = Math.round(angle * 180);

  const svg = `<svg viewBox="0 0 280 88">
    <circle cx="140" cy="44" r="34" fill="none" stroke="var(--border)" stroke-width="1"/>
    <line x1="140" y1="44"
          x2="${140 + Math.cos(Math.PI * angle) * width * 34}"
          y2="${44 + Math.sin(Math.PI * angle) * width * 34}"
          stroke="var(--accent)" stroke-width="2" stroke-linecap="round"/>
    <text x="10" y="15" fill="var(--muted)" font-size="9.5" font-family="Inter">${deg}°</text>
  </svg>`;

  return {
    hide: ["width", "angle"],
    ui: ui.column([
      ui.svg(88, svg, { id: "compass", label: "Blur Vector" }),
      ui.row([
        ui.button("Horiz", "preset:h"),
        ui.button("Vert", "preset:v"),
        ui.button("Off", "preset:off"),
      ]),
    ]),
  };
}

function onCardAction(action, ctx) {
  if (action.id === "compass" && action.value) {
    const nx = (Number(action.value.x) - 0.5) / 0.25;
    const ny = (Number(action.value.y) - 0.5) / 0.42;
    const w = Math.min(1, Math.hypot(nx, ny));
    return { set: { width: w, angle: Math.atan2(ny, nx) / Math.PI } };
  }
  if (action.id === "preset:h") return { set: { width: 0.25, angle: 0 } };
  if (action.id === "preset:v") return { set: { width: 0.25, angle: 0.5 } };
  if (action.id === "preset:off") return { set: { width: 0 } };
  return {};
}
```

---

## 3. Lifecycle & API Contract

### `renderCard(ctx)` (required)

Pure function returning the declarative UI tree for the current snapshot.

#### `ctx` (input)
| Field | Type | Description |
|---|---|---|
| `ctx.card` | `string` | Card display title |
| `ctx.params` | `Record<string, number \| string>` | Current parameter values, accessible by **both** full declared name (e.g. `field_radius`) and common-prefix-stripped short name (e.g. `radius`) |
| `ctx.ranges` | `Record<string, { min, max, unit, label }>` | Declared parameter range metadata |
| `ctx.theme` | `Record<string, string>` | Active Motolii skin colors as `#rrggbb` |
| `ctx.state` | `Record<string, unknown>` | Ephemeral card-local UI state (not persisted to the document) |
| `ctx.time` | `number` | Current playhead time in seconds |
| `ctx.fps` | `number` | Composition frame rate |
| `ctx.audio` | `number[]` | Live 24-band log-spaced audio FFT spectrum (20 Hz – 12 kHz, each `0..1`) at `ctx.time`, or `[]` when no audio is active / still decoding |

#### Return value
- `{ hide?: string[], ui: UiNode }` (or a bare `UiNode` when nothing is tucked)
- **`hide` behavior**: Parameters listed in `hide` are tucked into a collapsible **`> Parameters`** fold below the custom card rather than removed, keeping keyframes and Macro `○` plug routing reachable while preserving a single source of truth.

### `onCardAction(action, ctx)` (optional)

Invoked when the user interacts with a control.

#### `action` (input)
- `action.id`: Control `id`
- `action.value`: Control payload (`true` for buttons, `number` for sliders/numbers, `boolean` for toggles, `string` for select/input/color, `{ x, y }` for `xy`, `{ x, y, phase: "down" | "drag" | "up", shift: boolean }` for `ui.svg` and `ui.canvas`)
- `action.live`: `true` while dragging continuously, `false` on click or pointer release (coalesced into one undo step by the host).

#### Return value
```js
{
  set?: { [paramName]: number },   // numeric parameter updates
  say?: { [paramName]: string },   // string parameter updates
  state?: { [key]: unknown },      // ephemeral UI state merge (`null` deletes a key)
}
```

- **Zero-boilerplate direct binding**: If `onCardAction` is omitted or returns `{}` and the control `id` matches a parameter name (or `"xParam,yParam"` for `xy`), Motolii writes directly to that parameter.

---

## 4. UI Primitives & Standard SVG (`ui.svg`)

Every node renders natively with Motolii's widgets and active skin (no HTML or WebView). See [`shelves/motolii-ui.d.ts`](../shelves/motolii-ui.d.ts) for the authoritative type reference of every builder method and option.

- **Layout**: `ui.column`, `ui.row`, `ui.grid`, `ui.section`, `ui.divider`, `ui.spacer`
- **Display**: `ui.text`, `ui.badge`, `ui.meter`, `ui.swatch`
- **Controls**: `ui.button`, `ui.toggle`, `ui.slider`, `ui.number`, `ui.select`, `ui.input`, `ui.color`, `ui.xy`
- **Custom vector graphics**: **`ui.svg`** (recommended), `ui.canvas`

### `ui.svg(height, svgMarkup, { id?, label?, fit? })`
Renders standard SVG markup natively via `flutter_svg`, unlocking `<path>`, `<linearGradient>`, `<radialGradient>`, `stroke-dasharray`, `transform`, and standard vector tooling output without expanding host-specific draw commands.

- **Skin-adaptive colors (`var(--token)`)**: `var(--accent)`, `var(--layout)`, `var(--blend)`, `var(--place)`, `var(--time)`, `var(--layer)`, `var(--text)`, `var(--muted)`, `var(--border)`, `var(--surface)`, and `var(--well)` resolve automatically to the active skin.
- **Fit modes**: `"contain"` (default, preserves `viewBox` aspect ratio for compasses/circles), `"fill"` (stretches full width with `preserveAspectRatio="none"` for charts/waveforms), or `"cover"`.
- **Pointer input**: Providing `id` turns the SVG into an interactive surface reporting normalized `{ x, y, phase, shift }` events.

---

## 5. Multi-Handle Dragging (`ctx.state`)

Keep transient interaction state (such as which handle is grabbed) out of the document by returning `state` from `onCardAction`. See [`shelves/expressions/rise_to_sound.ui.js`](../shelves/expressions/rise_to_sound.ui.js) for a complete 3-zone (`lo` / `hi` / `pan`) implementation:

```js
function onCardAction(action, ctx) {
  if (action.id === "band" && action.value) {
    const { x, phase } = action.value;
    if (phase === "up") return { state: { drag: null } };
    const mode = phase === "down" ? hitTestHandle(x, ctx.params) : ctx.state.drag;
    if (mode === "lo") return { set: { start: toHz(x) }, state: { drag: "lo" } };
    if (mode === "hi") return { set: { end: toHz(x) }, state: { drag: "hi" } };
  }
  return {};
}
```

---

## 6. Developer Workflow & Sandbox Guarantees

- **Editor autocomplete**: [`shelves/motolii-ui.d.ts`](../shelves/motolii-ui.d.ts) and [`shelves/jsconfig.json`](../shelves/jsconfig.json) give instant VS Code / Cursor autocomplete and JSDoc hovers for `ui.*`, `ctx`, and `action`.
- **Hot reload on save**: Saving a `.ui.js` file re-evaluates the card automatically (~80 ms debounce) with no restart.
- **Non-crashing error recovery**: Syntax or runtime errors render inline with the script name, line message, and a `Retry` action; saving a fix recovers automatically.
- **Sandbox limits**: QuickJS runs with a **16 MiB memory cap** and **500 ms interrupt timeout**, with no filesystem or network access.

---

## 7. Bundled Reference Templates

- Physics & vector compass: [`rigid_body.ui.js`](../shelves/expressions/rigid_body.ui.js), [`wind.ui.js`](../shelves/expressions/wind.ui.js)
- Spatial falloff map: [`Field.ui.js`](../shelves/expressions/Field.ui.js)
- Live playback time & audio FFT (multi-handle): [`wave.ui.js`](../shelves/expressions/wave.ui.js), [`rise_to_sound.ui.js`](../shelves/expressions/rise_to_sound.ui.js)
- Squash/stretch & text cascade: [`Scale_Assist.ui.js`](../shelves/expressions/Scale_Assist.ui.js), [`lyric.ui.js`](../shelves/expressions/lyric.ui.js)
- Shader sidecar: [`Diagonal Blur.ui.js`](../shelves/effects/blur/Diagonal%20Blur.ui.js)
