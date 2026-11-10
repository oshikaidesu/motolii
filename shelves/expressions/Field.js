// Field: a round place over the copies, like Cavalry's Falloff. Where it reaches (Size from its middle At X, At Y, At Z), a
// copy grows by Grow, turns by Turn and is pushed away by Push, most at the middle and not at all at the edge (a smoothstep).
// With Ring above 0 it is a ring that wide, strongest at Size from the middle and nothing Ring either side. Push below 0 draws
// the copies in; above 0 puts them out as if round a hole of that radius. Put it after the expression that lays the copies:
// the distance is from where each copy lies so far, in the layer's own units.
// --track@field_x:At X,-3,3,0,0.01
// --track@field_y:At Y,-2,2,0,0.01
// --track@field_z:At Z,-2,2,0,0.01
// --track@field_radius:Size,0,4,0,0.01
// --track@field_band:Ring,0,2,0,0.01
// --track@field_size:Grow,-1,5,0,0.01
// --track@field_rotate:Turn,-180,180,0,1
// --track@field_push:Push,-2,2,0,0.01
function each(i, n, t, k, at) {
  if (k.field_radius <= 0) return {};
  const dx = at.x - k.field_x, dy = at.y - k.field_y, dz = at.z - k.field_z, r = Math.hypot(dx, dy, dz);
  const near = Math.min(1, Math.max(0, k.field_band > 0 ? 1 - Math.abs(r - k.field_radius) / k.field_band : 1 - r / k.field_radius));
  const s = near * near * (3 - 2 * near);
  // How far it moves along the line from the middle.
  const out = s * (k.field_push > 0 ? Math.sqrt(r * r + k.field_push * k.field_push) - r : k.field_push);
  const along = r > 1e-9 ? out / r : 0;
  return { x: dx * along, y: dy * along, z: dz * along, rotate: s * k.field_rotate, size: Math.max(0, 1 + s * k.field_size) };
}
