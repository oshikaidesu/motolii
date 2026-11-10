// The names of ThorVG's own effects as a layer's list of effects says them, and
// the one-letter code of each.
#ifndef MOTOLII_STAGE_EFFECTS_THORVG_EFFECT_NAMES_H_
#define MOTOLII_STAGE_EFFECTS_THORVG_EFFECT_NAMES_H_
#include <string>
// ThorVG's own effects, named by the value that turns each on in a layer's list
// of effects. Their letters, in the same order, are in doc_thor_letter and
// DrawnFx::order. A glow is not one of them. It is Filament's bloom on the
// layer's own image, see doc_evaluate.
inline const char* const doc_thor_names[] = {"tint", "tritone", "shadow",
                                             "blur"};
// Returns the letter of the ThorVG effect named `w`, or 0 when `w` is not one.
inline char doc_thor_letter(const std::string& w) {
  for (int i = 0; i < 4; ++i)
    if (w == doc_thor_names[i]) return "trsb"[i];
  return 0;
}
#endif  // MOTOLII_STAGE_EFFECTS_THORVG_EFFECT_NAMES_H_
