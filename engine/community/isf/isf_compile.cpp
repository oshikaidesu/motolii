// Compiling the GLSL of an ISF file to WGSL: glslang makes SPIR-V of it and
// Tint converts that to WGSL. Both are already part of the Filament build.

#include "SPIRV/GlslangToSpv.h"
#include "community/isf/isf_translate.h"
#include "sca/builtinResource.h"
#include "src/tint/lang/core/ir/module.h"
#include "src/tint/lang/spirv/reader/reader.h"
#include "src/tint/lang/wgsl/program/program.h"
#include "src/tint/lang/wgsl/writer/writer.h"

namespace motolii {

std::string isf_compile(const std::string& glsl, std::string& why) {
  static std::once_flag once;
  std::call_once(once, [] { glslang::InitializeProcess(); });
  glslang::TShader sh(EShLangFragment);
  const char* src = glsl.c_str();
  sh.setStrings(&src, 1);
  // WebGPU is treated like GLSL ES, as WebGL is, where the compiler defines
  // GL_ES itself. This leaves out the #ifndef GL_ES parts of an ISF file, as
  // Vidvox's ISF-JS-Renderer does.
  sh.setPreamble("#define GL_ES 1\n");
  sh.setEnvInput(glslang::EShSourceGlsl, EShLangFragment,
                 glslang::EShClientVulkan, 100);
  sh.setEnvClient(glslang::EShClientVulkan, glslang::EShTargetVulkan_1_1);
  sh.setEnvTarget(glslang::EShTargetSpv, glslang::EShTargetSpv_1_3);
  const EShMessages msg = EShMessages(EShMsgSpvRules | EShMsgVulkanRules);
  if (!sh.parse(&DefaultTBuiltInResource, 450, false, msg))
    return why = std::string("GLSL: ") + sh.getInfoLog(), "";
  glslang::TProgram program;
  program.addShader(&sh);
  if (!program.link(msg))
    return why = std::string("GLSL: ") + program.getInfoLog(), "";
  std::vector<uint32_t> spv;
  glslang::GlslangToSpv(*program.getIntermediate(EShLangFragment), spv);
  auto ir = tint::spirv::reader::ReadIR(spv);
  if (ir != tint::Success) return why = "SPIR-V: " + ir.Failure().reason, "";
  tint::wgsl::writer::Options o;
  o.allow_non_uniform_derivatives = true;
  auto built = tint::wgsl::writer::ProgramFromIR(ir.Get(), o);
  if (built != tint::Success)
    return why = "WGSL: " + built.Failure().reason, "";
  auto wgsl = tint::wgsl::writer::Generate(built.Get(), o);
  if (wgsl != tint::Success) return why = "WGSL: " + wgsl.Failure().reason, "";
  return wgsl->wgsl;
}

}  // namespace motolii
