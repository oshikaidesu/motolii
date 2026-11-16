// Minimal stand-ins for the parts of the 'playcanvas' module that a
// GSplatShaderEffect imports: just Vec3, Color and Script with the methods
// the base class uses. No rendering API, no event bus.
export class Vec3 { constructor(x = 0, y = 0, z = 0) { this.x = x; this.y = y; this.z = z; } set(x, y, z) { this.x = x; this.y = y; this.z = z; return this; } copy(v) { return this.set(v.x, v.y, v.z); } clone() { return new Vec3(this.x, this.y, this.z); } }
export class Color { constructor(r = 0, g = 0, b = 0, a = 1) { this.r = r; this.g = g; this.b = b; this.a = a; } set(r, g, b, a = 1) { this.r = r; this.g = g; this.b = b; this.a = a; return this; } copy(c) { return this.set(c.r, c.g, c.b, c.a); } clone() { return new Color(this.r, this.g, this.b, this.a); } }
export class Script { constructor() { this.enabled = true; } on() {} off() {} fire() {} }
