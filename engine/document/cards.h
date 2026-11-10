#ifndef MOTOLII_DOCUMENT_CARDS_H_
#define MOTOLII_DOCUMENT_CARDS_H_

// cards.h: a layer's properties as the app lists them: names, words, ranges and
// cards.

#include <string>

namespace motolii {

struct Doc;

// Removes all keyframes of a property, leaving it constant at the value it had
// at time "at". Returns false if the layer does not have the property.
bool doc_stay(Doc& d, int layer, const char* name, double at);
// Returns the words a property of a layer may take, separated by spaces, such
// as the modes of blend or the shapes of a solid. Returns "" if any word is
// allowed or the property is not a word.
std::string doc_words(Doc& d, int layer, const char* name);
// Returns the name of a layer for lists of layers: the user's name if set,
// otherwise the text of a text layer, the shape of a shape layer, or the file
// name.
std::string doc_name(Doc& d, int layer);
// Returns the names of the properties of a layer that can have keyframes,
// separated by spaces.
std::string doc_moving(Doc& d, int layer);
// Returns the names of all properties of a layer, separated by spaces: those
// the values table lists for its kind, plus its script parameters.
std::string doc_has(Doc& d, int layer);
// Returns the title of the card of an effect in a layer's effect list. A ThorVG
// effect uses its card's title, such as Gaussian Blur. A file effect uses its
// file name as a title, so halftone becomes Halftone.
std::string doc_fx_title(const std::string& name);
// Duplicates the effect with the given card title on the layer, placing the
// copy right after the original with the same parameter values and keyframes.
// This matches Alight Motion's effect card menu item Duplicate, which copies an
// effect with its parameters (see EffectsPanel in AbsentMotion). The copy is
// named by inserting ~n before the file extension, as in "Glow~2.fs". fx_source
// reads that name as the original file, and the copy's parameters are its own
// because a parameter name is derived from the effect name (doc_screen_knob).
// Only ISF effects, .wgsl effects and expressions can be duplicated. Returns
// the new effect name, or "" with d.error set on failure.
std::string doc_fx_duplicate(Doc& d, int layer, const std::string& title);
// Returns the titles of a layer's effect cards in effect order, separated by
// ";", such as "Halftone;Gaussian Blur". Effects that are turned off are
// included because their cards exist.
std::string doc_fx_titles(Doc& d, int layer);
// Returns the cards of a layer as "title: name name; title: name". A card
// contains only the properties the layer's kind has, and a card with none is
// left out. If "more" is not null, it receives the cards that exist but are
// hidden until the user asks for them, in the same format.
std::string doc_cards_of(Doc& d, int layer, std::string* more = nullptr);
// Gets the display range of a numeric property of a layer into *low and *high.
// Returns false if the property is not numeric or the layer does not have it.
bool doc_range(Doc& d, int layer, const char* name, double* low, double* high);
// Returns whether a property is on: it has keyframes, or it is set to a nonzero
// value. A color that is set counts as on, black included.
bool doc_on(Doc& d, int layer, const char* name);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_CARDS_H_
