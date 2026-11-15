// Icosahedron: the thing's picture on the twenty flat faces of an icosahedron
// (the built-in gem of Alight Motion; three.js IcosahedronGeometry with detail
// 0, made flat-faced by its own toNonIndexed and computeVertexNormals: MIT).
// --track@size:Size,0.05,4,1,0.01
// --check@lit:Lit,1
import * as THREE from '../../engine/third_party/js/three/three.core.js';
export function solid(k) {
    const g = new THREE.IcosahedronGeometry(k.size * k.h / 2, 0).toNonIndexed();
    g.computeVertexNormals();
    return g;
}
