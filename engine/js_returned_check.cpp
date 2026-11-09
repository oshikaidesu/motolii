// js_returned_check.cpp: a number of each()'s returned object changed where motolii_js_returned says it is, and nowhere
// else (js_returned_check.sh).   out/js_returned_check <file> <property> <number as written> <new> <to file>
#include "motolii.h"
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <string>

int main(int argc, char** argv) {
    if (argc != 6) return std::fprintf(stderr, "usage: js_returned_check <file> <property> <number> <new> <to>\n"), 2;
    std::ifstream in(argv[1]);
    std::stringstream all;
    all << in.rdbuf();
    std::string src = all.str();
    std::istringstream lines(motolii_js_returned(src.c_str()));
    for (std::string line; std::getline(lines, line);) {
        std::istringstream w(line);
        std::string name, at;
        size_t start = 0, end = 0;
        std::getline(w, name, '\t'), w >> start >> end;
        std::printf("  %s: %s\n", name.c_str(), src.substr(start, end - start).c_str());
        if (name != argv[2]) continue;
        while (w >> at) {
            const size_t a = std::strtoul(at.c_str(), nullptr, 10), b = std::strtoul(at.c_str() + at.find(':') + 1, nullptr, 10);
            if (src.compare(a, b - a, argv[3]) != 0) continue;
            src.replace(a, b - a, argv[4]);
            std::ofstream(argv[5]) << src;
            std::printf("  %s's %s at bytes %zu to %zu is %s now\n", argv[2], argv[3], a, b, argv[4]);
            return 0;
        }
    }
    return std::fprintf(stderr, "no %s in %s's value\n", argv[3], argv[2]), 1;
}
