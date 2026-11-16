// Runs after the shape script is imported. It calls solid(k) and leaves the
// result in globals as flat typed arrays: __pos, __nrm, __uv, __idx and
// __repeat. Normals are computed if the geometry has none, and an unindexed
// geometry gets a sequential index. On failure it sets __why.
const k = globalThis.__k;
if (globalThis.__cover) k.alpha = { width: k.coverW, height: k.coverH, values: new Uint8Array(globalThis.__cover) };
try {
    const g = solid(k), n = g.attributes.position ? g.attributes.position.count : 0;
    if (n && !g.attributes.normal) g.computeVertexNormals();
    globalThis.__pos = n ? Float32Array.from(g.attributes.position.array) : new Float32Array(0);
    globalThis.__nrm = n ? Float32Array.from(g.attributes.normal.array) : new Float32Array(0);
    globalThis.__uv = n && g.attributes.uv ? Float32Array.from(g.attributes.uv.array) : new Float32Array(2 * n);
    globalThis.__idx = g.index ? Uint32Array.from(g.index.array) : Uint32Array.from({ length: n }, (_, i) => i);
    globalThis.__repeat = !!g.userData.repeat;
} catch (e) { globalThis.__why = String(e) + ' ' + (e.stack || ''); }
