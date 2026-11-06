// A group in a group (check/group_in_group.sh): the outer one keyed across, the inner one keyed up with its things in
// turn (Delay each). Each thing should go across with the outer one at once, as one, and up one after another: only the
// inner group's own moves read late (After Effects' delayed parenting, parent.transform.position.valueAtTime(time - delay)).
#include "../motolii.h"
#include <math.h>
#include <stdio.h>
#include <unistd.h>

int main(int argc, char** argv) {
    Motolii* m = motolii_open(argv[1], 640, 360);
    if (!m) return printf("not opened\n"), 1;
    int t[3];
    for (int i = 0; i < 3; ++i) t[i] = motolii_add(m, "shape", "circle"), motolii_set(m, t[i], "x", -0.4 + 0.4 * i), motolii_set(m, t[i], "scale_x", 0.2), motolii_set(m, t[i], "scale_y", 0.2);
    const int inner = motolii_add(m, "shape", "null"), outer = motolii_add(m, "shape", "null");
    for (int i = 0; i < 3; ++i) motolii_set(m, t[i], "parent", inner);
    motolii_set(m, inner, "parent", outer);
    motolii_set(m, inner, "stagger", 0.3);
    motolii_key(m, inner, "y", 0, -0.3), motolii_key(m, inner, "y", 0.5, 0);
    motolii_key(m, outer, "x", 0, 0), motolii_key(m, outer, "x", 1, 0.5);
    int fails = 0;
    for (double at = 0.25; at < 1.0; at += 0.25) {
        motolii_at(m, at);
        usleep(1500000);
        double f[3][8];
        for (int i = 0; i < 3; ++i) motolii_frame(m, t[i], f[i]);
        // (across: each as far from where it began as the others; up: not all alike while they go in turn)
        const double moved0 = f[0][0] - f[1][0], moved2 = f[2][0] - f[1][0];
        const int together = fabs(moved0 + moved2) < 1.0;   // (the middle one stays halfway between the two ends)
        const int turns = at < 1.0 && (fabs(f[0][1] - f[1][1]) > 0.5 || fabs(f[1][1] - f[2][1]) > 0.5);
        printf("at %.2f: across %.1f %.1f %.1f, up %.1f %.1f %.1f: across as one %s, up in turn %s\n", at, f[0][0], f[1][0], f[2][0], f[0][1], f[1][1], f[2][1], together ? "yes" : "no", turns ? "yes" : "no");
        fails += !together;
    }
    motolii_close(m);
    printf(fails ? "FAIL\n" : "PASS\n");
    return fails != 0;
}
