// Kinetic Array Motion: array choreography for group children, copies, or split letters.
// --track@spread:Spread,-1.5,1.5,0.22,0.01
// --track@wave:Wave,0,1,0.14,0.01
// --track@spin:Spin,-45,45,6,0.5
// --track@tempo:Tempo,0,2,0.45,0.01
// --track@phase:Phase,0,1,0.22,0.01
// --track@fade:Edge Fade,0,0.9,0.15,0.01

function each(i, n, t, k) {
  const count = Math.max(1, n);
  const center = (count - 1) * 0.5;
  const rel = i - center;
  const norm = count > 1 ? rel / center : 0;
  const ang = t * Math.PI * 2 * k.tempo - i * k.phase * Math.PI * 2;
  const s = Math.sin(ang);
  const c = Math.cos(ang);
  return {
    x: rel * k.spread,
    y: s * k.wave,
    rotate: c * k.spin,
    size: Math.max(0.1, 1 + 0.05 * s),
    opacity: Math.max(0.05, 1 - Math.abs(norm) * k.fade),
  };
}
