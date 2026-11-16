// Builds the tangent frames Filament draws with, from the normals a points
// file supplied. Frisvad's basis (Filament SurfaceOrientation.cpp
// frisvadTangentSpace) followed by mat3f::packTangentFrame (math/mat3.h) with
// matrix::extractQuat (math/TMatHelpers.h), line for line. A point whose
// normal was left at zero keeps the frame its shape gave it.
@group(0) @binding(0) var<storage, read_write> normals: array<f32>;
@group(0) @binding(2) var<storage, read_write> frames: array<f32>;
@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) id: vec3u) {
  let i = id.x;
  if (3u * i + 2u >= arrayLength(&normals) || 4u * i + 3u >= arrayLength(&frames)) { return; }
  var n = vec3f(normals[3u * i], normals[3u * i + 1u], normals[3u * i + 2u]);
  let long = length(n);
  if (long == 0.0) { return; }
  n = n / long;
  var t = vec3f(-1.0, 0.0, 0.0);
  var b = vec3f(0.0, 0.0, -1.0);
  if (n.y >= -1.0 + 1.1920929e-7) {
    let a = 1.0 / (1.0 + n.y);
    let c = -n.z * n.x * a;
    t = vec3f(c, -n.z, 1.0 - n.z * n.z * a);
    b = vec3f(1.0 - n.x * n.x * a, -n.x, c);
  }
  var m = mat3x3f(t, cross(n, t), n);
  var q = vec4f(0.0);
  let trace = m[0][0] + m[1][1] + m[2][2];
  if (trace > 0.0) {
    var s = sqrt(trace + 1.0);
    q.w = 0.5 * s;
    s = 0.5 / s;
    q.x = (m[1][2] - m[2][1]) * s;
    q.y = (m[2][0] - m[0][2]) * s;
    q.z = (m[0][1] - m[1][0]) * s;
  } else {
    var a = 0;
    if (m[1][1] > m[0][0]) { a = 1; }
    if (m[2][2] > m[a][a]) { a = 2; }
    let j = (a + 1) % 3;
    let k = (j + 1) % 3;
    var s = sqrt((m[a][a] - (m[j][j] + m[k][k])) + 1.0);
    q[a] = 0.5 * s;
    if (s != 0.0) { s = 0.5 / s; }
    q.w = (m[j][k] - m[k][j]) * s;
    q[j] = (m[a][j] + m[j][a]) * s;
    q[k] = (m[a][k] + m[k][a]) * s;
  }
  q = normalize(q);
  if (q.w < 0.0) { q = -q; }
  let bias = 1.0 / 32767.0;
  if (q.w < bias) { q = vec4f(q.xyz * sqrt(1.0 - bias * bias), bias); }
  if (dot(cross(t, n), b) < 0.0) { q = -q; }
  frames[4u * i] = q.x; frames[4u * i + 1u] = q.y; frames[4u * i + 2u] = q.z; frames[4u * i + 3u] = q.w;
}
