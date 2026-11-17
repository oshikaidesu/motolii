#ifndef MOTOLII_COMMUNITY_SCRIPT_RUNNER_RUN_AE_H_
#define MOTOLII_COMMUNITY_SCRIPT_RUNNER_RUN_AE_H_

// Loads the After Effects expression runtime (lottie-web's ExpressionManager,
// pre-compiled to QuickJS bytecode) into a QuickJS context.  Called once per
// Script, before the user's file is evaluated.

#include <quickjs.h>

#include <string>

namespace motolii {

// Loads the lottie shim and its imports from pre-compiled bytecode into `cx`.
// Sets `trouble` on failure.
void setup_ae_expressions(JSRuntime* rt, JSContext* cx, std::string& trouble);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_SCRIPT_RUNNER_RUN_AE_H_
