// Type definitions for Motolii expression & Vism host globals
// (host_prelude.js in expressions; panel_script.cpp in Vism panels & cards).

export type Vec2 = [number, number];
export type Vec3 = [number, number, number];
export type Vec4 = [number, number, number, number];

export interface LayerBounds {
  readonly x: number;
  readonly y: number;
  readonly width: number;
  readonly height: number;
  readonly left: number;
  readonly top: number;
  readonly rotate: number;
  readonly halfX: number;
  readonly halfY: number;
  readonly px: number;
}

export interface CameraInfo {
  readonly eye: Vec3;
  readonly look: Vec3;
  readonly up: Vec3;
  readonly fov: number;
  readonly distance: number;
  readonly id: number;
}

export interface AudioBands {
  readonly bass: number;
  readonly lowMid: number;
  readonly highMid: number;
  readonly treble: number;
  readonly rms: number;
}

export interface AudioHandle extends AudioBands {
  at(t: number): AudioHandle;
  bands(t?: number): AudioBands;
  spectrum(out?: Uint8Array | Float32Array, t?: number): Uint8Array | Float32Array;
  wave(out?: Float32Array, t?: number): Float32Array;
  /** Vism UI runtime extras (populated from ctx.waveform / ctx.strikes when present). */
  readonly waveform?: number[];
  readonly strikes?: number[];
}

export interface MidiState {
  readonly vel: number;
  readonly pitch: number;
  readonly gate: number;
  readonly bpm: number;
}

export interface LayerHandle {
  readonly id: number;
  readonly exists: boolean;
  readonly name: string;
  readonly kind: string;
  readonly text: string;
  readonly index: number;
  readonly parent: LayerHandle | null;
  readonly children: LayerHandle[];
  readonly start: number;
  readonly duration: number;
  readonly x: number;
  readonly y: number;
  readonly z: number;
  readonly pos: Vec3;
  readonly size: number;
  readonly scaleX: number;
  readonly scaleY: number;
  readonly scaleZ: number;
  readonly scale: Vec3;
  readonly anchor: Vec3;
  readonly rotate: number;
  readonly rotateX: number;
  readonly rotateY: number;
  readonly opacity: number;
  readonly bounds: LayerBounds | null;
  /** Vism UI runtime metadata (when backed by ctx.layers). */
  readonly visible?: boolean;
  readonly selected?: boolean;
  readonly fill?: string;

  at(t: number): LayerHandle;
  copy(index: number): LayerHandle;
  get(prop: string, fallback?: number, t?: number): number;
  word(prop: string): string;
  keys(prop: string): number[];
  fx(effectName: string, paramName: string, fallback?: number, t?: number): number;
  toWorld(point: Vec2 | Vec3, t?: number): Vec3;
  fromWorld(point: Vec2 | Vec3, t?: number): Vec2;
  sample(point: Vec2, radius?: Vec2 | number, postEffect?: boolean, t?: number): Vec4;
}

export interface StageHost {
  readonly time: number;
  readonly fps: number;
  readonly frame: number;
  readonly width: number;
  readonly height: number;
  readonly duration: number;
  readonly px: number;
  readonly bpm: number;
  readonly bpmFrom: number;
  readonly beat: number;
  readonly layers: LayerHandle[];
  readonly self: LayerHandle;
  /** Selected layers in Vism UI panels (empty in expressions). */
  readonly selected?: LayerHandle[];
  readonly marks?: Array<{ time: number; name: string }>;

  camera(t?: number): CameraInfo;
  toScreen(point: Vec3, t?: number): Vec2;
  get(prop: string, fallback?: number, t?: number): number;
  word(prop: string): string;
}

declare global {
  function layer(ref?: string | number | LayerHandle, t?: number): LayerHandle;
  const stage: StageHost;
  const audio: AudioHandle & ((ref?: string | number | LayerHandle, t?: number) => AudioHandle);
  const midi: MidiState & ((source?: string | number, channel?: number, t?: number) => MidiState);
}
