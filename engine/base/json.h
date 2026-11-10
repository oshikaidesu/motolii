// The one rapidjson. Every file that reads or writes JSON includes this header, so there is a single copy
// (the one Filament's assimp ships) and no file depends on another having included it first.
#ifndef MOTOLII_BASE_JSON_H_
#define MOTOLII_BASE_JSON_H_

#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/document.h"
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/pointer.h"
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/stringbuffer.h"
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/writer.h"

#endif  // MOTOLII_BASE_JSON_H_
