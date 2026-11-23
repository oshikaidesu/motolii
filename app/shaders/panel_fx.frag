// Bundled multi-mode GLSL fragment shader for Flutter-native `ui.shader` custom card visualizers.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uMode;   // 0=holo, 1=metaball, 2=vhs, 3=scope, 4=aurora, 5=grid
uniform float uParamA; // primary morph / intensity (0..1)
uniform float uParamB; // secondary frequency / warp (0..1)
uniform vec2 uMouse;   // normalized pointer (0..1)
uniform vec3 uColA;
uniform vec3 uColB;
uniform vec3 uColC;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec3 holoShader(vec2 uv) {
  vec2 p = uv - uMouse;
  float wave = sin((uv.x * 5.0 + uv.y * 3.5) * (1.0 + uParamB * 1.5) + uTime * 1.8);
  float shimmer = sin(length(p) * 14.0 - uTime * 2.4 + wave * 2.2);
  float band = 0.5 + 0.5 * shimmer;
  vec3 c1 = mix(uColA, uColB, band);
  vec3 c2 = mix(c1, uColC, 0.5 + 0.5 * sin(uv.x * 7.0 - uv.y * 5.0 + uTime));
  float spec = pow(max(0.0, 1.0 - length(p) * 1.8), 3.0) * (0.4 + 0.6 * uParamA);
  float grain = (hash(floor(uv * 240.0)) - 0.5) * 0.04;
  return clamp(c2 + vec3(spec) + vec3(grain), 0.0, 1.0);
}

vec3 metaballShader(vec2 uv) {
  vec2 aspect = vec2(uSize.x / max(1.0, uSize.y), 1.0);
  vec2 p = (uv - 0.5) * aspect;
  float field = 0.0;
  for (int i = 0; i < 5; i++) {
    float fi = float(i);
    float a = uTime * (0.7 + fi * 0.22) + fi * 1.3;
    vec2 center = vec2(cos(a) * 0.42, sin(a * 1.25) * 0.28);
    if (i == 0) center = (uMouse - 0.5) * aspect * 0.9;
    float r = 0.075 + 0.045 * uParamA;
    field += (r * r) / max(0.002, dot(p - center, p - center));
  }
  vec3 bg = mix(uColC * 0.14, uColB * 0.20, uv.y);
  float blob = smoothstep(0.95, 1.18, field);
  float core = smoothstep(1.35, 2.3, field);
  float rim = smoothstep(0.85, 1.05, field) - smoothstep(1.05, 1.35, field);
  vec3 col = mix(uColA, uColB, clamp(uv.x + 0.2 * sin(uTime), 0.0, 1.0));
  vec3 outC = mix(bg, col, blob);
  outC += uColC * core * 0.55 + vec3(1.0) * rim * 0.45;
  return clamp(outC, 0.0, 1.0);
}

vec3 vhsShader(vec2 uv) {
  float scan = 0.86 + 0.14 * sin(uv.y * uSize.y * 1.8);
  float band = smoothstep(0.96, 1.0, sin(uv.y * 6.0 - uTime * 2.5));
  float jitter = (hash(vec2(floor(uv.y * 60.0), floor(uTime * 12.0))) - 0.5) * 0.04 * (0.3 + uParamA);
  vec2 u = uv + vec2(jitter + band * 0.03 * uParamA, 0.0);
  float sep = 0.008 + 0.02 * uParamB;
  float r = smoothstep(0.08, 0.0, abs(u.y - (0.5 + 0.22 * sin((u.x + sep) * 14.0 + uTime * 3.0))));
  float g = smoothstep(0.08, 0.0, abs(u.y - (0.5 + 0.22 * sin(u.x * 14.0 + uTime * 3.0))));
  float b = smoothstep(0.08, 0.0, abs(u.y - (0.5 + 0.22 * sin((u.x - sep) * 14.0 + uTime * 3.0))));
  vec3 base = mix(uColC * 0.10, uColB * 0.22, uv.y);
  vec3 wave = vec3(r, g, b) * mix(uColA, vec3(1.0), 0.45);
  float snow = hash(uv * 320.0 + uTime) * 0.12 * uParamA;
  return clamp((base + wave + vec3(snow) + vec3(band * 0.18)) * scan, 0.0, 1.0);
}

vec3 scopeShader(vec2 uv) {
  vec2 p = uv * 2.0 - 1.0;
  float freq = 3.0 + uParamB * 9.0;
  float y1 = 0.52 * uParamA * sin(p.x * freq + uTime * 3.2) * cos(p.x * 1.4 - uTime);
  float y2 = 0.36 * uParamA * sin(p.x * (freq * 1.5) - uTime * 2.4);
  float d1 = abs(p.y - y1);
  float d2 = abs(p.y - y2);
  float glow1 = exp(-d1 * 28.0) + 0.25 * exp(-d1 * 7.0);
  float glow2 = exp(-d2 * 30.0) + 0.20 * exp(-d2 * 8.0);
  float gridX = smoothstep(0.96, 1.0, abs(sin(uv.x * 3.14159 * 8.0)));
  float gridY = smoothstep(0.96, 1.0, abs(sin(uv.y * 3.14159 * 4.0)));
  vec3 bg = uColC * 0.08 + vec3(0.05, 0.08, 0.07) * (gridX + gridY);
  return clamp(bg + uColA * glow1 + uColB * glow2, 0.0, 1.0);
}

vec3 auroraShader(vec2 uv) {
  float w1 = sin(uv.x * 4.2 + uTime * 0.9 + sin(uv.y * 3.0 + uTime * 0.5) * 1.4);
  float w2 = cos(uv.x * 6.5 - uTime * 1.1 + uv.y * 4.0 * (0.5 + uParamB));
  float ribbon = exp(-abs(uv.y - (0.52 + 0.22 * w1 * (0.4 + uParamA))) * 5.2);
  float ribbon2 = exp(-abs(uv.y - (0.46 + 0.18 * w2)) * 6.5);
  vec3 sky = mix(uColC * 0.12, uColC * 0.26, 1.0 - uv.y);
  return clamp(sky + uColA * ribbon * 0.95 + uColB * ribbon2 * 0.85, 0.0, 1.0);
}

vec3 gridShader(vec2 uv) {
  float horizon = 0.42;
  if (uv.y < horizon) {
    float t = uv.y / horizon;
    vec3 sky = mix(uColC * 0.14, uColB * 0.55, pow(t, 1.8));
    vec2 sunP = vec2((uv.x - 0.5) * (uSize.x / max(1.0, uSize.y)), uv.y - horizon + 0.06);
    float sun = smoothstep(0.24, 0.22, length(sunP));
    float stripe = step(0.3, fract(uv.y * 28.0));
    vec3 sunCol = mix(uColA, uColB, clamp(uv.y * 2.5, 0.0, 1.0));
    return clamp(sky + sunCol * sun * mix(1.0, stripe, smoothstep(0.22, 0.42, uv.y)), 0.0, 1.0);
  }
  float z = 1.0 / max(0.04, uv.y - horizon);
  float gx = abs(fract((uv.x - 0.5) * z * 1.4 + (uMouse.x - 0.5) * 2.0) - 0.5);
  float gz = abs(fract(z * 0.45 - uTime * (0.8 + uParamA * 1.5)) - 0.5);
  float line = smoothstep(0.07, 0.0, min(gx, gz));
  float fade = exp(-(uv.y - horizon) * 1.2);
  vec3 floorBg = uColC * 0.09;
  return clamp(floorBg + uColA * line * (0.4 + 0.8 * fade) + uColB * exp(-(uv.y - horizon) * 14.0) * 0.6, 0.0, 1.0);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / max(vec2(1.0), uSize);
  vec3 col;
  if (uMode < 0.5) {
    col = holoShader(uv);
  } else if (uMode < 1.5) {
    col = metaballShader(uv);
  } else if (uMode < 2.5) {
    col = vhsShader(uv);
  } else if (uMode < 3.5) {
    col = scopeShader(uv);
  } else if (uMode < 4.5) {
    col = auroraShader(uv);
  } else {
    col = gridShader(uv);
  }
  fragColor = vec4(col, 1.0);
}
