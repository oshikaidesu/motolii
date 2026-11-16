// Minimal stand-in for the three module imports a shader module uses. Just
// enough of Vector2/3/4, Color and Matrix3/4 for a shader module to build its
// uniform values. Vectors keep their components and Color turns a hex number
// into r, g, b in 0-1.
export class Vector2 { constructor(x = 0, y = 0) { this.x = x; this.y = y; } }
export class Vector3 { constructor(x = 0, y = 0, z = 0) { this.x = x; this.y = y; this.z = z; } }
export class Vector4 { constructor(x = 0, y = 0, z = 0, w = 1) { this.x = x; this.y = y; this.z = z; this.w = w; } }
export class Color { constructor(r = 1, g, b) { if (g === undefined) { const h = typeof r === 'number' ? r : 0xffffff; this.r = ((h >> 16) & 255) / 255; this.g = ((h >> 8) & 255) / 255; this.b = (h & 255) / 255; } else { this.r = r; this.g = g; this.b = b; } } }
export class Matrix3 {} export class Matrix4 {}
