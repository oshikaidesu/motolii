// js_returned_check.cpp: each()'s returned rows as motolii_js_returned says them, and a number of one changed where it
// says the number is and nowhere else (js_returned_check.sh).
//   out/js_returned_check <file>                                      each row: its value, then its parts as written
//   out/js_returned_check <file> <property> <number> <new> <to file>  that number of that row changed, written to <to file>
#include "motolii.h"
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <string>

int main(int argc, char** argv) {
    if (argc != 2 && argc != 6) return std::fprintf(stderr, "usage: js_returned_check <file> [<property> <number> <new> <to>]\n"), 2;
    std::ifstream in(argv[1]);
    std::stringstream all;
    all << in.rdbuf();
    std::string src = all.str();
    std::istringstream lines(motolii_js_returned(src.c_str()));
    for (std::string line; std::getline(lines, line);) {
        std::istringstream w(line);
        std::string name, part;
        size_t start = 0, end = 0;
        std::getline(w, name, '\t'), w >> start >> end;
        std::printf("  %s: %s\n", name.c_str(), src.substr(start, end - start).c_str());
        while (w >> part) {   // (n:start:end, k:Name:start:end)
            const size_t last = part.rfind(':'), before = part.rfind(':', last - 1);
            const size_t a = std::strtoul(part.c_str() + before + 1, nullptr, 10), b = std::strtoul(part.c_str() + last + 1, nullptr, 10);
            if (argc == 2) { std::printf("    %s  %s\n", part.c_str(), src.substr(a, b - a).c_str()); continue; }
            if (name != argv[2] || part[0] != 'n' || src.compare(a, b - a, argv[3]) != 0) continue;
            src.replace(a, b - a, argv[4]);
            std::ofstream(argv[5]) << src;
            std::printf("  %s's %s at bytes %zu to %zu is %s now\n", argv[2], argv[3], a, b, argv[4]);
            return 0;
        }
    }
    return argc == 2 ? 0 : (std::fprintf(stderr, "no %s in %s's value\n", argv[3], argv[2]), 1);
}
