#include "community/sites/adapter.h"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <functional>
#include <map>
#include <regex>
#include <sstream>
#include <string>
#include <system_error>
#include <vector>

#include "community/sites/adapter_shadertoy.h"
#include "community/subtitles/subtitles.h"
#include "third_party/js/twigl/noise.h"

namespace motolii {

namespace {

// Returns `t` as a double-quoted JavaScript string literal. Carriage returns
// are dropped.
std::string adapter_quoted(const std::string& t) {
  std::string out = "\"";
  for (const char c : t)
    out += c == '"'    ? "\\\""
           : c == '\\' ? "\\\\"
           : c == '\n' ? "\\n"
           : c == '\r' ? ""
                       : std::string(1, c);
  return out + "\"";
}

// Rewrites the import statements of a three.js program, which a script cannot
// run. Imports of three become variables taken from THREE. Imports from any
// other module become stand-ins taken from
// __any_names.
std::string adapter_three_imports(std::string src) {
  src = std::regex_replace(
      src,
      std::regex(R"re(import\s+\*\s+as\s+(\w+)\s+from\s+['"]three['"]\s*;?)re"),
      "var $1=globalThis.THREE;");
  src = std::regex_replace(
      src, std::regex(R"re(import\s+(\w+)\s+from\s+['"]three['"]\s*;?)re"),
      "var $1=globalThis.THREE;");
  src = std::regex_replace(
      src,
      std::regex(
          R"re(import\s+(?:\*\s+as\s+)?(\w+)\s+from\s+['"][^'"]+['"]\s*;?)re"),
      "var $1=__any_names.$1;");
  std::string out;
  static const std::regex named(
      R"re(import\s*\{([^}]*)\}\s*from\s*['"]([^'"]+)['"]\s*;?)re");
  auto from = std::sregex_iterator(src.begin(), src.end(), named);
  size_t at = 0;
  for (auto m = from; m != std::sregex_iterator(); ++m) {
    out += src.substr(at, (size_t)m->position() - at),
        at = (size_t)(m->position() + m->length());
    const std::string names = std::regex_replace(
        (*m)[1].str(), std::regex(R"((\w+)\s+as\s+(\w+))"), "$1:$2");
    if ((*m)[2].str() == "three")
      out += "var {" + names + "}=THREE;";
    else
      out += "var {" + names + "}=__any_names;";
  }
  return out + src.substr(at);
}

// Wraps a shader body that has its own main, or a bare body such as twigl's
// geekest mode, so that ISF's main calls it. `name` is the effect's
// description. `before` is placed at the top of the shader, `start` runs at the
// start of each call, and `done` runs after the shader. If the shader reads its
// previous frame, `last` is a regex alternation of the names that texture goes
// by, and the result is a persistent pass kept from frame to frame (PERSISTENT
// in the ISF spec).
std::string adapter_called(const std::string& name, std::string body,
                           const std::string& last, const std::string& before,
                           const std::string& start, const std::string& done) {
  static const std::regex hasMain(R"(\bvoid\s+main\s*\(\s*(void)?\s*\))");
  const std::regex past(R"(\b(?:texture|texture2D)\s*\(\s*(?:)" + last +
                        R"()\s*,)");
  const bool persistent = std::regex_search(body, past);
  body = std::regex_replace(body, past, "texture(isf_img_adapter_last,");
  body = std::regex_search(body, hasMain)
             ? std::regex_replace(body, hasMain, "void adapter_main()")
             : "void adapter_main(){\n" + body + "\n}";
  return "/*{\"ISFVSN\":\"2\",\"DESCRIPTION\":\"" + name +
         "\",\"CATEGORIES\":[\"Shadertoy\"],\"INPUTS\":[]" +
         (persistent ? ",\"PASSES\":[{\"TARGET\":\"adapter_last\","
                       "\"PERSISTENT\":true},{}]"
                     : "") +
         "}*/\n" + before + body + "\nvoid main(){" +
         (persistent ? "if(PASSINDEX==1){gl_FragColor=IMG_NORM_PIXEL(adapter_"
                       "last,gl_FragCoord.xy/RENDERSIZE);return;}"
                     : "") +
         start + "adapter_main();" + done + "}\n";
}

}  // namespace

std::string adapter_name(const std::string& form) {
  static const std::map<std::string, std::string> names = {
      {"", "p5.js"},
      {"shadertoy", "Shadertoy"},
      {"sandbox", "GLSL Sandbox"},
      {"three", "three.js"},
      {"hydra", "Hydra"},
      {"dweet", "Dwitter"},
      {"tixy", "tixy"},
      {"turtle", "Turtletoy"},
      {"two", "Two.js"},
      {"paper", "Paper.js"},
      {"canvas", "Canvas"},
      {"twigl", "twigl"},
      {"bonzomatic", "Bonzomatic"},
      {"subtitles", "Subtitles"}};
  const auto at = names.find(form);
  return at == names.end() ? form : at->second;
}

std::string adapter_form(const std::string& t) {
  static const std::regex twigl(R"(\bFC\b|\buniform\s+vec2\s+r\s*;)"),
      sandbox(R"(\buniform\s+\w+\s+(u_)?(time|resolution)\b)"),
      hydra(R"(\b(osc|noise|voronoi|shape|gradient|solid|src)\s*\()"),
      member(R"(\b[xc]\.\w|\bwith\s*\(\s*x\s*\))"), tixy(R"(\b[tixy]\b)"),
      paper(
          R"(\bnew\s+(Path|Point|Group|Raster|PointText|Layer|Size)\b|\bview\.|\bfunction\s+onFrame\b|\bproject\.)");
  // Subtitles and lyrics, as FFmpeg's own probe tells them
  // (community/subtitles).
  if (!subtitles_format(t).empty()) return "subtitles";
  if (adapter_has(t, "\"ISFVSN\"") || adapter_has(t, "\"INPUTS\"") ||
      adapter_has(t, "\"CATEGORIES\"") || adapter_has(t, "function each"))
    return "";
  if (adapter_has(t, "mainImage")) return "shadertoy";
  if (adapter_has(t, "gl_FragColor") && adapter_has(t, "void main") &&
      std::regex_search(t, sandbox))
    return "sandbox";
  if (adapter_has(t, ".out(") && std::regex_search(t, hydra)) return "hydra";
  if (adapter_has(t, "THREE.") || adapter_has(t, "from 'three'") ||
      adapter_has(t, "from \"three\""))
    return "three";
  if (adapter_has(t, "new Two(")) return "two";
  if (adapter_has(t, "new Turtle(") || adapter_has(t, "extends Turtle") ||
      adapter_has(t, "Canvas.setpenopacity("))
    return "turtle";
  const bool sketch = adapter_has(t, "function draw") ||
                      adapter_has(t, "function setup") ||
                      adapter_has(t, "createCanvas");
  if (sketch) return "";
  if (adapter_has(t, "fGlobalTime") || adapter_has(t, "v2Resolution"))
    return "bonzomatic";
  if (adapter_has(t, "vec") && !adapter_has(t, "=>") &&
      !adapter_has(t, "function") &&
      (std::regex_search(t, twigl) || adapter_has(t, "gl_FragCoord") ||
       adapter_has(t, "gl_FragColor")))
    return "twigl";
  if (std::regex_search(t, paper)) return "paper";
  if (adapter_has(t, "getContext")) return "canvas";
  // A dweet packed into wide characters. Dwitter's own players unpack it by
  // running it.
  if (t.size() <= 900 &&
      (adapter_has(t, "unescape(escape`") || std::regex_search(t, member)))
    return "dweet";
  if (t.size() <= 120 && t.find('\n') == t.rfind('\n') &&
      !adapter_has(t, ";") && !adapter_has(t, "function") &&
      std::regex_search(t, tixy))
    return "tixy";
  return "";
}

std::string adapter_library(const std::string& form) {
  return form == "two"      ? "two/two.min.js"
         : form == "paper"  ? "paper/paper-full.min.js"
         : form == "turtle" ? "turtletoy/turtletoy.umd.cjs"
         : form == "three"  ? "three/three.core.js"
                            : "";
}

std::string adapter_page(
    const std::string& t, const std::filesystem::path& beside,
    const std::function<std::string(const std::string&)>& fetched) {
  static const std::regex named(R"re(\bsrc\s*=\s*['"]([^'"]+)['"])re"),
      ours(R"re(^(p5(\.sound|\.dom)?|three(\.module|\.core)?)(\.min)?\.js$)re");
  std::string out, needs;
  for (size_t at = t.find("<script"); at != std::string::npos;
       at = t.find("<script", at)) {
    const size_t head = t.find('>', at), end = head == std::string::npos
                                                   ? head
                                                   : t.find("</script>", head);
    if (end == std::string::npos) break;
    const std::string tag = t.substr(at, head - at);
    std::smatch name;
    const bool told = std::regex_search(tag, name, named);
    const std::string src = told ? name[1].str() : "",
                      base = std::filesystem::path(src.substr(0, src.find('?')))
                                 .filename()
                                 .string();
    if (std::error_code wrong; told && adapter_has(src, "://")) {
      if (const std::string got = fetched && !adapter_has(tag, "module") &&
                                          !std::regex_match(base, ours)
                                      ? fetched(src)
                                      : "";
          !got.empty())
        needs += "//! needs " + got + "\n";
    } else if (told && !beside.empty() && !std::regex_match(base, ours) &&
               std::filesystem::is_regular_file(beside / src, wrong)) {
      std::ifstream in(beside / src);
      std::stringstream all;
      all << in.rdbuf();
      out += all.str() + "\n";
    } else if (!told &&
               (!adapter_has(tag, "type=") || adapter_has(tag, "module") ||
                adapter_has(tag, "javascript")))
      out += t.substr(head + 1, end - head - 1) + "\n";
    at = end;
  }
  return out.empty() ? t : needs + out;
}

std::vector<std::string> adapter_needs(const std::string& text) {
  std::vector<std::string> out;
  for (size_t at = 0; text.compare(at, 9, "//! needs") == 0;) {
    const size_t end = text.find('\n', at);
    if (end == std::string::npos) break;
    out.push_back(text.substr(at + 10, end - at - 10)), at = end + 1;
  }
  return out;
}

std::string adapter_shader_files(const std::string& text,
                                 const std::filesystem::path& beside) {
  static const std::regex load(
      R"re(\bloadShader\s*\(\s*['"`]([^'"`]+)['"`]\s*,\s*['"`]([^'"`]+)['"`]\s*(?:,[^)]*)?\))re");
  const auto file = [&](const std::string& name) {
    std::ifstream in(beside / name);
    std::stringstream all;
    all << in.rdbuf();
    return all.str();
  };
  std::string out;
  size_t at = 0;
  for (std::sregex_iterator m(text.begin(), text.end(), load), end; m != end;
       ++m) {
    const std::string vert = file((*m)[1]), frag = file((*m)[2]);
    out +=
        text.substr(at, (size_t)m->position() - at) +
        (vert.empty() || frag.empty() ? m->str()
                                      : "createShader(" + adapter_quoted(vert) +
                                            "," + adapter_quoted(frag) + ")");
    at = (size_t)(m->position() + m->length());
  }
  return out + text.substr(at);
}

void adapter_images(const std::string& text,
                    const std::filesystem::path& beside,
                    const std::filesystem::path& saved) {
  static const std::regex load(R"re(\bloadImage\s*\(\s*['"`]([^'"`]+)['"`])re");
  std::error_code wrong;
  for (std::sregex_iterator m(text.begin(), text.end(), load), end; m != end;
       ++m) {
    const std::filesystem::path from = beside / (*m)[1].str(),
                                to = saved.parent_path() / saved.stem();
    if (!std::filesystem::is_regular_file(from, wrong)) continue;
    std::filesystem::create_directories(to, wrong);
    std::filesystem::copy_file(
        from, to / from.filename(),
        std::filesystem::copy_options::overwrite_existing, wrong);
  }
}

std::string adapter_library_text(const std::string& form, std::string text) {
  if (form != "three") return text;
  const size_t at = text.rfind("export {");
  if (at == std::string::npos) return text;
  const std::string names = text.substr(at + 8, text.rfind('}') - at - 8);
  return text.substr(0, at) + "globalThis.THREE = {" +
         std::regex_replace(names, std::regex(R"((\w+) as (\w+))"), "$2: $1") +
         "};\n";
}

std::string adapter_js(const std::string& src, const std::string& form) {
  const std::string body = "function __adapter_body(){" + src +
                           "\n;return typeof walk=='function'?walk:null}\n";
  // Subtitles: libass draws any moment on its own, so __paints asks it for
  // frame f alone and keeps no frames (community/subtitles; p5_stand.h's
  // __paints draws every frame up to f). Set in setup(), which runs after
  // p5_stand.h is read. Drawn so that the canvas's long side
  // is 1920, a new project's (app/lib/bridge/motolii.dart, entry/edit.cpp):
  // pixelDensity() lets the stage place it at its size (canvas_sketch.cpp).
  if (form == "subtitles")
    return "function setup(){const "
           "w=__subtitles_size[0],h=__subtitles_size[1];createCanvas(w,h);"
           "pixelDensity(Math.max(1,1920/Math.max(w,h)));__paints=f=>{__"
           "canvas.take();const "
           "o=__subtitles_frame(f*1000/60,pixelDensity());if(o)drawingContext."
           "putImageData({width:o.w,height:o.h,data:new "
           "Uint8ClampedArray(o.data)},o.x,o.y);const "
           "p=__canvas.take()[1],a=new "
           "Float64Array(p.length+1);a[0]=1;a.set(p,1);return a}}function "
           "draw(){}\n";
  if (form == "dweet")
    return "var "
           "c,x,S=Math.sin,C=Math.cos,T=Math.tan,R=(r,g,b,a)=>'rgba('+(r|0)+','"
           "+(g|0)+','+(b|0)+','+(a===undefined?1:a)+')',time=0,frame=0;"
           "function "
           "setup(){createCanvas(1920,1080);__adapter_canvas();x="
           "drawingContext;c=x.canvas;c.sheet='#fff';c.width=1920}function "
           "draw(){time=(frame=frameCount-1)/60;u(time)}function u(t){" +
           src + "\n}\n";
  if (form == "tixy")
    return "function setup(){createCanvas(1024,1024);noStroke()}function "
           "draw(){background(0);const t=(frameCount-1)/60;for(let "
           "i=0,y=0;y<16;y++)for(let x=0;x<16;x++,i++){const "
           "v=Math.max(-1,Math.min(1,Number(__tixy(t,i,x,y))||0));fill(v<0?'#"
           "f24':'#fff');circle(x*64+32,y*64+32,Math.abs(v)*62)}}function "
           "__tixy(t,i,x,y){with(Math){return(" +
           src + "\n)}}\n";
  if (form == "turtle")
    return "var Canvas,Turtle,__walk,__i=0;function "
           "setup(){createCanvas(1080,1080);noFill();background(255);stroke(0);"
           "Canvas=turtletoy.Canvas,Turtle=turtletoy.Turtle;Canvas."
           "setpenopacity=v=>{background(v<0?0:255);stroke(v<0?255:0,Math.abs("
           "v)*255)};turtletoy.turtleDraw(()=>{},{onDrawLine:(a,b,p,q)=>line(("
           "a+100)*5.4,(b+100)*5.4,(p+100)*5.4,(q+100)*5.4)});__walk=__adapter_"
           "body()}function draw(){for(let "
           "n=0;n<400&&__walk;++n)if(__walk(__i++,1)===false)__walk=null}" +
           body;
  if (form == "two")
    return "function setup(){createCanvas(1920,1080);__adapter_canvas();const "
           "W=Two;Two=class extends "
           "W{constructor(o){o=Object.assign({},o,{type:W.Types.canvas});if(o."
           "width&&o.height&&!o.fullscreen&&!o.fitted)resizeCanvas(o.width,o."
           "height);super(o)}};__adapter_body()}" +
           body;
  if (form == "canvas")
    return "function "
           "setup(){createCanvas(1920,1080);__adapter_canvas();__adapter_body()"
           ";const "
           "e=drawingContext.canvas;if(e.width!==width||e.height!==height)"
           "resizeCanvas(e.width,e.height,true)}" +
           body;
  if (form == "three")
    return "function "
           "setup(){createCanvas(1920,1080,WEBGL);__adapter_canvas();__three_"
           "stand();__adapter_body()}function draw(){}function "
           "__adapter_body(){" +
           adapter_three_imports(src) + "\n}\n";
  if (form == "paper")
    return "function "
           "setup(){createCanvas(1920,1080);__adapter_canvas();paper.setup("
           "drawingContext.canvas);paper.PaperScript.execute(" +
           adapter_quoted(src) +
           ",paper);paper.view.play&&paper.view.play()}\n";
  return src;
}

std::string adapter_isf(const std::string& text) {
  const std::string form = adapter_form(text);
  if (form == "shadertoy") {
    // A single tab, as copied. Every iChannel reads the image the effect is
    // applied to.
    AdapterTab tab;
    tab.name = "Image", tab.code = adapter_toy_clean(text);
    const bool reads = adapter_has(text, "iChannel");
    if (reads) std::fill(tab.channel, tab.channel + 4, 0);
    return adapter_tabs_isf("", {tab}, reads);
  }
  if (form == "bonzomatic") {
    static const std::regex output(
        R"(\blayout\s*\([^)]*\)\s*out\s+vec4\s+(\w+)\s*;)");
    std::smatch said;
    const std::string out =
        std::regex_search(text, said, output) ? said[1].str() : "out_color";
    static const std::regex samplerUniform(
        R"(\buniform\s+sampler[12]D\s+(\w+)\s*;)");
    // Names of its sound and image inputs, whatever they are called. Reads of
    // them return nothing here.
    std::string none = "texFFT\\w*";
    for (std::sregex_iterator at(text.begin(), text.end(), samplerUniform), end;
         at != end; ++at)
      if ((*at)[1] != "texPreviousFrame") none += "|" + (*at)[1].str();
    std::string body = std::regex_replace(
        text,
        std::regex(
            R"(#version[^\n]*|\buniform\s+\w+\s+(?:fGlobalTime|fFrameTime|v2Resolution)\s*;)"),
        "");
    body = std::regex_replace(std::regex_replace(body, output, ""),
                              samplerUniform, "");
    body = std::regex_replace(
        body,
        std::regex(
            R"(\b(?:texture|texture2D|texture1D|textureLod|texelFetch)\s*\(\s*(?:)" +
            none + R"()\s*,)"),
        "adapter_none(");
    // The globals are variables assigned at the start rather than macros,
    // because a Bonzomatic shader usually begins with `#define time
    // fGlobalTime`.
    return adapter_called(
        "Bonzomatic", body, "texPreviousFrame",
        "float fGlobalTime,fFrameTime;vec2 v2Resolution;float "
        "adapter_now(){return TIME;}vec2 adapter_size(){return "
        "RENDERSIZE;}\nvec4 " +
            out +
            ";\nvec4 adapter_none(float a){return vec4(0.);}\nvec4 "
            "adapter_none(float a,float b){return vec4(0.);}\nvec4 "
            "adapter_none(vec2 a){return vec4(0.);}\nvec4 adapter_none(vec2 "
            "a,float b){return vec4(0.);}\n",
        "fGlobalTime=adapter_now();v2Resolution=adapter_size();fFrameTime=1./"
        "60.;",
        "gl_FragColor=vec4(" + out + ".rgb,1.);");
  }
  if (form == "twigl") {
    static const std::regex own(R"(\bvoid\s+main\s*\()"), frag(R"(\bFC\b)");
    std::string body = std::regex_replace(
        text,
        std::regex(
            R"(#version[^\n]*|\bprecision\s+\w+\s+\w+\s*;|\buniform\s+\w+\s+(?:r|m|t|f|s|b|resolution|mouse|time|backbuffer)\s*;|\bout\s+vec4\s+(?:o|outColor)\s*;)"),
        "");
    // The helper functions belong to twigl's geekest mode only. A shader with
    // its own main that does not use FC does not get them.
    const std::string given =
        std::regex_search(text, own) && !std::regex_search(text, frag)
            ? ""
            : twigl_noise;
    return adapter_called(
        "twigl", body, "b|backbuffer",
        "#define FC gl_FragCoord\nvec2 r,m,mouse;float t,f,s;vec4 "
        "o,outColor;\n" +
            given + "\n",
        "r=RENDERSIZE;m=mouse=vec2(0.);t=TIME;f=float(FRAMEINDEX);s=0.;",
        adapter_has(body, "gl_FragColor")
            ? ""
            : std::string("gl_FragColor=vec4(") +
                  (adapter_has(body, "outColor") ? "outColor" : "o") +
                  ".rgb,1.);");
  }
  if (form == "sandbox") {
    std::string body = std::regex_replace(
        text,
        std::regex(
            R"(\buniform\s+\w+\s+(u_)?(time|resolution|mouse)\s*;|\bvarying\s+vec2\s+surface\w*\s*;|#extension[^\n]*)"),
        "");
    body = std::regex_replace(
        body, std::regex(R"(\bvoid\s+main\s*\(\s*void\s*\))"), "void main()");
    if (adapter_has(body, "backbuffer")) {
      // backbuffer is the previous frame's output. GLSL Sandbox has it, and so
      // does twigl's classic mode.
      body = std::regex_replace(
          body, std::regex(R"(\buniform\s+sampler2D\s+backbuffer\s*;)"), "");
      return adapter_called(
          "GLSL Sandbox", body, "backbuffer",
          "#define u_time TIME\n#define u_resolution RENDERSIZE\n#define mouse "
          "vec2(.5)\n#define u_mouse vec2(.5)\n",
          "", "");
    }
    // The site's time and resolution uniforms are ISF's TIME and RENDERSIZE
    // (see community/isf/isf.cpp).
    return "/*{\"ISFVSN\":\"2\",\"DESCRIPTION\":\"GLSL "
           "Sandbox\",\"CATEGORIES\":[\"Shadertoy\"],\"INPUTS\":[]}*/\n#define "
           "u_time TIME\n#define u_resolution RENDERSIZE\n#define mouse "
           "vec2(.5)\n#define u_mouse vec2(.5)\n" +
           body;
  }
  return text;
}

}  // namespace motolii
