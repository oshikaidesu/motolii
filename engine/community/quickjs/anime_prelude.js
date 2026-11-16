// anime.js's easings (third_party/anime, MIT) run as they are: one QuickJS
// context for the whole library, the bundle read once from where the library
// keeps it, and each ease said made once and kept by what it says.
// irregular() draws its points with Math.random: while an ease is made,
// anime.js's own seeded one stands in, its seed from the words, so the same
// words give the same curve every time.
var __eases = {};
function __ease(said) {
  var built = __eases[said];
  if (built) return built;
  var seed = 0;
  for (var i = 0; i < said.length; i++) seed = (seed * 31 + said.charCodeAt(i)) | 0;
  var r = anime.utils.createSeededRandom(seed), ownRandom = Math.random;
  Math.random = function () { return r(0, 1, 6); };
  try { with (anime.eases) { with (anime) { built = eval('(' + said + ')'); } } } finally { Math.random = ownRandom; }   // (anime's own linear(), steps()... before eases.linear)
  if (built && typeof built.ease === 'function') built = built.ease;   // (a spring: its ease)
  if (typeof built !== 'function') throw new Error(said + ': not an ease of anime.js');
  return __eases[said] = built;
}
function __ease_at(said, u) { return __ease(said)(Math.min(1, Math.max(0, u))); }
