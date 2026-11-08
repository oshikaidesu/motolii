// A group's copies dealt to its things by their ratios (check/group_ratio.sh): three circles in a group, the first ×2,
// the group's Count 8 laid in a row (copy_x). The first should draw 4 of the 8, the others 2 each, in turn 1 1 2 3 1 1 2 3
// (doc_dealt: GROUP_FOCUS_new.md 266, 赤 ×7・青 ×2・黄 ×1 で 7:2:1), and the group's Copies card should show its Count from
// when it is made, the rest of the card only once the Count passes the things it holds (doc_cards_of).
#include "../motolii.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int members_of(Motolii* m, int thing) {   // (how many it draws, as the moment's picture says: "members": {"id": n})
    long version = 0;
    char* json = motolii_picture(m, 2, 0, &version);
    if (!json) return -1;
    int n = -1;
    char key[32];
    snprintf(key, sizeof key, "\"%d\":", thing);
    const char* at = strstr(json, "\"members\"");
    const char* end = at ? strchr(at, '}') : NULL;
    if (at && end) {
        const char* k = strstr(at, key);
        if (k && k < end) n = atoi(k + strlen(key));
    }
    free(json);
    return n;
}

int main(int argc, char** argv) {
    Motolii* m = motolii_open(argv[1], 640, 360);
    if (!m) return printf("not opened\n"), 1;
    int fails = 0;
    int t[3];
    for (int i = 0; i < 3; ++i) t[i] = motolii_add(m, "shape", "circle"), motolii_set(m, t[i], "scale_x", 0.2), motolii_set(m, t[i], "scale_y", 0.2);
    const int group = motolii_add(m, "shape", "null");
    for (int i = 0; i < 3; ++i) motolii_set(m, t[i], "parent", group);
    motolii_set(m, group, "copies", 3);   // (as ⌘G sets it: as many as it holds)
    motolii_at(m, 0);
    usleep(500000);
    const char* cards = motolii_cards(m, group);
    const int countShown = strstr(cards, "Copies:") && strstr(cards, "copies"), layShown = strstr(cards, "copy_x") != NULL;
    printf("count 3 of 3: Copies card with its count %s, no lay on it %s\n", countShown ? "yes" : "NO", !layShown ? "yes" : "NO");
    fails += !countShown || layShown;
    for (int i = 0; i < 3; ++i) {   // (each draws itself once, where it was)
        const int n = members_of(m, t[i]);
        if (n > 1) printf("count 3 of 3: thing %d draws %d, not 1: NO\n", i, n), ++fails;
    }
    motolii_set(m, t[0], "ratio", 2);
    motolii_set(m, group, "copies", 8);
    motolii_set(m, group, "copy_x", 0.2);
    motolii_at(m, 0);
    usleep(500000);
    cards = motolii_cards(m, group);
    printf("count 8 of 3, copy_x said: still no lay card on the group %s\n", strstr(cards, "Arrange:") == NULL ? "yes" : "NO");
    fails += strstr(cards, "Arrange:") != NULL;
    const int want[3] = {4, 2, 2};
    int seen[8] = {0};   // (which of the 8 places in the row each copy lands on: every place once)
    for (int i = 0; i < 3; ++i) {
        const int n = members_of(m, t[i]);
        printf("thing %d (x%d) draws %d, wants %d: %s\n", i, i == 0 ? 2 : 1, n, want[i], n == want[i] ? "yes" : "NO");
        fails += n != want[i];
        for (int j = 0; j < n && j < 8; ++j) {
            double path[4];
            if (motolii_path(m, t[i], j, 0, 0.1, 1, path) != 1) { printf("  copy %d: no path: NO\n", j); ++fails; continue; }
            const double place = path[0] / 0.2 + 3.5;   // (its place in the row, 0 to 7)
            const int k = (int)lround(place);
            printf("  copy %d at x %.3f: place %d\n", j, path[0], k);
            if (fabs(place - k) > 0.05 || k < 0 || k > 7) ++fails; else ++seen[k];
        }
    }
    int once = 1;
    for (int k = 0; k < 8; ++k) once = once && seen[k] == 1;
    printf("every place in the row taken once: %s\n", once ? "yes" : "NO");
    fails += !once;
    // (in turn 1 1 2 3 1 1 2 3: the first thing's copies lie in pairs, places 0-1 and 4-5)
    double p[4];
    int pairs = 1;
    for (int j = 0; j < 4; ++j) {
        motolii_path(m, t[0], j, 0, 0.1, 1, p);
        const int k = (int)lround(p[0] / 0.2 + 3.5);
        pairs = pairs && (k == 0 || k == 1 || k == 4 || k == 5);
    }
    printf("the x2 thing's copies in pairs (1 1 2 3 1 1 2 3): %s\n", pairs ? "yes" : "NO");
    fails += !pairs;
    // (as the window does it: nine circles grouped, a ratio carried by hand on one, then the count carried on the group;
    //  the group's part of the document's picture should then still show no lay: not there unasked, whatever the count
    //  (the user, 11/8), and the document's picture of the group made again by the hand's step)
    int c[9];
    for (int i = 0; i < 9; ++i) c[i] = motolii_add(m, "shape", "circle"), motolii_set(m, c[i], "x", -1.6 + 0.4 * i), motolii_set(m, c[i], "size", 0.12);
    const int g = motolii_add(m, "shape", "null");
    for (int i = 0; i < 9; ++i) motolii_set(m, c[i], "parent", g);
    motolii_set(m, g, "copies", 9);
    motolii_hold(m, c[0]), motolii_carry(m, "ratio", 3, 0), motolii_let_go(m, 1);
    motolii_hold(m, g), motolii_carry(m, "copies", 20, 0), motolii_let_go(m, 1);
    motolii_at(m, 0);
    usleep(500000);
    const char* gc = motolii_cards(m, g);
    long version = 0;
    char* json = motolii_picture(m, 1, 0, &version);
    char key[32];
    snprintf(key, sizeof key, "\"%d\":", g);
    const char* part = json ? strstr(json, key) : NULL;
    const char* pcards = part ? strstr(part, "\"cards\":\"") : NULL;
    const char* pend = pcards ? strchr(pcards + 9, '"') : NULL;   // (the cards string ends at its closing quote)
    const char* found = pcards ? strstr(pcards + 9, "copy_x") : NULL;
    const int inCall = strstr(gc, "copy_x") != NULL, inPicture = found && pend && found < pend, countInPicture = pcards && pend && strstr(pcards + 9, "copies") && strstr(pcards + 9, "copies") < pend;
    printf("by hand, count 20 of 9: no lay unasked in motolii_cards %s, nor in the document's picture %s; its count there %s\n", !inCall ? "yes" : "NO", !inPicture ? "yes" : "NO", countInPicture ? "yes" : "NO");
    if (pcards && pend) printf("  picture cards: %.*s\n", (int)(pend - pcards - 9), pcards + 9);
    else printf("  the group's part not in the picture: NO\n");
    fails += inCall || inPicture || !countInPicture;
    free(json);
    motolii_close(m);
    printf(fails ? "FAIL\n" : "PASS\n");
    return fails != 0;
}
