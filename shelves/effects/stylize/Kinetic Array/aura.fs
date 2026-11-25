/*{
  "DESCRIPTION": "Soft aura halo and subtle bloom lift for Kinetic Array Vism pack.",
  "CREDIT": "Motolii",
  "CATEGORIES": ["Stylize"],
  "ISFVSN": "2",
  "INPUTS": [
    { "NAME": "inputImage", "TYPE": "image" },
    { "NAME": "glow", "LABEL": "Glow", "TYPE": "float", "DEFAULT": 0.35, "MIN": 0.0, "MAX": 1.2 },
    { "NAME": "halo", "LABEL": "Halo Radius", "TYPE": "float", "DEFAULT": 0.012, "MIN": 0.0, "MAX": 0.04 },
    { "NAME": "tint", "LABEL": "Aura Tint", "TYPE": "color", "DEFAULT": [0.31, 0.80, 0.77, 1.0] }
  ]
}*/

void main() {
  vec2 uv = isf_FragNormCoord;
  vec4 src = IMG_NORM_PIXEL(inputImage, uv);
  if (glow <= 0.001) {
    gl_FragColor = src;
    return;
  }
  vec2 r = vec2(halo * (RENDERSIZE.y / max(1.0, RENDERSIZE.x)), halo);
  vec4 blur = vec4(0.0);
  blur += IMG_NORM_PIXEL(inputImage, uv + vec2( r.x,  0.0));
  blur += IMG_NORM_PIXEL(inputImage, uv + vec2(-r.x,  0.0));
  blur += IMG_NORM_PIXEL(inputImage, uv + vec2( 0.0,  r.y));
  blur += IMG_NORM_PIXEL(inputImage, uv + vec2( 0.0, -r.y));
  blur += IMG_NORM_PIXEL(inputImage, uv + vec2( r.x,  r.y) * 0.7);
  blur += IMG_NORM_PIXEL(inputImage, uv + vec2(-r.x,  r.y) * 0.7);
  blur += IMG_NORM_PIXEL(inputImage, uv + vec2( r.x, -r.y) * 0.7);
  blur += IMG_NORM_PIXEL(inputImage, uv + vec2(-r.x, -r.y) * 0.7);
  blur *= 0.125;

  vec3 auraRgb = mix(blur.rgb, tint.rgb * max(blur.a, 0.25), 0.55) * glow;
  float outA = clamp(src.a + blur.a * glow * 0.65, 0.0, 1.0);
  vec3 outRgb = src.rgb + auraRgb * (1.0 - src.a * 0.45);
  gl_FragColor = vec4(outRgb, outA);
}
