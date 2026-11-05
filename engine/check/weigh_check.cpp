// What weigh.h holds: three motions from three programs, each as JSON alone, come out as those programs would have
// them on a row of 10 copies. Built and run by check/weigh.sh.
#include "../weigh.h"
#include <cstdio>

using namespace weigh;

static int bad = 0, done = 0;
static void is(const char* what, double got, double want, double near = 1e-9) {
    const bool ok = std::fabs(got - want) <= near;
    std::printf("%s: %s (%g%s)\n", what, ok ? "yes" : "NO", got, ok ? "" : (", wanted " + std::to_string(want)).c_str());
    bad += !ok, ++done;
}
static Element row(int i, int n = 10) { Element e; e.index = i, e.n = n, e.pos = {i * 40.0, 0, 0}, e.props = {{"opacity", 0}, {"y", 0}}; return e; }

int main() {
    std::string trouble;

    // After Effects' text animator Fade In (Cavalry's Fade In, animators/fade_in.js: length 0.67 s, delay 0.33 s across
    // the letters, SlowOut): Time wiping along the row by Index, eased Cubic.out, setting opacity to 1.
    const auto ae = stack_of(R"({ "weight": { "kind":"Remap", "way":"Cubic.out", "in":[
                                      { "kind":"Time", "a":0, "b":0.67, "delay":0.33, "in":[{"kind":"Index"}] } ] },
                                  "target":"opacity", "op":"Set", "value":1 })", &trouble);
    is("AE Fade In reads", trouble.empty() && ae.size() == 1, 1);
    is("AE: at 0 s the first letter is clear", resolve(row(0), ae, 0)["opacity"], 0);
    is("AE: at 0.67 s the first letter is whole", resolve(row(0), ae, 0.67)["opacity"], 1);
    is("AE: at 0.67 s the last letter is half through, eased", resolve(row(9), ae, 0.67)["opacity"], godot::Cubic::out((0.67 - 0.33) / 0.67, 0, 1, 1));
    is("AE: at 1.0 s the last letter is whole", resolve(row(9), ae, 1.0)["opacity"], 1);
    is("AE: a middle letter is between", resolve(row(5), ae, 0.4)["opacity"] > 0 && resolve(row(5), ae, 0.4)["opacity"] < 1, 1);

    // Random Fade In: the same with Random as the order (animators/random_fade_in.js).
    const auto rnd = stack_of(R"({ "weight": { "kind":"Time", "a":0, "b":0.67, "delay":0.33, "in":[{"kind":"Random","a":50}] }, "target":"opacity", "op":"Set", "value":1 })");
    { double sum = 0; for (int i = 0; i < 10; ++i) sum += resolve(row(i), rnd, 0.4)["opacity"]; is("Random Fade In: at 0.4 s some are further than others", sum > 1 && sum < 9, 1); }
    is("Random Fade In: the same every time", resolve(row(3), rnd, 0.4)["opacity"], resolve(row(3), rnd, 0.4)["opacity"]);

    // Cinema 4D: a Cloner, a Plain Effector lifting y by 50, under a Spherical Falloff of radius 100 fading over 100
    // about the row's 4th copy (x 120): copies within 100 lifted whole, 200 away untouched, between part way.
    const auto c4d = stack_of(R"({ "weight": { "kind":"Distance", "at":[120,0,0], "a":100, "b":100 }, "target":"y", "op":"Add", "value":50 })");
    is("C4D: under the falloff, lifted whole", resolve(row(3), c4d, 0)["y"], 50);
    is("C4D: 80 away, still whole", resolve(row(1), c4d, 0)["y"], 50);
    is("C4D: 160 away, lifted by 20", resolve(row(7), c4d, 0)["y"], 50 * (1 - 0.6));
    is("C4D: 240 away, untouched", resolve(row(9), c4d, 0)["y"], 0);

    // CSS: two rules, the later over the earlier where both reach (the cascade is a stack of Sets). A step is Index
    // with a == b. (:nth-child(odd), a comb along the row, is NOT one of the five weights: see weigh.sh's last line.)
    const auto css = stack_of(R"([ { "weight": {"kind":"Index","a":0,"b":0}, "target":"opacity", "op":"Set", "value":0.5 },
                                   { "weight": {"kind":"Index","a":0.5,"b":0.5}, "target":"opacity", "op":"Set", "value":1 } ])");
    is("CSS: .item { opacity: .5 } on the first", resolve(row(0), css, 0)["opacity"], 0.5);
    is("CSS: .item:nth-child(n+6) { opacity: 1 } on the last", resolve(row(9), css, 0)["opacity"], 1);
    is("CSS: the later rule wins where both apply", resolve(row(7), css, 0)["opacity"], 1);
    is("CSS: the earlier stays where the later does not reach", resolve(row(3), css, 0)["opacity"], 0.5);

    // Stacked: wiped in by time, lifted by the falloff, with noise — three multiplications in one row.
    const auto all = stack_of(R"([ { "weight": { "kind":"Time", "a":0, "b":0.5, "delay":0.5, "in":[{"kind":"Index"}] }, "target":"opacity", "op":"Set", "value":1 },
                                   { "weight": { "kind":"Distance", "at":[120,0,0], "a":0, "b":200 }, "target":"y", "op":"Add", "value":-30 },
                                   { "weight": { "kind":"Noise", "a":100, "b":1 }, "target":"y", "op":"Add", "value":10 } ])");
    const Props p = resolve(row(3), all, 1.0);
    is("Stacked: three effects, opacity whole at the end", p.at("opacity"), 1);
    is("Stacked: y lifted and jittered", p.at("y") <= -30 + 10 && p.at("y") >= -30, 1);

    // Nothing weighed is nothing changed.
    is("Mul of a value not there is 0", resolve(row(0), stack_of(R"({"weight":{"kind":"Index"},"target":"size","op":"Mul","value":2})"), 0)["size"], 0);
    is("Not JSON is refused", stack_of("{ nope", &trouble).empty() && !trouble.empty(), 1);
    is("No weight said is 1 for every copy", resolve(row(9), stack_of(R"({"target":"opacity","op":"Set","value":0.25})"), 0)["opacity"], 0.25);

    // Texton's shape: a CSS curve as the ease, and an Out that counts from the thing's end.
    is("A bezier way is the keys' curve", ease("bezier 0.42 0 0.58 1", 0.5), 0.5, 1e-6);
    is("A bezier way eases in", ease("bezier 0.42 0 1 1", 0.25) < 0.25, 1);
    { Element e = row(0); e.lasts = 3;
      const auto out = stack_of(R"({ "weight": { "kind":"Time", "a":-0.5, "b":0.5 }, "target":"opacity", "op":"Set", "value":1 })");
      is("An Out has not begun at 2.4 s of 3", resolve(e, out, 2.4)["opacity"], 0);
      is("An Out is half way at 2.75 s of 3", resolve(e, out, 2.75)["opacity"], 0.5); }

    std::printf("weigh.h holds: %s (%d checks)\n", bad ? "NO" : "yes", done);
    return bad ? 1 : 0;
}
