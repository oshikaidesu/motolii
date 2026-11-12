#ifndef MOTOLII_COMMUNITY_CSS_TEXT_H_
#define MOTOLII_COMMUNITY_CSS_TEXT_H_

// A text layer's letters set as a web page sets them (text.rs, in Rust): Blitz
// reads the CSS, Parley lays the letters out and skrifa gives their outlines,
// as Blitz paints a page's text. Ranges of the characters may carry their own
// CSS declarations, so a few letters can be larger, coloured, shifted or set at
// other variable-font axes than the rest.

#include <stdint.h>

extern "C" {

struct MotoliiText;

// Sets `words`.
// `styles` holds one range a line: "start count declarations", the characters
// from `start` (counted from 0 in Unicode characters, as After Effects'
// sourceText style.setFontSize(value, startIndex, numOfCharacters) counts),
// `count` of them, and CSS declarations for them, for example
// "4 2 font-size: 150%; color: #ff8a3d; font-variation-settings: 'wght' 700".
// A later line wins where ranges overlap, as a later CSS rule does. May be null.
// `fonts` lists font files, one a line: the layer's font first, then fonts to
// fall back on for characters it lacks.
// `size` is the font size in pixels, `line` the line height as CSS's
// line-height <number> gives it (times the font size), `tracking` After
// Effects' Tracking (thousandths of an em, CSS letter-spacing) and `slant` the
// angle of CSS's font-style: oblique, in degrees: a font's own slnt axis or
// oblique face where it has one, else its letters leaned. `wrap` is the width
// in pixels the lines break at (0: as typed); `breakAll` breaks between any
// letters. `align` sets each line in the widest one: 0 left, .5 centre, 1
// right. Returns null if no font could be read.
MotoliiText* motolii_text_new(const char* words, const char* styles,
                              const char* fonts, float size, float line,
                              float tracking, float slant, float wrap,
                              int32_t breakAll, float align);
// The outlines of all the letters, in pixels, y down, the first line's top at
// 0: `verbs` are 0 move (1 point), 1 line (1), 2 cubic (3), 3 close (0).
void motolii_text_path(const MotoliiText* text, const uint8_t** verbs,
                       int32_t* verbCount, const float** points,
                       int32_t* pointCount);
// How many lines. With `out`, 5 numbers each: the baseline, the ascent above
// it and the descent below it of the line's largest letters, where the line
// starts across and how wide it is.
int32_t motolii_text_lines(const MotoliiText* text, float* out);
// How many characters. With `out`, 5 numbers each: where the character is set
// across, its advance, where its ink starts and ends across (both 0 for a
// character that draws nothing), and its line.
int32_t motolii_text_letters(const MotoliiText* text, float* out);
// How many coloured pieces. With `out`, 8 numbers each: x y w h of a piece of
// a line, and its color, r g b a from 0 to 1. Only the letters whose range sets
// a color are listed; the rest take the layer's fill.
int32_t motolii_text_colors(const MotoliiText* text, float* out);
// The layer's font's ascent above the baseline and descent below it, at the
// size, in pixels: one line's height, whatever size the ranges set.
void motolii_text_font(const MotoliiText* text, float* ascent, float* descent);
void motolii_text_free(MotoliiText* text);

}  // extern "C"

#endif  // MOTOLII_COMMUNITY_CSS_TEXT_H_
