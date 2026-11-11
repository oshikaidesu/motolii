// Plane: the thing's picture on a flat sheet of many points, for an effect that moves points (three.js PlaneGeometry: MIT).
// A layer with such an effect and no solid of its own is laid on this one.
// --track@across:Points Across,1,512,64,1
// --track@down:Points Down,1,512,64,1
// --check@lit:Lit,0
import * as THREE from '../../engine/third_party/js/three/three.core.js';
export function solid(k) {   // (k: its knobs, and k.w, k.h: how wide and high the thing is, in its own units)
    return new THREE.PlaneGeometry(k.w, k.h, Math.max(1, Math.round(k.across)), Math.max(1, Math.round(k.down)));
}
