#ifndef MOTOLII_COMMUNITY_CSS_CSS_H_
#define MOTOLII_COMMUNITY_CSS_CSS_H_

// CSS animations, as posted on CodePen, moving the letters of a text layer
// (css.rs, in Rust: Blitz and Stylo run the page). The page is the pen's CSS
// and HTML, and the layer's words stand in its [data-splitting] element, cut
// into the markup Splitting.js makes. Motolii lays out the letters and gives
// their boxes; the page says how its CSS moves each one.

#include <stdint.h>

extern "C" {

struct MotoliiCss;

// Opens a page. `css` and `html` are as posted (either may be null).
// `words` is the layer's text, `nth` which [data-splitting] element of the
// HTML it is, from 0. `by_words` is nonzero when the layer is split into
// words, not letters. The page is width x height pixels, the project's size.
// Returns null if the page cannot be opened.
MotoliiCss* motolii_css_new(const char* css, const char* html,
                            const char* words, int32_t nth, int32_t by_words,
                            uint32_t width, uint32_t height);
// How many letters (or words) the page moves: every character of the words,
// spaces too, as Motolii splits a text.
int32_t motolii_css_letters(const MotoliiCss* page);
// Plays the page to `t` seconds. `boxes` holds n boxes, x y w h in pixels on
// the page, y down, one per letter. For each letter, `out` receives 17
// numbers: its opacity, then a 4 x 4 matrix, column by column, that moves it
// about its own middle in the same pixels. Returns how many were written.
int32_t motolii_css_at(MotoliiCss* page, double t, const float* boxes,
                       int32_t n, double* out);
void motolii_css_free(MotoliiCss* page);

}  // extern "C"

#endif  // MOTOLII_COMMUNITY_CSS_CSS_H_
