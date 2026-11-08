/* (a check: the three After Effects recipes, AE Ring, AE Grid and AE Stagger (recipes/ae_*.js), judged by what an After
   Effects expression means and not by how the inside runs it: each copy is watched through motolii_path, where it is on
   the stage over time. The conversion from After Effects' pixels to the stage's units is not assumed anywhere: only
   ratios, equalities and signs are asserted (relative 1e-3, angles 0.06 degrees).
   After Effects' y goes down, the stage's y goes up: a ring copy at +90 degrees lies below the middle (stage y < 0), a
   grid's first row (the smallest y of the expression) is the top row (the largest stage y).)
   out/ae_recipes_check <document> */
#include "../motolii.h"
#include <math.h>
#include <stdio.h>
#include <string.h>

#define TOL 1e-3    /* relative */
#define ANG 0.06    /* degrees (1e-3 radian) */
static Motolii* M;
static int bad;
#define SAY(ok, ...) (printf("%s ", (ok) ? "ok  " : (bad++, "FAIL")), printf(__VA_ARGS__), printf("\n"))

typedef struct { double x, y, rot, size; } P;
static const char* tr(void) { const char* s = M ? motolii_trouble(M) : "no stage"; return s ? s : ""; }
static void up(double* w, double d) { if (*w == *w && !(d <= *w)) *w = d; }   /* (the largest of them; a NaN stays) */
static double wrap(double a) { while (a > 180) a -= 360; while (a <= -180) a += 360; return a; }
static double ang(P p) { return atan2(p.y, p.x) * 180 / M_PI; }
static double dist(P p) { return hypot(p.x, p.y); }

/* where a copy is at one moment */
static int at(int f, int copy, double t, P* p) {
    double a[4];
    if (f > 0 && motolii_path(M, f, copy, t, t + 1e-6, 1, a) > 0) { p->x = a[0], p->y = a[1], p->rot = a[2], p->size = a[3]; return 1; }
    p->x = p->y = p->rot = p->size = NAN;
    return 0;
}
static int lay(int f, int n, double t, P* p) {
    int ok = 1;
    for (int i = 0; i < n; i++) ok &= at(f, i, t, p + i);
    return ok;
}
/* a recipe made as a new thing, with the copies and up to two knobs said (copies 0 / knob name 0: as the recipe has them) */
static int mk(const char* recipe, int copies, const char* ka, double va, const char* kb, double vb) {
    int f = motolii_make(M, recipe);
    if (f <= 0) return SAY(0, "%s not made: %s", recipe, tr()), 0;
    if (copies > 0 && !motolii_set(M, f, "copies", copies)) SAY(0, "%s: copies %d not set: %s", recipe, copies, tr());
    if (ka && !motolii_set(M, f, ka, va)) SAY(0, "%s: %s not set to %g: %s", recipe, ka, va, tr());
    if (kb && !motolii_set(M, f, kb, vb)) SAY(0, "%s: %s not set to %g: %s", recipe, kb, vb, tr());
    return f;
}
static int knob(int f, const char* name, double lo, double hi, double usual) {
    double l = -1e9, h = -1e9, v = -1e9;
    int ok = motolii_range(M, f, name, &l, &h) && motolii_value(M, f, name, 0, &v);
    SAY(ok && fabs(l - lo) < 1e-9 && fabs(h - hi) < 1e-9 && fabs(v - usual) < 1e-9, "%s goes %g to %g, as it comes %g (the head says %g to %g, usual %g)", name, l, h, v, lo, hi, usual);
    return ok;
}
static int distinct(const P* p, int n, int axis, double tol) {   /* how many places along x (0) or y (1), told apart by more than tol */
    double seen[64];
    int k = 0;
    for (int i = 0; i < n; i++) {
        double v = axis ? p[i].y : p[i].x;
        int j = 0;
        while (j < k && fabs(seen[j] - v) > tol) j++;
        if (j == k && k < 64) seen[k++] = v;
    }
    return k;
}

/* ---- AE Ring ---- */
static void ring(void) {
    P a[12], b[12], c[12];
    int f = mk("AE Ring", 0, 0, 0, 0, 0);
    SAY(f > 0 && !*tr(), "AE Ring made: thing %d, trouble \"%s\"", f, tr());
    knob(f, "js_Radius", 0, 1000, 300), knob(f, "js_Turn", -360, 360, 0);
    SAY(lay(f, 12, 0, a), "its 12 copies are seen");
    double d0 = dist(a[0]), w = 0;
    SAY(d0 > 0 && a[0].x > 0 && fabs(a[0].y) <= TOL * d0, "copy 0 lies on the +x axis: x %.5g, y %.3g", a[0].x, a[0].y);
    for (int i = 0; i < 12; i++) up(&w, fabs(dist(a[i]) - d0) / d0);
    SAY(d0 > 0 && w <= TOL, "every copy equally far from the middle: %.5g, worst deviation %.2g (relative)", d0, w);
    double mx = 0, my = 0;
    for (int i = 0; i < 12; i++) mx += a[i].x / 12, my += a[i].y / 12;
    SAY(hypot(mx, my) <= TOL * d0, "the ring is about the middle: mean of the copies (%.3g, %.3g)", mx, my);
    w = 0;
    for (int i = 0; i < 12; i++) up(&w, fabs(wrap(ang(a[(i + 1) % 12]) - ang(a[i])) + 30));
    SAY(w <= ANG, "consecutive copies 30 degrees apart, the way the clock goes (-30 on the stage): worst error %.3g degrees", w);
    SAY(a[3].y < 0 && fabs(a[3].x) <= TOL * d0 && a[1].y < 0 && a[9].y > 0 && fabs(a[9].x) <= TOL * d0 && a[6].x < 0,
        "After Effects' y goes down, the stage's up: copy 3 (90 degrees) is below the middle (x %.3g, y %.4g), copy 1 (30) below (y %.4g), copy 9 (270) above (y %.4g), copy 6 (180) left (x %.4g)", a[3].x, a[3].y, a[1].y, a[9].y, a[6].x);
    double t3[3] = {1.3, 4, 7.5};
    w = 0;
    for (int k = 0; k < 3; k++) {
        int ok = lay(f, 12, t3[k], b);
        for (int i = 0; i < 12; i++) up(&w, ok ? hypot(b[i].x - a[i].x, b[i].y - a[i].y) / d0 : NAN);
    }
    SAY(w <= TOL, "the ring does not move in time (at 1.3, 4 and 7.5 s): worst move %.2g (of the distance)", w);

    int g = mk("AE Ring", 0, "js_Turn", 90, 0, 0);
    lay(g, 12, 0, b);
    double wa = 0, wd = 0;
    for (int i = 0; i < 12; i++) up(&wa, fabs(wrap(ang(b[i]) - ang(a[i])) + 90)), up(&wd, fabs(dist(b[i]) - d0) / d0);
    SAY(wa <= ANG && wd <= TOL, "Turn 90 turns every copy by 90 degrees, the way they go round: worst angle error %.3g degrees, distance error %.2g", wa, wd);
    g = mk("AE Ring", 0, "js_Turn", -90, 0, 0);
    lay(g, 12, 0, b);
    wa = 0;
    for (int i = 0; i < 12; i++) up(&wa, fabs(wrap(ang(b[i]) - ang(a[i])) - 90));
    SAY(wa <= ANG, "Turn -90 turns every copy the other way: worst angle error %.3g degrees", wa);
    g = mk("AE Ring", 0, "js_Turn", 360, 0, 0);
    lay(g, 12, 0, b);
    w = 0;
    for (int i = 0; i < 12; i++) up(&w, hypot(b[i].x - a[i].x, b[i].y - a[i].y) / d0);
    SAY(w <= TOL, "Turn 360 puts every copy back where it was: worst move %.2g (of the distance)", w);

    g = mk("AE Ring", 0, "js_Radius", 600, 0, 0);
    lay(g, 12, 0, b);
    w = 0, wa = 0;
    for (int i = 0; i < 12; i++) up(&w, fabs(dist(b[i]) / d0 - 2)), up(&wa, hypot(b[i].x - 2 * a[i].x, b[i].y - 2 * a[i].y) / d0);
    SAY(w <= TOL * 2 && wa <= TOL * 2, "doubling Radius doubles every distance (and keeps the direction): worst ratio error %.2g, worst place error %.2g", w, wa);
    g = mk("AE Ring", 0, "js_Radius", 1000, 0, 0);
    lay(g, 12, 0, b);
    w = 0;
    for (int i = 0; i < 12; i++) up(&w, fabs(dist(b[i]) / d0 - 1000.0 / 300));
    SAY(w <= TOL * 4, "Radius 1000 against 300: every distance 10/3 as far, worst ratio error %.2g", w);
    g = mk("AE Ring", 0, "js_Radius", 0, 0, 0);
    lay(g, 12, 0, b);
    w = 0;
    for (int i = 0; i < 12; i++) up(&w, dist(b[i]) / d0);
    SAY(w <= TOL, "Radius 0 puts every copy on the middle: farthest %.2g (of the usual distance)", w);

    g = mk("AE Ring", 6, 0, 0, 0, 0);
    lay(g, 6, 0, c);
    double d6 = dist(c[0]);
    w = 0, wa = 0;
    for (int i = 0; i < 6; i++) up(&w, fabs(dist(c[i]) - d0) / d0), up(&wa, fabs(wrap(ang(c[(i + 1) % 6]) - ang(c[i])) + 60));
    SAY(d6 > 0 && c[0].x > 0 && fabs(c[0].y) <= TOL * d6 && w <= TOL && wa <= ANG && c[1].y < 0, "6 copies (thisComp.numLayers): 60 degrees apart, same ring as the 12: angle error %.3g degrees, distance error %.2g", wa, w);
    SAY(!*tr(), "AE Ring left no trouble: \"%s\"", tr());
}

/* ---- AE Grid ---- */
/* the copies against a lattice of `cols` columns and a step s: x/s = column - (cols-1)/2 (to the right), y/s = (rows-1)/2 - row (the first row on top);
   how far off, in steps */
static double lattice(const P* p, int n, int cols, double s) {
    int rows = (n + cols - 1) / cols;
    double w = 0;
    for (int i = 0; i < n; i++) up(&w, hypot(p[i].x / s - (i % cols - (cols - 1) / 2.0), p[i].y / s - ((rows - 1) / 2.0 - i / cols)));
    return w;
}
static void grid(void) {
    P g[12], h[12];
    int f = mk("AE Grid", 0, 0, 0, 0, 0);
    SAY(f > 0 && !*tr(), "AE Grid made: thing %d, trouble \"%s\"", f, tr());
    knob(f, "js_Columns", 1, 40, 4), knob(f, "js_Spacing", 0, 500, 120);
    SAY(lay(f, 12, 0, g), "its 12 copies are seen");
    double s = g[1].x - g[0].x, w = 0, wy = 0;
    for (int r = 0; r < 3; r++)
        for (int c = 0; c < 3; c++) up(&w, fabs(g[r * 4 + c + 1].x - g[r * 4 + c].x - s) / s), up(&wy, fabs(g[r * 4 + c + 1].y - g[r * 4 + c].y) / s);
    SAY(s > 0 && w <= TOL && wy <= TOL, "neighbours in a row a constant step apart, to the right: step %.5g, worst step error %.2g, worst slant %.2g (of the step)", s, w, wy);
    w = 0, wy = 0;
    for (int r = 0; r < 2; r++)
        for (int c = 0; c < 4; c++) up(&w, fabs(g[(r + 1) * 4 + c].y - g[r * 4 + c].y + s) / s), up(&wy, fabs(g[(r + 1) * 4 + c].x - g[r * 4 + c].x) / s);
    SAY(s > 0 && w <= TOL && wy <= TOL, "rows the same step apart as the columns, each below the one before: worst step error %.2g, worst slant %.2g (of the step)", w, wy);
    double mx = 0, my = 0, x0 = g[0].x, x1 = g[0].x, y0 = g[0].y, y1 = g[0].y;
    for (int i = 0; i < 12; i++) {
        mx += g[i].x / 12, my += g[i].y / 12;
        x0 = fmin(x0, g[i].x), x1 = fmax(x1, g[i].x), y0 = fmin(y0, g[i].y), y1 = fmax(y1, g[i].y);
    }
    SAY(fabs(mx) <= TOL * s && fabs(my) <= TOL * s && fabs(x0 + x1) <= TOL * s && fabs(y0 + y1) <= TOL * s, "the whole is centred: mean (%.3g, %.3g), box x %.4g..%.4g y %.4g..%.4g", mx, my, x0, x1, y0, y1);
    double top = g[0].y, bottom = g[8].y;
    int okrow = 1;
    for (int i = 0; i < 4; i++) okrow &= g[i].y >= y1 - TOL * s && g[8 + i].y <= y0 + TOL * s && g[i].y > g[8 + i].y;
    SAY(okrow && top > 0 && bottom < 0, "the first row (copies 0..3) is the top one, the largest stage y (%.4g), the last row (8..11) the lowest (%.4g)", top, bottom);
    SAY(distinct(g, 12, 0, TOL * s) == 4 && distinct(g, 12, 1, TOL * s) == 3, "4 columns and 3 rows: %d places across, %d down", distinct(g, 12, 0, TOL * s), distinct(g, 12, 1, TOL * s));
    SAY(lattice(g, 12, 4, s) <= TOL, "12 copies lie on the lattice of 4 columns: worst %.2g (of the step)", lattice(g, 12, 4, s));
    double t3[3] = {1.3, 4, 7.5};
    w = 0;
    for (int k = 0; k < 3; k++) {
        int ok = lay(f, 12, t3[k], h);
        for (int i = 0; i < 12; i++) up(&w, ok ? hypot(h[i].x - g[i].x, h[i].y - g[i].y) / s : NAN);
    }
    SAY(w <= TOL, "the grid does not move in time (at 1.3, 4 and 7.5 s): worst move %.2g (of the step)", w);

    int d = mk("AE Grid", 0, "js_Spacing", 240, 0, 0);
    lay(d, 12, 0, h);
    double s2 = h[1].x - h[0].x;
    SAY(fabs(s2 / s - 2) <= TOL * 2 && lattice(h, 12, 4, s2) <= TOL && lattice(h, 12, 4, 2 * s) <= 2 * TOL, "doubling Spacing doubles the steps (and keeps it centred): step ratio %.5g, off the doubled lattice by %.2g", s2 / s, lattice(h, 12, 4, 2 * s));
    d = mk("AE Grid", 0, "js_Spacing", 0, 0, 0);
    lay(d, 12, 0, h);
    w = 0;
    for (int i = 0; i < 12; i++) up(&w, dist(h[i]) / s);
    SAY(w <= TOL, "Spacing 0 puts every copy on the middle: farthest %.2g (of the usual step)", w);

    d = mk("AE Grid", 0, "js_Columns", 3, 0, 0);
    lay(d, 12, 0, h);
    SAY(distinct(h, 12, 0, TOL * s) == 3 && distinct(h, 12, 1, TOL * s) == 4 && lattice(h, 12, 3, s) <= TOL,
        "Columns 3: 3 columns and 4 rows (%d across, %d down), the same step, centred, first row on top: off the lattice by %.2g", distinct(h, 12, 0, TOL * s), distinct(h, 12, 1, TOL * s), lattice(h, 12, 3, s));
    SAY(h[0].y > h[3].y && h[3].y > h[6].y && h[6].y > h[9].y && h[0].y >= h[1].y - TOL * s && h[9].y <= h[11].y + TOL * s, "Columns 3: the rows go down, copies 0, 3, 6, 9 from the top (y %.4g, %.4g, %.4g, %.4g)", h[0].y, h[3].y, h[6].y, h[9].y);
    d = mk("AE Grid", 0, "js_Columns", 1, 0, 0);
    lay(d, 12, 0, h);
    SAY(distinct(h, 12, 0, TOL * s) == 1 && distinct(h, 12, 1, TOL * s) == 12 && lattice(h, 12, 1, s) <= TOL, "Columns 1: one column of 12 rows: off the lattice by %.2g", lattice(h, 12, 1, s));
    d = mk("AE Grid", 0, "js_Columns", 12, 0, 0);
    lay(d, 12, 0, h);
    SAY(distinct(h, 12, 0, TOL * s) == 12 && distinct(h, 12, 1, TOL * s) == 1 && lattice(h, 12, 12, s) <= TOL, "Columns 12: one row of 12: off the lattice by %.2g", lattice(h, 12, 12, s));
    d = mk("AE Grid", 10, 0, 0, 0, 0);
    lay(d, 10, 0, h);
    SAY(distinct(h, 10, 0, TOL * s) == 4 && distinct(h, 10, 1, TOL * s) == 3 && lattice(h, 10, 4, s) <= TOL, "10 copies (thisComp.numLayers) in 4 columns: 3 rows, the last of two, centred by the rows there are: off the lattice by %.2g", lattice(h, 10, 4, s));
    d = mk("AE Grid", 0, "js_Columns", 5, 0, 0);
    lay(d, 12, 0, h);
    SAY(distinct(h, 12, 0, TOL * s) == 5 && distinct(h, 12, 1, TOL * s) == 3 && lattice(h, 12, 5, s) <= TOL, "Columns 5: 5 columns, 3 rows (5, 5, 2): off the lattice by %.2g", lattice(h, 12, 5, s));
    SAY(!*tr(), "AE Grid left no trouble: \"%s\"", tr());
}

/* ---- AE Stagger ---- */
/* the share of its full size a copy has at a moment (the size of the thing is its full one) */
static double share(int f, int i, double t, double full) {
    P p;
    return at(f, i, t, &p) ? p.size / full : NAN;
}
/* the worst a copy is off 0.5 at the middle of its own stretch, over the 8 */
static double halves(int f, double delay, double length, double full) {
    double w = 0;
    for (int i = 0; i < 8; i++) up(&w, fabs(share(f, i, delay * i + length / 2, full) - 0.5));
    return w;
}
static void stagger(void) {
    const double D = 0.12, L = 0.6;
    int f = mk("AE Stagger", 0, 0, 0, 0, 0);
    SAY(f > 0 && !*tr(), "AE Stagger made: thing %d, trouble \"%s\"", f, tr());
    knob(f, "js_Delay", 0, 1, 0.12), knob(f, "js_Length", 0.05, 3, 0.6);
    double full = 0, w = 0;
    SAY(motolii_value(M, f, "size", 0, &full) && full > 0, "the thing's own size is %g", full);
    for (int i = 0; i < 8; i++) up(&w, share(f, i, 0, full));
    SAY(w <= TOL, "at 0 s every copy is at 0 (copy 0 just at its start, the others before theirs): largest %.2g", w);
    w = 0;
    for (int i = 1; i < 8; i++) up(&w, share(f, i, D * i * 0.5, full));
    SAY(w <= TOL, "well before its start a copy is 0: largest %.2g (copies 1..7 at half their delay)", w);
    w = 0;
    for (int i = 0; i < 8; i++) up(&w, fabs(share(f, i, 7 * D + L + 0.5, full) - 1));
    SAY(w <= TOL, "well after (t = %.2f s) every copy is at 1: worst error %.2g", 7 * D + L + 0.5, w);
    w = 0;
    for (int i = 0; i < 8; i++) up(&w, fabs(share(f, i, D * i + L, full) - 1));
    SAY(w <= TOL, "each copy is 1 at the end of its own stretch (Delay x i + Length): worst error %.2g", w);
    w = halves(f, D, L, full);
    SAY(w <= TOL, "each copy is exactly 0.5 at Delay x i + Length / 2: worst error %.2g", w);
    w = 0;
    for (int i = 0; i < 8; i++)
        for (int k = 1; k <= 3; k++) {
            double m = D * i + L / 2, s = 0.1 * k;   /* (ease is symmetric: the two sides of the middle add to 1) */
            up(&w, fabs(share(f, i, m - s, full) + share(f, i, m + s, full) - 1));
        }
    SAY(w <= TOL, "the ease is symmetric about the middle of the stretch (the two sides at 0.1, 0.2, 0.3 s add to 1): worst error %.2g", w);
    double slow0 = 0, slow1 = 0;
    for (int i = 0; i < 8; i++) up(&slow0, share(f, i, D * i + 0.05 * L, full) / 0.05), up(&slow1, (1 - share(f, i, D * i + 0.95 * L, full)) / 0.05);
    SAY(slow0 <= 0.5 && slow1 <= 0.5, "smooth at both ends: 5%% of the way along in time a copy has grown only %.2g of what a straight line would give at the start, and has %.2g of a straight line left at the end (each under 0.5)", slow0, slow1);

    /* when each copy starts to grow: the first moment it passes 1e-3, on a grid of 5 ms */
    double start[8], dt = 0.005;
    for (int i = 0; i < 8; i++) {
        start[i] = -1;
        for (int k = 0; k < 400 && start[i] < 0; k++) {
            double v = share(f, i, k * dt, full);
            if (v > 1e-3) start[i] = k * dt;
        }
    }
    int later = start[0] >= 0;
    double dev = 0;
    for (int i = 1; i < 8; i++) {
        later &= start[i] > start[i - 1] && start[i - 1] >= 0;
        up(&dev, fabs(start[i] - start[i - 1] - D));
    }
    SAY(later && dev <= 2 * dt, "copy i starts strictly later than copy i-1, by Delay (%.2f s) each: starts %.3f %.3f %.3f ... %.3f s, worst gap error %.3f s", D, start[0], start[1], start[2], start[7], dev);

    int a = mk("AE Stagger", 0, "js_Delay", 0.24, 0, 0), b = mk("AE Stagger", 0, "js_Length", 1.2, 0, 0), z = mk("AE Stagger", 0, "js_Delay", 0, 0, 0);
    SAY(halves(a, 0.24, L, full) <= TOL, "Delay 0.24: copy i is 0.5 at 0.24 x i + 0.3 s: worst error %.2g", halves(a, 0.24, L, full));
    SAY(halves(b, D, 1.2, full) <= TOL, "Length 1.2: copy i is 0.5 at 0.12 x i + 0.6 s: worst error %.2g", halves(b, D, 1.2, full));
    w = 0;
    for (int i = 0; i < 8; i++)
        for (int k = 0; k < 6; k++) up(&w, fabs(share(z, i, 0.1 * k, full) - share(z, 0, 0.1 * k, full)));
    SAY(w <= TOL && halves(z, 0, L, full) <= TOL, "Delay 0: all copies grow together (worst difference %.2g) and are 0.5 at 0.3 s (worst error %.2g)", w, halves(z, 0, L, full));
    double late = 0;
    for (int i = 0; i < 8; i++) up(&late, fabs(share(a, i, 7 * 0.24 + L + 0.5, full) - 1));
    SAY(late <= TOL, "Delay 0.24: well after (t = %.2f s) every copy is at 1: worst error %.2g", 7 * 0.24 + L + 0.5, late);

    /* a row of copies */
    P r[8], r2[8];
    int seen = lay(f, 8, 0, r) && lay(f, 8, 3, r2);
    double step = r[1].x - r[0].x, wy = 0, wx = 0, wm = 0, mean = 0;
    for (int i = 0; i < 8; i++) {
        up(&wy, fabs(r[i].y - r[0].y) / fabs(step)), up(&wm, hypot(r2[i].x - r[i].x, r2[i].y - r[i].y) / fabs(step));
        mean += r[i].x / 8;
        if (i) up(&wx, fabs(r[i].x - r[i - 1].x - step) / fabs(step));
    }
    SAY(seen && step != 0 && wy <= TOL && wx <= TOL && wm <= TOL && fabs(mean) <= TOL * fabs(step), "a row: one height (error %.2g), one step %.5g (error %.2g), centred (mean x %.3g), not moving in time (%.2g) (of the step)", wy, step, wx, mean, wm);
    SAY(!*tr(), "AE Stagger left no trouble: \"%s\"", tr());
}

int main(int argc, char** argv) {
    M = argc > 1 ? motolii_open(argv[1], 540, 960) : 0;
    if (!M) return printf("FAIL not opened\n"), 1;
    ring();
    grid();
    stagger();
    motolii_close(M);
    printf(bad ? "FAIL %d\n" : "PASS\n", bad);
    return bad != 0;
}
