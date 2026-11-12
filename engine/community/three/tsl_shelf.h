#ifndef MOTOLII_COMMUNITY_THREE_TSL_SHELF_H_
#define MOTOLII_COMMUNITY_THREE_TSL_SHELF_H_

// Declares the converter from pasted three.js Shading Language (TSL) code to
// files of the effects shelf. The code is a three.js page's script, as an
// example or a pen has it: it is run whole and unchanged in QuickJS with the
// page stood in, and three.js's own builder writes the WGSL. The JavaScript
// that does this is community/three_shading_language_to_shelf/from_page.js,
// the same the shelf's own TSL files are written with.
#include <string>

namespace motolii {

// Runs `code` and gives what the material of the first mesh it draws is
// written as: `effect`, its colour as an effect that makes its own picture,
// and `points`, a points file, when it moves the mesh's points. Either is
// empty when the material has none. `three` is the directory of three.js's
// builds (third_party/js/three) and `writers` the directory of from_page.js.
// `name` is the files' title. Returns true if one of the two was made; on
// failure returns false and sets `why`.
bool tsl_shelf(const std::string& three, const std::string& writers,
               const std::string& code, const std::string& name,
               std::string& effect, std::string& points, std::string& why);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_THREE_TSL_SHELF_H_
