// Type definitions for Motolii Custom UI scripts:
// - Inspector Effect / Expression Cards (`<effect>.ui.js` or co-located `renderCard`)
// - Dockable Custom Panels / Tabs (`shelves/panels/*.js`)
//
// Drop a `.ui.js` file next to any `.js` / `.fs` / `.wgsl` file, or a `.js` file
// into `shelves/panels/`, and Motolii hot-reloads it on save.

declare namespace MotoliiUi {
  type Tone =
    | "accent"
    | "layout"
    | "blend"
    | "place"
    | "time"
    | "layer"
    | "muted";

  interface ThemeColors {
    accent: string;
    layout: string;
    blend: string;
    place: string;
    time: string;
    layer: string;
    muted: string;
    border: string;
    text: string;
    surface: string;
    well: string;
  }

  interface ParamRange {
    min?: number;
    max?: number;
    unit?: string;
    label?: string;
  }

  interface PointerPayload {
    /** Normalized horizontal coordinate in 0..1. */
    x: number;
    /** Normalized vertical coordinate in 0..1. */
    y: number;
    /** Gesture phase. */
    phase: "down" | "drag" | "up";
    /** True while Shift is held. */
    shift: boolean;
  }

  interface UiNode {
    type: string;
    [key: string]: unknown;
  }

  interface DrawOp {
    op: "line" | "rect" | "circle" | "arc" | "polyline" | "bezier" | "text";
    x?: number;
    y?: number;
    x2?: number;
    y2?: number;
    w?: number;
    h?: number;
    r?: number;
    cx1?: number;
    cy1?: number;
    cx2?: number;
    cy2?: number;
    start?: number;
    sweep?: number;
    width?: number;
    alpha?: number;
    radius?: number;
    fill?: string;
    stroke?: string;
    text?: string;
    align?: "left" | "center" | "right";
    points?: Array<[number, number]>;
  }

  interface UiBuilder {
    column(children: UiNode[], opts?: Record<string, unknown>): UiNode;
    row(children: UiNode[], opts?: Record<string, unknown>): UiNode;
    grid(children: UiNode[], opts?: { cols?: number }): UiNode;
    section(title: string, children: UiNode[], opts?: { open?: boolean }): UiNode;
    text(text: string, opts?: { muted?: boolean; bold?: boolean }): UiNode;
    badge(text: string, opts?: { tone?: Tone }): UiNode;
    meter(value: number, opts?: { label?: string; tone?: Tone }): UiNode;
    swatch(color: string, opts?: { id?: string; active?: boolean; tip?: string }): UiNode;
    button(label: string, id?: string, opts?: { accent?: boolean; tone?: Tone; disabled?: boolean }): UiNode;
    toggle(label: string, value: boolean, opts?: { id?: string; disabled?: boolean }): UiNode;
    slider(
      label: string,
      value: number,
      opts?: { id?: string; min?: number; max?: number; step?: number; dec?: number; unit?: string }
    ): UiNode;
    number(
      label: string,
      value: number,
      opts?: { id?: string; min?: number; max?: number; step?: number; dec?: number; unit?: string }
    ): UiNode;
    select(label: string, value: string, options: string[], opts?: { id?: string }): UiNode;
    input(label: string, value: string, opts?: { id?: string; placeholder?: string }): UiNode;
    color(label: string, value: string, opts?: { id?: string }): UiNode;
    xy(
      label: string,
      x: number,
      y: number,
      opts?: { id?: string; min?: number; max?: number; snap9?: boolean }
    ): UiNode;
    /**
     * Renders standard SVG markup natively via `flutter_svg`.
     * Use `var(--accent)`, `var(--blend)`, `var(--place)`, `var(--time)`, `var(--layer)`,
     * `var(--layout)`, `var(--border)`, `var(--muted)`, `var(--text)`, `var(--well)`
     * so colors adapt automatically to every Motolii skin.
     */
    svg(
      height: number,
      svgMarkup: string,
      opts?: { id?: string; label?: string; fit?: "contain" | "fill" | "cover" }
    ): UiNode;
    canvas(
      height: number,
      draw: DrawOp[],
      opts?: { id?: string; label?: string }
    ): UiNode;
    divider(): UiNode;
    spacer(size?: number): UiNode;
  }

  /** Context passed to `renderCard(ctx)` and `onCardAction(action, ctx)`. */
  interface CardContext {
    /** Display title of the card. */
    card: string;
    /** Current parameter values indexed by short name and full `--track@` name. */
    params: Record<string, number | string>;
    /** Declared min/max/unit metadata per parameter name. */
    ranges: Record<string, ParamRange>;
    /** Active Motolii skin palette as `#rrggbb` hex strings. */
    theme: ThemeColors;
    /** Ephemeral card-local UI state (not saved to document; ideal for multi-handle drags). */
    state: Record<string, unknown>;
    /** Current playhead time in seconds. */
    time: number;
    /** Composition frame rate. */
    fps: number;
    /**
     * Live 24-band log-spaced audio FFT spectrum (20 Hz – 12 kHz, each 0..1) at `time`,
     * or empty array when no audio track is active.
     */
    audio: number[];
    /** Current layer being inspected. */
    layer?: PanelLayer;
    /** All layers in the composition. */
    layers?: PanelLayer[];
    /** Saved user JSON presets for this card. */
    presets?: Record<string, unknown>;
    /** Composition size and scale. */
    comp?: { width: number; height: number; point: number };
  }

  interface CardRenderResult {
    /** Parameter names tucked into the collapsible `Parameters >` fold (still keyframeable & Macro-mappable). */
    hide?: string[];
    /** Root declarative UI node tree. */
    ui: UiNode;
  }

  interface CardAction {
    id: string;
    value: unknown;
    /** True during continuous drag; false on tap or pointer release (commits undo step). */
    live: boolean;
  }

  interface CardActionResult {
    /** Numeric parameter writes keyed by parameter name. */
    set?: Record<string, number>;
    /** String parameter writes keyed by parameter name. */
    say?: Record<string, string>;
    /** Ephemeral UI state keys to merge into `ctx.state` (not persisted to document). */
    state?: Record<string, unknown>;
    /** Optional document mutations (e.g. explode, add backplate, bake keyframes, preset_save). */
    ops?: PanelOp[];
    /** Status banner message. */
    notice?: string;
  }

  interface PanelLayer {
    id: number;
    name: string;
    kind: string;
    selected: boolean;
    parent: number;
    start: number;
    duration: number;
    x: number;
    y: number;
    z: number;
    rotate: number;
    scale_x: number;
    scale_y: number;
    anchor_x: number;
    anchor_y: number;
    opacity: number;
    fill: string;
    text: string;
    split: string;
    space: string;
    font: string;
    size: number;
    width: number;
    height: number;
  }

  /** Context passed to `render(ctx)` and `onAction(action, ctx)` in `shelves/panels/*.js`. */
  interface PanelContext {
    time: number;
    frame: number;
    fps: number;
    duration: number;
    comp: { width: number; height: number; point: number };
    selected: number[];
    layers: PanelLayer[];
    state: Record<string, unknown>;
    presets: Record<string, unknown>;
    theme: ThemeColors;
    audio: number[];
  }

  type PanelOp =
    | { op: "set"; layer: number; name: string; value?: number; word?: string }
    | { op: "say"; layer: number; name: string; word: string }
    | { op: "key"; layer: number; name: string; at: number; value: number; ease?: string }
    | { op: "add"; kind?: string; file?: string }
    | { op: "explode"; layer: number; mode?: "letters" | "strokes" }
    | { op: "outline"; layer: number }
    | { op: "remove"; layer: number }
    | { op: "fx"; layer: number; file: string }
    | { op: "preset_save"; name: string; word: string }
    | { op: "preset_delete"; name: string }
    | { op: "select"; layers: number[] }
    | { op: "time"; at: number };

  interface PanelActionResult {
    state?: Record<string, unknown>;
    notice?: string;
    ops?: PanelOp[];
  }
}

declare const ui: MotoliiUi.UiBuilder;
