#ifndef MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_RUNNER_H_
#define MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_RUNNER_H_

// Declares Script, which runs a JavaScript file that places copies of a layer.
// The file may be in any dialect the adapters know (one of our scripts, a
// Cavalry distribution, a p5.js sketch, code in the form a site posts it, an
// After Effects expression held by a script), so this module sits above the
// adapters, and above media/ for the video a sketch sees. The types and the
// header format are the groundwork in community/quickjs/script.h.
//
// The body defines where each copy of the layer is and how it looks:
//   function each(i, n, t, k) { return { x, y, z, size, rotate, rotate_x,
//   rotate_y, opacity }; }
// Here i is the index of the copy out of n copies, t is the number of seconds
// since the layer began, and k holds the parameters. k also has duration, how
// long the layer lasts, and px, the size of one project pixel in stage units.
// This is how Cavalry's JavaScript Utility gives a Duplicator its points.
// QuickJS-ng runs the code.
//
// each() may take a fifth argument: each(i, n, t, k, at). at.x, at.y and at.z
// are the position the layer's script and the expressions before this one gave
// the copy, or 0 0 0 if there are none. After Effects gives an expression the
// same thing as `value`. What each() returns is added on top of that position.
// See document/scripts/expressions.h.
//
// A script may hold an After Effects expression as it was posted:
// AE.compile(`...`) once, then AE.run(f, ...) in each(). The expression is
// compiled once, not every frame. See ae_expr.h.

#include <array>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "community/quickjs/script.h"

namespace motolii {

// Runs one JavaScript file with QuickJS-ng. The file is a script with an each()
// function, a Cavalry distribution that is run whole, or a p5.js sketch. The
// constructor runs the code once and keeps each().
class Script {
 public:
  // Runs file. p5 is the path of p5.js, needed for a sketch; see p5_stand.h.
  // film is the video that a sketch's createCapture and createVideo see.
  explicit Script(const std::string& file, const std::string& p5 = "",
                  const std::string& film = "");
  ~Script();
  // Returns true if the file ran without error.
  bool ok() const;
  // Returns the text of the error, or an empty string if there was none.
  const std::string& trouble() const;
  // Returns true for a p5.js sketch, which p5.js itself runs; see p5_stand.h.
  bool sketch() const;
  // Returns true if the script has its own each(), which is asked once per
  // copy. Returns false for a sketch and for a Cavalry distribution that is run
  // whole.
  bool lays() const;
  // Returns how many copies the sketch draws at once.
  int most();
  // Returns the shape of the sketch's copies, as the word a solid uses.
  std::string shape();
  // Returns true if the sketch paints on a 2D canvas.
  bool flat();
  // Returns the width of the sketch's canvas.
  int width();
  // Returns the sketch's pixelDensity(): the number of canvas pixels per unit
  // of width.
  float density();
  // Returns the height of the sketch's canvas.
  int height();
  // Evaluates js in the sketch and returns the result as a string.
  std::string said(const std::string& js);
  // Evaluates js in the script, whatever kind it is, and returns the result as
  // a string, as a browser's console answers what is typed in it: the code sees
  // what the file's own code sees. Returns "" if the file did not run or js
  // threw.
  std::string answers(const std::string& js);
  // Evaluates js in the sketch and returns the contents of __bytes that it
  // leaves.
  std::vector<uint8_t> bytes(const std::string& js);
  // Evaluates js in the sketch and returns the Float64Array it answers with.
  // Returns an empty vector if the evaluation failed, which is reported once.
  std::vector<double> numbers(const std::string& js);
  // Returns what makes frame `frame` on a canvas holding frame `had`, which is
  // the result of
  // __paints in p5_stand.h.
  std::vector<double> paints(int frame, int had, int pic = -1);
  // Lets the sketch read the value of another layer: layerValue(id, name, t,
  // otherwise, copy) in its code gives what `read` answers, or NaN while none
  // is set. `copy` is which copy (a split text's letter) is read, -1 (left
  // out) the layer itself. What answers it from the project is
  // document/scripts/script_reads.h.
  using LayerReader =
      std::function<double(int layer, const std::string& name, double t,
                           double otherwise, int copy)>;
  void reads(LayerReader read);
  // Lets the script read the picture of another layer, under After Effects'
  // names for it (ae-expressions.docsforadobe.dev/layer/general/ and
  // /layer/space-transforms/), with the layer's number first as layerValue has
  // it:
  //   sampleImage(id, point, radius, postEffect, t) gives [red, green, blue,
  //     alpha], each 0 to 1, of the rectangle `radius` ([x, y], left out: half
  //     a pixel) around `point` in the layer's own pixels, at second t.
  //   fromWorld(id, point, t) gives where a point of the stage is in the
  //     layer's own pixels at second t, to be handed to sampleImage.
  // While none is set the first gives [0, 0, 0, 0] and the second [NaN, NaN].
  using ImageSampler = std::function<std::array<double, 4>(
      int layer, double x, double y, double rx, double ry, bool post_effect,
      double t)>;
  using PointMapper = std::function<std::array<double, 2>(
      int layer, double x, double y, double z, double t)>;
  void reads_pictures(ImageSampler sample, PointMapper point);
  // Lets the script ask which keyframes a layer has and which layer has a
  // name:
  //   layerKeys(id, name) gives the seconds of the keyframes layer `id` has
  //     for `name` (layerValue's names), in order; [] for none.
  //   layerNamed(name) gives the number of the layer called `name`, 0 for
  //     none.
  // While none is set they give [] and 0.
  using KeyReader =
      std::function<std::vector<double>(int layer, const std::string& name)>;
  using LayerFinder = std::function<int(const std::string& name)>;
  void reads_keys(KeyReader keys, LayerFinder named);
  // Lets the script read the sound of another layer, under the names and with
  // the numbers of the Web's AnalyserNode (W3C Web Audio API, section 1.8,
  // www.w3.org/TR/webaudio-1.1/#AnalyserNode), which p5.sound, three.js and
  // the visualizers posted as plain JavaScript all read. The layer's number
  // comes first and the second last:
  //   getFloatFrequencyData(id, array, t) fills a Float32Array with how strong
  //     each pitch is at second t, in decibels.
  //   getByteFrequencyData(id, array, t) fills a Uint8Array with the same as
  //     bytes: 0 at -100 dB and under, 255 at -30 dB and over (the minDecibels
  //     and maxDecibels an AnalyserNode starts with), the floor of
  //     255 / 70 x (decibels + 100) between.
  //   getFloatTimeDomainData(id, array, t) fills a Float32Array with the
  //     samples of the wave up to second t, each -1 to 1.
  // All three give undefined, and a TypeError for any other kind of array, as
  // on the Web. `sound` answers with the decibels of each pitch (`spectrum`;
  // minus infinity for a pitch with no sound) or with the samples; both arrive
  // in a Float32Array as they are. An array shorter than the answer takes its
  // first part; a longer one keeps what it held in the rest. An empty answer
  // says the layer has no sound: then, and while no `sound` is set, the whole
  // array is filled with silence: bytes and samples of 0, decibels of minus
  // infinity.
  using SoundReader =
      std::function<std::vector<float>(int layer, bool spectrum, double t)>;
  void reads_sound(SoundReader sound);
  // Returns the source lines of the sketch that draw, as sketch_marked reports
  // them.
  std::vector<int> lines() const;
  // Returns n copies of the layer at time t, with the parameters as the project
  // has them now. numbers holds the numeric parameters, and words holds each
  // select as the word it is set to. For a script with each(), calls each()
  // once per copy. The fifth argument is the placement the copy has so far,
  // taken from before, or 0 0 0 if before has no entry. For a file with no
  // each(), runs the whole file with its parameters as globals (n0, n1, ...),
  // plus time and frame. That run must give a Cavalry PointCloud whose points
  // are in pixels. unit is the size of one pixel in stage units.
  std::vector<ScriptCopy> copies(
      int n, double t, const std::map<std::string, double>& numbers,
      const std::map<std::string, std::string>& words, double unit,
      const std::vector<ScriptCopy>& before = {});

 private:
  // Sets the parameters on the script's parameters object.
  void parameters(const std::map<std::string, double>& numbers,
                  const std::map<std::string, std::string>& words);
  // Calls each() for copy i of n at time t, with the parameters as last set. at
  // is where the copy lies so far, passed as each()'s fifth argument.
  ScriptCopy ask(int i, int n, double t, const ScriptCopy& at);

  // State of the JavaScript runtime. Defined in script_runner.cpp.
  struct Own;
  std::unique_ptr<Own> own;
};

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_RUNNER_H_
