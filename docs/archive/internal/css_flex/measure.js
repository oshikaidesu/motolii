// Chrome's own layout of the letters: per [data-splitting] element its text, its font-size, the advance of a space in
// its font, and for each .char the size and the box on the page of its letter. Written into the page as JSON (id "out").
const out = [...document.querySelectorAll('[data-splitting]')].map(root => {
  const s = document.createElement('span');
  s.style.cssText = 'position:absolute;white-space:pre;visibility:hidden';
  s.textContent = ' ';
  (root.querySelector('.word') || root).append(s);
  const space = s.getBoundingClientRect().width; s.remove();
  // A letter's box is its text's own: where Chrome sets the glyph, as wide as its advance and as tall as the font's
  // content area. Its element may be larger (a grid item stretched across its column) with the letter at its start.
  const chars = [...root.querySelectorAll('.char')].map(e => {
    const r = document.createRange(); r.selectNodeContents(e);
    const b = r.getBoundingClientRect();
    return [b.width, b.height, b.x + scrollX, b.y + scrollY, b.width, b.height];
  });
  return { text: root.dataset.text, font: parseFloat(getComputedStyle(root).fontSize), space, chars, view: [innerWidth, innerHeight] };
});
const pre = document.createElement('pre'); pre.id = 'out'; pre.textContent = JSON.stringify(out); document.body.append(pre);
