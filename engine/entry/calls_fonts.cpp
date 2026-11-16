// Font metadata calls: kinds the file reports (serif / sans / mono / bold /
// light / italic / symbols / ornaments), and the English names of the
// non-Latin scripts the font covers (japanese / korean / chinese / …). Used
// by the Fonts shelf for sorting and filtering.
//
// The one implementation here reads font tables through macOS's CoreText, the
// only font API linked into the engine right now. For Windows and Linux, swap
// in a reader that returns the same space-separated tags from the font's own
// 'name' (nameID 1, 2) and 'OS/2' (panose, usWidthClass) tables — HarfBuzz
// (hb_face_create / hb_ot_name_list_names) or FreeType (FT_Get_Sfnt_Name)
// both read those tables on every platform the engine would target. The
// shape of the output ("tag1 tag2 … script1 script2") is a cross-platform
// contract: a swap only re-writes the body of motolii_font_tags().

#include "entry/motolii.h"

#ifdef __APPLE__
#include <CoreText/CoreText.h>

#include <cctype>
#include <cstdint>
#include <cstring>
#include <string>

const char* motolii_font_tags(const char* path) {
  static thread_local std::string out;
  out.clear();
  CFURLRef url = CFURLCreateFromFileSystemRepresentation(
      nullptr, (const UInt8*)path, (CFIndex)std::strlen(path), false);
  CFArrayRef all =
      url ? CTFontManagerCreateFontDescriptorsFromURL(url) : nullptr;
  if (all && CFArrayGetCount(all) > 0) {
    CTFontDescriptorRef one =
        (CTFontDescriptorRef)CFArrayGetValueAtIndex(all, 0);
    CFDictionaryRef traits = (CFDictionaryRef)CTFontDescriptorCopyAttribute(
        one, kCTFontTraitsAttribute);
    if (traits) {
      SInt32 symbolic = 0;
      float weight = 0.f;
      if (CFNumberRef n =
              (CFNumberRef)CFDictionaryGetValue(traits, kCTFontSymbolicTrait))
        CFNumberGetValue(n, kCFNumberSInt32Type, &symbolic);
      if (CFNumberRef n =
              (CFNumberRef)CFDictionaryGetValue(traits, kCTFontWeightTrait))
        CFNumberGetValue(n, kCFNumberFloatType, &weight);
      // The family class sits in the top bits of the symbolic traits. Classes 1
      // to 7 are serif styles, 8 is sans serif, 9 is ornamental, 10 is script
      // and 12 is symbolic.
      const uint32_t kind =
          ((uint32_t)symbolic & kCTFontClassMaskTrait) >> kCTFontClassMaskShift;
      if (kind >= 1 && kind <= 7)
        out += "serif ";
      else if (kind == 8)
        out += "sans ";
      else if (kind == 9)
        out += "ornaments ";
      else if (kind == 10)
        out += "script ";
      else if (kind == 12)
        out += "symbols ";
      // Mono, bold, light and italic come from the symbolic traits and the
      // weight, which runs from -1 to 1. A weight above 0.3 also counts as bold
      // and one below -0.3 as light.
      if ((uint32_t)symbolic & kCTFontMonoSpaceTrait) out += "mono ";
      if ((uint32_t)symbolic & kCTFontBoldTrait || weight > 0.3f)
        out += "bold ";
      if (weight < -0.3f) out += "light ";
      if ((uint32_t)symbolic & kCTFontItalicTrait) out += "italic ";
      CFRelease(traits);
    }
    // Add the scripts beyond Latin that the font supports, from the languages
    // CoreText reports. Each is named in English as macOS names it.
    if (CFArrayRef langs = (CFArrayRef)CTFontDescriptorCopyAttribute(
            one, kCTFontLanguagesAttribute)) {
      CFLocaleRef english = CFLocaleCreate(nullptr, CFSTR("en"));
      for (const char* code :
           {"ja", "ko", "zh", "ru", "el", "ar", "he", "th", "hi"}) {
        CFStringRef c =
            CFStringCreateWithCString(nullptr, code, kCFStringEncodingUTF8);
        bool has = false;
        // Match the language itself or one of its variants such as "zh-Hans",
        // but not a different language whose code merely begins with the same
        // letters, such as "arn" for "ar".
        for (CFIndex i = 0; i < CFArrayGetCount(langs) && !has; ++i) {
          CFStringRef l = (CFStringRef)CFArrayGetValueAtIndex(langs, i);
          has = CFStringCompare(l, c, 0) == kCFCompareEqualTo ||
                (CFStringHasPrefix(l, c) &&
                 CFStringGetLength(l) > CFStringGetLength(c) &&
                 CFStringGetCharacterAtIndex(l, CFStringGetLength(c)) == '-');
        }
        if (has)
          if (CFStringRef name = CFLocaleCopyDisplayNameForPropertyValue(
                  english, kCFLocaleLanguageCode, c)) {
            char said[64] = "";
            CFStringGetCString(name, said, sizeof said, kCFStringEncodingUTF8);
            for (char* ch = said; *ch; ++ch)
              *ch = (char)std::tolower((unsigned char)*ch);
            out += std::string(said) + " ";
            CFRelease(name);
          }
        CFRelease(c);
      }
      CFRelease(english);
      CFRelease(langs);
    }
  }
  if (all) CFRelease(all);
  if (url) CFRelease(url);
  if (!out.empty()) out.pop_back();
  return out.c_str();
}

#else

// Windows and Linux: HarfBuzz (hb_face_create / hb_ot_name_list_names) or
// FreeType (FT_Get_Sfnt_Name) read the 'name' and 'OS/2' tables that the
// macOS branch above gets through CoreText. Both libraries are linked
// through Skia, so a Win/Linux build only needs to open the face and parse
// the same tags out of these tables. Until then the Fonts shelf treats every
// font as Latin only (no tags, no scripts), which falls back to the English
// sample line.
const char* motolii_font_tags(const char* path) {
  (void)path;
  return "";
}

#endif
