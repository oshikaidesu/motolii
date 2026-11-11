#ifndef MOTOLII_BASE_DEFAULT_FONT_H_
#define MOTOLII_BASE_DEFAULT_FONT_H_
// The font a text takes when none is named: one that every machine of the
// platform has. The app's own default for a new text
// (app/lib/workspace/state/drawing_inks.dart, defaultTextFont) is the same
// file.

namespace motolii {

inline const char* default_font() {
#ifdef _WIN32
  return "C:/Windows/Fonts/arial.ttf";
#else
  return "/System/Library/Fonts/Supplemental/Arial Unicode.ttf";
#endif
}

}  // namespace motolii

#endif  // MOTOLII_BASE_DEFAULT_FONT_H_
