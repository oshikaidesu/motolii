#ifndef MOTOLII_COMMUNITY_CSS_TEXT_H_
#define MOTOLII_COMMUNITY_CSS_TEXT_H_

// A text layer's letters set as a web page sets them (text.rs, in Rust): Blitz
// reads the CSS, Parley/HarfRust lay the letters out (horizontal & vertical
// OpenType typesetting, Japanese kinsoku, hanging punctuation,
// metrics/features) and skrifa extracts the outlines and font metadata.

#include <stdint.h>

extern "C" {

struct MotoliiText;

// Sets `words`.
// `styles` holds one range per line: "start count declarations".
// `fonts` lists font files, one per line (layer font first, fallbacks after).
// `size`: font size in px; `line`: CSS line-height multiplier;
// `tracking`: thousandths of an em; `slant`: oblique degrees;
// `wrap`: line/column measure in px (0 = unwrapped);
// `breakAll`: break between any characters;
// `align`: 0 start, 0.5 center, 1 end;
// `vertical`: non-zero for vertical-rl OpenType typesetting (vert/vrt2/vmtx);
// `kinsoku`: "normal", "strict", "loose", or "none" (CSS line-break);
// `hanging`: non-zero to hang trailing punctuation (、。，．) past the end;
// `features`: OpenType feature tags (e.g. "\"palt\" 1, \"kern\" 1" or "palt
// tnum").
MotoliiText* motolii_text_new(const char* words, const char* styles,
                              const char* fonts, float size, float line,
                              float tracking, float slant, float wrap,
                              int32_t breakAll, float align, int32_t vertical,
                              const char* kinsoku, int32_t hanging,
                              const char* features);

// Reads variable-font axes (fvar) and OpenType feature tags + UI names
// (GSUB/GPOS) from `fontFile` via skrifa. Writes a UTF-8 text report into `out`
// (up to `cap` bytes including NUL) and returns its byte length (excluding
// NUL).
int32_t motolii_font_meta_read(const char* fontFile, char* out, int32_t cap);

// Detects Unicode character classes present in `words` via ICU4X
// (`icu_properties`), writing one tab-separated line per class
// (`id\tlabel\tname`) into `out`.
int32_t motolii_text_classes_read(const char* words, char* out, int32_t cap);

// The outlines of all the letters, in pixels, y down, the first line's top at
// 0: `verbs` are 0 move (1 point), 1 line (1), 2 cubic (3), 3 close (0).
void motolii_text_path(const MotoliiText* text, const uint8_t** verbs,
                       int32_t* verbCount, const float** points,
                       int32_t* pointCount);
// How many lines (or vertical columns). With `out`, 5 numbers each: baseline,
// ascent, descent, start x, advance width.
int32_t motolii_text_lines(const MotoliiText* text, float* out);
// How many characters. With `out`, 5 numbers each: x, advance, ink start,
// ink end, line index.
int32_t motolii_text_letters(const MotoliiText* text, float* out);
// How many coloured pieces. With `out`, 8 numbers each: x y w h r g b a.
int32_t motolii_text_colors(const MotoliiText* text, float* out);
// The layer's font's ascent above the baseline and descent below it, at `size`.
void motolii_text_font(const MotoliiText* text, float* ascent, float* descent);
void motolii_text_free(MotoliiText* text);

}  // extern "C"

#endif  // MOTOLII_COMMUNITY_CSS_TEXT_H_
