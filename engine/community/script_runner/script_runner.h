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
  // out) the layer itself. Only a relation written as a file uses it, see
  // document/evaluate/world.h.
  using LayerReader =
      std::function<double(int layer, const std::string& name, double t,
                           double otherwise, int copy)>;
  void reads(LayerReader read);
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
