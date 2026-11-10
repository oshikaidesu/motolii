#ifndef MOTOLII_DOCUMENT_EDIT_KEYS_PUT_H_
#define MOTOLII_DOCUMENT_EDIT_KEYS_PUT_H_

// Keyframes on a property, and changing a property the way a user edit does.
//
// A property either stays or is keyed. A property that stays has one row at
// time 0 with no easing, which is what `set` writes. A keyed property has
// keyframes. A keyframe is a keyframe even when it is the only one. The first
// keyframe of a property takes the place of the value that stayed. A keyframe
// at time 0 is marked by its easing, which is Linear until the user changes it.

namespace motolii {

struct Doc;

// Sets a keyframe of a property at time `at` to the value `is`. Returns false
// and sets d.error if `at` is out of range or the property rejects the value.
bool doc_key(Doc& d, int layer, const char* name, double at, double is);
// Sets many keyframes of one property at once: n keyframes at times at[i] with
// values is[i]. The rule is the one of doc_key, applied once for all keyframes,
// so the value that stayed is deleted when keyframes arrive. One prepared
// statement is reused for every keyframe. The whole call is one act, and the
// stage is rebuilt once at its end.
//
// `easing`, when not null, is the easing of every keyframe. A MIDI import uses
// Hold.
bool doc_key_many(Doc& d, int layer, const char* name, int n, const double* at,
                  const double* is, const char* easing = nullptr);
// Returns the number of keyframes of a property. With `at` of 0 or more,
// returns instead whether the property has a keyframe at exactly that time, as
// 1 or 0.
int doc_keys(Doc& d, int layer, const char* name, double at = -1.0);

// The operations the app calls to change a property at a time, following the
// document's own rules so that the app does not work them out.
//   put      Change the value there. If every change is being keyed, d.keying,
//   add a keyframe
//            there, as the Auto-keyframe mode of After Effects does. If it is
//            the property's first keyframe and later than the time when keying
//            began, the old value is also kept as a keyframe at that earlier
//            time, as in a Jitter animation's bar. If changes are not being
//            keyed, a property that has keyframes gets a keyframe there, as
//            After Effects does for any property with keyframes wherever it is
//            changed. A property without keyframes stays a single value.
//   key_here Add a keyframe at that time holding the value the property has
//   there. Does nothing
//            if it already has one there.
//   raise    Bring a layer nearer or further back among the layers.
//   stay     Remove the property's keyframes. It stays at the value it has at
//   that time. keyed    0 if the property has no keyframes, 1 if it has
//   keyframes but none at that time,
//            2 if it has a keyframe at that time.
//   moving   The names of the properties of a layer that can take keyframes.

// Changes a property to `is` at time `at`, following the rules of After
// Effects. See the list above. Returns false when the property rejects the
// value.
bool doc_put(Doc& d, int layer, const char* name, double at, double is);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EDIT_KEYS_PUT_H_
