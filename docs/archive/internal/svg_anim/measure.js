// Chrome side of the svg-spinners check: every SVG element's computed values at the times the probe reads, animations
// paused there. Saved by POST to chrome/blitz-free name (the scratch server).
(async () => {
  const props = ['opacity', 'r', 'cx', 'cy', 'x', 'y', 'width', 'height', 'rx', 'ry', 'stroke-dasharray', 'stroke-dashoffset', 'transform'];
  const all = [...document.querySelectorAll('svg *:not(style)')];
  const out = {};
  for (const t of [0.3, 0.9, 1.7]) {
    for (const a of document.getAnimations()) { a.pause(); a.currentTime = t * 1000; }
    out[t] = all.map(e => { const s = getComputedStyle(e); return Object.fromEntries(props.map(p => [p, s.getPropertyValue(p)])); });
  }
  const r = await fetch('/chrome/spinners.json', { method: 'POST', body: JSON.stringify(out) });
  return await r.text();
})()
