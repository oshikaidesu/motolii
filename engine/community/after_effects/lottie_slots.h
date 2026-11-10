#ifndef MOTOLII_COMMUNITY_AFTER_EFFECTS_LOTTIE_SLOTS_H_
#define MOTOLII_COMMUNITY_AFTER_EFFECTS_LOTTIE_SLOTS_H_

// Exposes the slots of a Lottie file as script parameters and converts
// parameter values back into slot JSON.
//
// A Lottie slot is a value that the file's author allows to be set from
// outside. Each slot is identified by its sid and has the form {"sid": {"p":
// {"a": 0, "k": value}}}. Slots become parameters on the layer's card. Edited
// values are passed back to ThorVG in the same JSON form (LottieAnimation::gen,
// then apply, as ThorVG's own test/testLottie.cpp does).
//
// A slot with one number is one parameter. Two numbers become parameters x and
// y. Three or four numbers are a color with components from 0 to 1. Lottie does
// not define a range, so a number gets one: from 0 (or four times the value, if
// it is negative) to four times its absolute value (at least 1). Text and image
// slots are not exposed as parameters.

#include <string>
#include <vector>

#include "community/quickjs/script.h"

// Reads the file's slots and returns one parameter per number in each slot.
// Returns an empty list if the file cannot be parsed or has no slots. Each
// parameter's "words" field is "lottie <sid> <index of the number in the slot>
// <count of numbers in the slot>"; the function below uses it to rebuild the
// slot.
std::vector<ScriptParameter> lottie_parameters(const std::string& file);
// Returns slot JSON of the form {"sid": {"p": {"a": 0, "k": ...}}} for the
// current values. values[i] is the value of parameters[i]. Only slots with at
// least one value different from the parameter's default (usual) are included;
// a slot left alone keeps animating as the file defines it. Returns an empty
// string if no slot was changed.
std::string lottie_slots_json(const std::vector<ScriptParameter>& parameters,
                              const std::vector<double>& values);

#endif  // MOTOLII_COMMUNITY_AFTER_EFFECTS_LOTTIE_SLOTS_H_
