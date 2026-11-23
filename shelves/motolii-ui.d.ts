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

  interface PanelShadow {
    x?: number;
    y?: number;
    blur?: number;
    spread?: number;
    color?: string;
  }

  /** Optional VST faceplate & per-control visual styling overrides. */
  interface PanelStyle {
    bg?: string;
    bg2?: string;
    gradAngle?: number;
    fg?: string;
    muted?: string;
    accent?: string;
    border?: string;
    borderWidth?: number;
    radius?: number;
    pad?: number;
    padX?: number;
    padY?: number;
    gap?: number;
    fontSize?: number;
    letterSpacing?: number;
    height?: number;
    mono?: boolean;
    align?: "left" | "center" | "right";
    framed?: boolean;
    shadow?: PanelShadow;
    controlBg?: string;
    controlFg?: string;
    controlBorder?: string;
  }

  interface Scene3dObject {
    shape?: "cube" | "sphere" | "torus" | "icosahedron" | "crystal" | "pyramid" | "cone" | "cylinder" | "ring";
    x?: number;
    y?: number;
    z?: number;
    scale?: number;
    rx?: number;
    ry?: number;
    rz?: number;
    color?: string;
    look?: "studio" | "toon" | "wireframe" | "holo" | "clay";
  }

  interface Scene3dOptions {
    id?: string;
    label?: string;
    shape?: "cube" | "sphere" | "torus" | "icosahedron" | "crystal" | "pyramid" | "cone" | "cylinder" | "ring" | "wavetable" | "gizmo";
    /** Optional relative or absolute `.glb` / `.obj` model file next to `.ui.js`. */
    model?: string;
    look?: "studio" | "toon" | "wireframe" | "holo" | "clay";
    yaw?: number;
    pitch?: number;
    roll?: number;
    zoom?: number;
    color?: string;
    color2?: string;
    outline?: string;
    outlineWidth?: number;
    bg?: string;
    bg2?: string;
    lightYaw?: number;
    lightPitch?: number;
    rimColor?: string;
    ambientColor?: string;
    ambient?: number;
    gloss?: number;
    grid?: boolean;
    axes?: boolean;
    shadow?: boolean;
    wireframe?: boolean;
    warp?: number;
    phase?: number;
    harmonics?: number;
    vertices?: Array<[number, number, number]>;
    faces?: number[][];
    objects?: Scene3dObject[];
    framed?: boolean;
    style?: PanelStyle;
  }

  interface UiBuilder {
    column(children: UiNode[], opts?: { style?: PanelStyle } & Record<string, unknown>): UiNode;
    row(children: UiNode[], opts?: { style?: PanelStyle } & Record<string, unknown>): UiNode;
    grid(children: UiNode[], opts?: { cols?: number; style?: PanelStyle }): UiNode;
    section(title: string, children: UiNode[], opts?: { open?: boolean; style?: PanelStyle }): UiNode;
    /** Styled faceplate/module box container (background, gradient, thick border, hard/soft shadow). */
    box(children: UiNode | UiNode[], opts?: PanelStyle & { id?: string; align?: string; inset?: number; style?: PanelStyle }): UiNode;
    /** Overlay stack container. Children may declare `align` ("topLeft".."bottomRight"|"center"|"fill") and `inset`. */
    stack(children: UiNode[], opts?: { align?: string }): UiNode;
    text(text: string, opts?: { muted?: boolean; bold?: boolean; align?: string; style?: PanelStyle }): UiNode;
    badge(text: string, opts?: { tone?: Tone; align?: string; inset?: number; style?: PanelStyle }): UiNode;
    meter(value: number, opts?: { label?: string; tone?: Tone; style?: PanelStyle }): UiNode;
    swatch(color: string, opts?: { id?: string; active?: boolean; tip?: string; style?: PanelStyle }): UiNode;
    button(label: string, id?: string, opts?: { accent?: boolean; tone?: Tone; disabled?: boolean; style?: PanelStyle }): UiNode;
    toggle(label: string, value: boolean, opts?: { id?: string; disabled?: boolean; style?: PanelStyle }): UiNode;
    /** Tactile VST rotary knob (vertical drag, Shift for fine precision, double-click resets to `def`). */
    knob(
      label: string,
      value: number,
      opts?: {
        id?: string;
        min?: number;
        max?: number;
        def?: number;
        step?: number;
        dec?: number;
        unit?: string;
        size?: number;
        look?: "arc" | "pop" | "hardware" | "minimal";
        color?: string;
        trackColor?: string;
        capColor?: string;
        borderColor?: string;
        style?: PanelStyle;
      }
    ): UiNode;
    slider(
      label: string,
      value: number,
      opts?: { id?: string; min?: number; max?: number; step?: number; dec?: number; unit?: string; style?: PanelStyle }
    ): UiNode;
    number(
      label: string,
      value: number,
      opts?: { id?: string; min?: number; max?: number; step?: number; dec?: number; unit?: string; style?: PanelStyle }
    ): UiNode;
    select(label: string, value: string, options: string[], opts?: { id?: string; style?: PanelStyle }): UiNode;
    input(label: string, value: string, opts?: { id?: string; placeholder?: string; style?: PanelStyle }): UiNode;
    color(label: string, value: string, opts?: { id?: string; style?: PanelStyle }): UiNode;
    xy(
      label: string,
      x: number,
      y: number,
      opts?: { id?: string; min?: number; max?: number; snap9?: boolean; style?: PanelStyle }
    ): UiNode;
    /**
     * Renders standard SVG markup natively via `flutter_svg`.
     * Set `framed: false` to blend seamlessly into a custom faceplate.
     */
    svg(
      height: number,
      svgMarkup: string,
      opts?: { id?: string; label?: string; fit?: "contain" | "fill" | "cover"; framed?: boolean; style?: PanelStyle }
    ): UiNode;
    canvas(
      height: number,
      draw: DrawOp[],
      opts?: { id?: string; label?: string; framed?: boolean; style?: PanelStyle }
    ): UiNode;
    /** Renders a PNG/WebP/JPG from a relative path next to `.ui.js` or a `data:image/...;base64,...` URI. */
    image(
      src: string,
      opts?: { id?: string; label?: string; height?: number; fit?: "contain" | "fill" | "cover"; framed?: boolean; style?: PanelStyle }
    ): UiNode;
    /**
     * Flutter-native 3D viewport widget (primitives, Serum-style 3D wavetable, `.glb`/`.obj` models,
     * interactive orbit drag emitting `{ yaw, pitch, x, y, phase, shift }`).
     */
    scene3d(height: number, opts?: Scene3dOptions): UiNode;
    divider(opts?: { style?: PanelStyle }): UiNode;
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
    /** Project tempo in BPM (0 when unset). */
    bpm?: number;
    /** Timeline markers in time order. */
    marks?: Array<{ time: number; name: string }>;
  }

  interface CardRenderResult {
    /** Parameter names tucked into the collapsible `Parameters >` fold (still keyframeable & Macro-mappable). */
    hide?: string[];
    /** Optional VST-style custom faceplate styling for the entire Inspector card container. */
    surface?: PanelStyle;
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
    order: number;
    visible: boolean;
    clip: boolean;
    fx: string;
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
    bpm: number;
    marks: Array<{ time: number; name: string }>;
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
    | { op: "psd"; file: string }
    | { op: "pivot"; layer: number; x: number; y: number }
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
