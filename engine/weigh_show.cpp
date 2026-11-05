// weigh_show: a row of 10 rectangles given a stack from weigh.h, drawn by ThorVG's CPU engine at 60 frames a second
// into out/weigh/NNN.ppm (ffmpeg or `sips` makes them a film or PNGs). The first picture of the model on a screen:
// what check/weigh.sh says in numbers, seen. Built and run by weigh_show.sh.
//   out/weigh_show [stack.json] [seconds]       (no file: After Effects' Fade In, each rectangle rising as it comes)
#include "weigh.h"
#include <thorvg.h>
#include <cstdio>
#include <fstream>
#include <sstream>
#include <vector>

static const char* fade_in = R"([
  { "weight": { "kind":"Remap", "way":"Cubic.out", "in":[ { "kind":"Time", "a":0.2, "b":0.6, "delay":0.6, "in":[{"kind":"Index"}] } ] }, "target":"opacity", "op":"Set", "value":1 },
  { "weight": { "kind":"Remap", "way":"Back.out",  "in":[ { "kind":"Time", "a":0.2, "b":0.6, "delay":0.6, "in":[{"kind":"Index"}] } ] }, "target":"y", "op":"Add", "value":-60 }
])";

int main(int argc, char** argv) {
    std::string json = fade_in, trouble;
    if (argc > 1) { std::ifstream in(argv[1]); std::stringstream s; s << in.rdbuf(); json = s.str(); }
    const double seconds = argc > 2 ? std::atof(argv[2]) : 2.0;
    const std::vector<weigh::Effect> stack = weigh::stack_of(json.c_str(), &trouble);
    if (!trouble.empty()) { std::fprintf(stderr, "%s\n", trouble.c_str()); return 1; }

    const int W = 960, H = 240, n = 10;
    if (tvg::Initializer::init(0) != tvg::Result::Success) { std::fprintf(stderr, "ThorVG did not start\n"); return 1; }
    std::vector<uint32_t> pixels((size_t)W * H);
    tvg::SwCanvas* canvas = tvg::SwCanvas::gen();
    canvas->target(pixels.data(), W, W, H, tvg::ColorSpace::ARGB8888);
    std::system("mkdir -p out/weigh");
    for (int frame = 0; frame * 1.0 / 60 <= seconds; ++frame) {
        const double t = frame / 60.0;
        canvas->remove();
        tvg::Shape* back = tvg::Shape::gen();
        back->appendRect(0, 0, W, H), back->fill(24, 24, 28);
        canvas->add(back);
        for (int i = 0; i < n; ++i) {
            weigh::Element e;
            e.index = i, e.n = n, e.pos = {60.0 + i * 92.0, 150.0, 0.0}, e.props = {{"x", e.pos.x}, {"y", e.pos.y}, {"opacity", 0.0}};
            const weigh::Props p = weigh::resolve(e, stack, t);
            tvg::Shape* box = tvg::Shape::gen();
            box->appendRect((float)p.at("x"), (float)p.at("y"), 64, 64, 8, 8);
            box->fill(255, 200, 80), box->opacity((uint8_t)(weigh::clamp01(p.at("opacity")) * 255));
            canvas->add(box);
        }
        canvas->draw(true), canvas->sync();
        char name[64];
        std::snprintf(name, sizeof name, "out/weigh/%03d.ppm", frame);
        if (FILE* f = std::fopen(name, "wb")) {   // (ARGB → PPM's RGB)
            std::fprintf(f, "P6\n%d %d\n255\n", W, H);
            for (uint32_t px : pixels) { const unsigned char rgb[3] = {(unsigned char)(px >> 16), (unsigned char)(px >> 8), (unsigned char)px}; std::fwrite(rgb, 1, 3, f); }
            std::fclose(f);
        }
    }
    delete canvas;
    tvg::Initializer::term();
    std::printf("out/weigh/000.ppm.. : %d frames\n", (int)(seconds * 60) + 1);
    return 0;
}
