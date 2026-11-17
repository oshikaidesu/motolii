// Chrome's own letters, for the check of engine/community/css: per [data-splitting] element and time, each .char's box
// with every transform taken away (the box Motolii gives), then its box as Chrome draws it, and its opacity times its
// ancestors'. Saved by POST to chrome/<page>.json (the scratch server). Animations paused at the time, as compare.js.
(async () => {
  const name = location.pathname.split('/').pop().replace('.html', '.json');
  const roots = [...document.querySelectorAll('[data-splitting]')];
  const off = document.createElement('style');
  off.textContent = '*{transform:none!important;translate:none!important;rotate:none!important;scale:none!important}';
  const box = e => { const b = e.getBoundingClientRect(); return [b.x + scrollX, b.y + scrollY, b.width, b.height]; };
  const seen = e => { let o = 1; for (let n = e; n; n = n.parentElement) o *= +getComputedStyle(n).opacity; return o; };
  const out = {};
  for (const t of [0.3, 0.9, 1.7]) {
    for (const a of document.getAnimations()) { a.pause(); a.currentTime = t * 1000; }
    document.head.append(off);
    const base = roots.map(r => [...r.querySelectorAll('.char')].map(box));
    off.remove();
    out[t] = roots.map((r, k) => [...r.querySelectorAll('.char')].map((e, j) => [...base[k][j], ...box(e), seen(e)]));
  }
  const r = await fetch('/' + name, { method: 'POST', body: JSON.stringify(out) });
  return name + ' ' + await r.text();
})()
