/*{
  "DESCRIPTION": "Bandwidth-efficient 8-pass Dual Kawase Blur (SIGGRAPH 2015, Marius Bjørge / ARM). Smooth wide blur at a fraction of Gaussian cost.",
  "CREDIT": "Marius Bjørge / ARM (SIGGRAPH 2015 Dual Kawase algorithm)",
  "CATEGORIES": ["Blur"],
  "ISFVSN": "2",
  "PAD": "radius*1.5+8:192",
  "BYPASS": "radius",
  "INPUTS": [
    { "NAME": "inputImage", "TYPE": "image" },
    { "NAME": "radius", "LABEL": "Radius", "TYPE": "float", "MIN": 0.0, "MAX": 128.0, "DEFAULT": 16.0 }
  ],
  "PASSES": [
    { "TARGET": "down1", "WIDTH": "max(1.0, floor($WIDTH / 2.0))",  "HEIGHT": "max(1.0, floor($HEIGHT / 2.0))" },
    { "TARGET": "down2", "WIDTH": "max(1.0, floor($WIDTH / 4.0))",  "HEIGHT": "max(1.0, floor($HEIGHT / 4.0))" },
    { "TARGET": "down3", "WIDTH": "max(1.0, floor($WIDTH / 8.0))",  "HEIGHT": "max(1.0, floor($HEIGHT / 8.0))" },
    { "TARGET": "down4", "WIDTH": "max(1.0, floor($WIDTH / 16.0))", "HEIGHT": "max(1.0, floor($HEIGHT / 16.0))" },
    { "TARGET": "up3",   "WIDTH": "max(1.0, floor($WIDTH / 8.0))",  "HEIGHT": "max(1.0, floor($HEIGHT / 8.0))" },
    { "TARGET": "up2",   "WIDTH": "max(1.0, floor($WIDTH / 4.0))",  "HEIGHT": "max(1.0, floor($HEIGHT / 4.0))" },
    { "TARGET": "up1",   "WIDTH": "max(1.0, floor($WIDTH / 2.0))",  "HEIGHT": "max(1.0, floor($HEIGHT / 2.0))" },
    {}
  ]
}*/

vec4 readPrev(vec2 uv) {
  if (PASSINDEX == 0) return IMG_NORM_PIXEL(inputImage, uv);
  if (PASSINDEX == 1) return IMG_NORM_PIXEL(down1, uv);
  if (PASSINDEX == 2) return IMG_NORM_PIXEL(down2, uv);
  if (PASSINDEX == 3) return IMG_NORM_PIXEL(down3, uv);
  if (PASSINDEX == 4) return IMG_NORM_PIXEL(down4, uv);
  if (PASSINDEX == 5) return IMG_NORM_PIXEL(up3, uv);
  if (PASSINDEX == 6) return IMG_NORM_PIXEL(up2, uv);
  return IMG_NORM_PIXEL(up1, uv);
}

vec4 kawaseDown(vec2 uv, vec2 halfpixel, float offset) {
  vec4 sum = readPrev(uv) * 4.0;
  sum += readPrev(uv - halfpixel * offset);
  sum += readPrev(uv + halfpixel * offset);
  sum += readPrev(uv + vec2(halfpixel.x, -halfpixel.y) * offset);
  sum += readPrev(uv - vec2(halfpixel.x, -halfpixel.y) * offset);
  return sum * 0.125;
}

vec4 kawaseUp(vec2 uv, vec2 halfpixel, float offset) {
  vec4 sum = readPrev(uv + vec2(-halfpixel.x * 2.0, 0.0) * offset);
  sum += readPrev(uv + vec2(-halfpixel.x, halfpixel.y) * offset) * 2.0;
  sum += readPrev(uv + vec2(0.0, halfpixel.y * 2.0) * offset);
  sum += readPrev(uv + vec2(halfpixel.x, halfpixel.y) * offset) * 2.0;
  sum += readPrev(uv + vec2(halfpixel.x * 2.0, 0.0) * offset);
  sum += readPrev(uv + vec2(halfpixel.x, -halfpixel.y) * offset) * 2.0;
  sum += readPrev(uv + vec2(0.0, -halfpixel.y * 2.0) * offset);
  sum += readPrev(uv + vec2(-halfpixel.x, -halfpixel.y) * offset) * 2.0;
  return sum / 12.0;
}

void main() {
  vec2 uv = isf_FragNormCoord;
  if (radius <= 0.001) {
    gl_FragColor = IMG_NORM_PIXEL(inputImage, uv);
    return;
  }
  vec2 hp = 0.5 / max(RENDERSIZE, vec2(1.0));
  float spread = clamp(radius / 16.0, 0.0, 8.0);
  float off = 0.5 + spread * 0.35;

  if (PASSINDEX == 0) {
    gl_FragColor = kawaseDown(uv, hp, min(radius * 0.5, off));
  } else if (PASSINDEX == 1) {
    float k = clamp((radius - 2.0) / 6.0, 0.0, 1.0);
    gl_FragColor = mix(IMG_NORM_PIXEL(down1, uv), kawaseDown(uv, hp, off), k);
  } else if (PASSINDEX == 2) {
    float k = clamp((radius - 8.0) / 12.0, 0.0, 1.0);
    gl_FragColor = mix(IMG_NORM_PIXEL(down2, uv), kawaseDown(uv, hp, off), k);
  } else if (PASSINDEX == 3) {
    float k = clamp((radius - 20.0) / 24.0, 0.0, 1.0);
    gl_FragColor = mix(IMG_NORM_PIXEL(down3, uv), kawaseDown(uv, hp, off), k);
  } else if (PASSINDEX == 4) {
    float k = clamp((radius - 20.0) / 24.0, 0.0, 1.0);
    gl_FragColor = mix(IMG_NORM_PIXEL(down3, uv), kawaseUp(uv, hp, off), k);
  } else if (PASSINDEX == 5) {
    float k = clamp((radius - 8.0) / 12.0, 0.0, 1.0);
    gl_FragColor = mix(IMG_NORM_PIXEL(down2, uv), kawaseUp(uv, hp, off), k);
  } else if (PASSINDEX == 6) {
    float k = clamp((radius - 2.0) / 6.0, 0.0, 1.0);
    gl_FragColor = mix(IMG_NORM_PIXEL(down1, uv), kawaseUp(uv, hp, off), k);
  } else {
    float k = clamp(radius / 2.0, 0.0, 1.0);
    gl_FragColor = mix(IMG_NORM_PIXEL(inputImage, uv), kawaseUp(uv, hp, min(radius * 0.5, off)), k);
  }
}
