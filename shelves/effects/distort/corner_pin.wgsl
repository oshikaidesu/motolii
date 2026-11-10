// Corner Pin: pulls the four corners of the layer to places of your own, and the picture follows in true perspective, as After Effects' Distort > Corner Pin does. Written for Motolii after Paul Heckbert, "Fundamentals of Texture Mapping and Image Warping" (1989), section 2.2.1, the unit square to a quadrilateral (the same as Foundry Nuke's CornerPin2D); the picture is looked up by the inverse of that map. Positions are shares of the layer: 0,0 is its top left, 1,1 its bottom right, and a corner may go outside.
// --label:Distort
// --tag:basic
// --about:Moves the four corners of the layer anywhere, with perspective. The corners start at the layer's own.
// --group:Top left
// --track@tl_x:x,-2,3,0,0.001
// --track@tl_y:y,-2,3,0,0.001
// --group
// --group:Top right
// --track@tr_x:x,-2,3,1,0.001
// --track@tr_y:y,-2,3,0,0.001
// --group
// --group:Bottom right
// --track@br_x:x,-2,3,1,0.001
// --track@br_y:y,-2,3,1,0.001
// --group
// --group:Bottom left
// --track@bl_x:x,-2,3,0,0.001
// --track@bl_y:y,-2,3,1,0.001
// --group

struct Knobs {
  tl_x: f32,
  tl_y: f32,
  tr_x: f32,
  tr_y: f32,
  br_x: f32,
  br_y: f32,
  bl_x: f32,
  bl_y: f32,
}

@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var pictureSampler: sampler;
@group(0) @binding(2) var<uniform> k: Knobs;

// Heckbert's square to quadrilateral: columns are what the unit square's u, v and
// 1 become, in homogeneous coordinates (x, y, w).
fn square_to_quad(p0: vec2f, p1: vec2f, p2: vec2f, p3: vec2f) -> mat3x3f {
  let s = p0 - p1 + p2 - p3;
  var g = 0.0;
  var h = 0.0;
  if (abs(s.x) > 1e-7 || abs(s.y) > 1e-7) {
    let d1 = p1 - p2;
    let d2 = p3 - p2;
    let det = d1.x * d2.y - d2.x * d1.y;
    g = (s.x * d2.y - d2.x * s.y) / det;
    h = (d1.x * s.y - s.x * d1.y) / det;
  }
  return mat3x3f(
    vec3f(p1.x - p0.x + g * p1.x, p1.y - p0.y + g * p1.y, g),
    vec3f(p3.x - p0.x + h * p3.x, p3.y - p0.y + h * p3.y, h),
    vec3f(p0.x, p0.y, 1.0));
}

// The adjugate of a 3x3 matrix: its inverse times its determinant. A homography
// is the same under any scale, so that is all the inverse that is needed.
fn adjugate(m: mat3x3f) -> mat3x3f {
  return mat3x3f(
    cross(m[1], m[2]),
    cross(m[2], m[0]),
    cross(m[0], m[1]));
}

@fragment
fn fs_main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
  let m = square_to_quad(vec2f(k.tl_x, k.tl_y), vec2f(k.tr_x, k.tr_y),
                         vec2f(k.br_x, k.br_y), vec2f(k.bl_x, k.bl_y));
  // The rows of the adjugate of m, as the columns of the transpose.
  let q = transpose(adjugate(m)) * vec3f(uv, 1.0);
  let at = q.xy / q.z;
  let inside = q.z != 0.0 && all(at >= vec2f(0.0)) && all(at <= vec2f(1.0));
  let c = textureSampleLevel(picture, pictureSampler, clamp(at, vec2f(0.0), vec2f(1.0)), 0.0);
  return select(vec4f(0.0), c, inside);
}
