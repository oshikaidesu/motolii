// A TSL material turned to WGSL by three.js's own builder (WGSLNodeBuilder), with no GPU, in QuickJS: set up as three's
// Nodes._createNodeBuilder does (three.webgpu.js 55300-55310), the camera in WebGPU's own coordinates as its Renderer
// does before it draws (62657). Plain JavaScript with no tool in between: the shelf writers here bundle it (run.sh), and
// the engine reads it as it is when TSL is pasted in the app (engine/community/three/tsl_shelf.cpp).
import * as THREE from "three/webgpu";
export const renderer = new THREE.WebGPURenderer({ canvas: { getContext() { return null; }, style: {}, addEventListener() { } } });
// The two things the builder asks the GPU it will draw on, answered as plain WebGPU with no optional features.
renderer._initialized = true;
renderer.backend.hasFeature = () => false;
renderer.backend.utils = new Proxy({}, { get: (_, k) => () => k === "getTextureSampleData" ? { primarySamples: 1 } : undefined });
export const plane = new THREE.PlaneGeometry(2, 2);
export function built(object, material, camera, scene) {
    camera ??= new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
    scene ??= new THREE.Scene();
    camera.coordinateSystem = THREE.WebGPUCoordinateSystem;
    camera.updateProjectionMatrix();
    scene.updateMatrixWorld();
    camera.updateMatrixWorld();
    object.updateMatrixWorld();
    const b = new THREE.WGSLNodeBuilder(object, renderer);
    b.scene = scene;
    b.material = material;
    b.camera = camera;
    b.context.material = material;
    b.build();
    return b;
}
export function wgsl(object, material, camera, scene) {
    const b = built(object, material, camera, scene);
    return [b.vertexShader, b.fragmentShader];
}
