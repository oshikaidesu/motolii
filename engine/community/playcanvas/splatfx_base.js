// Stand-in for playcanvas-engine's gsplat-shader-effect.mjs: the base class
// an effect extends. Keeps the uniforms it is told and asks the effect
// subclass whether it has finished.
import { Script } from 'playcanvas';
export class GSplatShaderEffect extends Script {
    constructor() { super(); this.effectTime = 0; this.__uniforms = {}; }
    setUniform(name, v) { this.__uniforms[name] = typeof v === 'number' ? [v] : Array.from(v); }
    isEffectComplete() { const t = this.getCompletionTime ? this.getCompletionTime() : Infinity; return this.effectTime >= t; }
}
