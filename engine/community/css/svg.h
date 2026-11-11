#ifndef MOTOLII_COMMUNITY_CSS_SVG_H_
#define MOTOLII_COMMUNITY_CSS_SVG_H_

// An SVG that moves by CSS @keyframes, as posted (svg.rs, in Rust: Blitz and
// Stylo play its CSS). ThorVG runs no CSS animation, so at each time the SVG
// is written again with what the CSS makes of each element in its
// attributes, and ThorVG draws that.

extern "C" {

struct MotoliiSvg;

// Opens an SVG's text. Returns null if it cannot be read as XML.
MotoliiSvg* motolii_svg_new(const char* svg);
// The SVG at `t` seconds, as SVG text; it lasts until the next call or free.
// Null if playing failed.
const char* motolii_svg_at(MotoliiSvg* svg, double t);
void motolii_svg_free(MotoliiSvg* svg);

}  // extern "C"

#endif  // MOTOLII_COMMUNITY_CSS_SVG_H_
