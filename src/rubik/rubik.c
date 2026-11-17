#include "rubik.h"
#include "rubik_tables.h"

enum { CUBIES = 7, MAX_DEPTH = 11 };

static const char move_text[9][3] = {"R",  "R2", "R'", "B", "B2",
                                     "B'", "D",  "D2", "D'"};


static int parse_state(const char *text, unsigned *perm, unsigned *ori)
{
    unsigned p[CUBIES];
    unsigned seen = 0, sum = 0;
    *perm = 0;
    *ori = 0;

    for (unsigned i = 0; i < CUBIES; i++) {
        unsigned digit = (unsigned char) text[i];
        if (digit < '1' || digit > '7')
            return 0;
        p[i] = digit - '1';
        unsigned bit = 1u << p[i];
        if (seen & bit)
            return 0;
        seen |= bit;
    }
    for (unsigned i = 0; i < CUBIES; i++) {
        unsigned digit = (unsigned char) text[CUBIES + i];
        if (digit < '1' || digit > '3')
            return 0;
        unsigned value = digit - '1';
        sum += value;
        if (sum >= 3)
            sum -= 3;
        if (i < 6)
            *ori = *ori * 3 + value;
    }
    if (text[RUBIK_STATE_LEN] != '\0' || sum != 0)
        return 0;

    for (unsigned i = 0; i < CUBIES; i++) {
        unsigned smaller = 0;
        for (unsigned j = i + 1; j < CUBIES; j++)
            smaller += p[j] < p[i];
        *perm = *perm * (CUBIES - i) + smaller;
    }
    return 1;
}

static unsigned heuristic(unsigned perm, unsigned ori)
{
    unsigned p = perm_dist[perm], o = ori_dist[ori];
    return p > o ? p : o;
}

static int search(unsigned perm,
                  unsigned ori,
                  unsigned remaining,
                  unsigned last_face,
                  uint8_t *path)
{
    if (heuristic(perm, ori) > remaining)
        return 0;
    if ((perm | ori) == 0)
        return 1;

    const uint16_t *p = perm_move[perm];
    const uint16_t *o = ori_move[ori];
    for (unsigned face = 0; face < 3; face++) {
        if (face == last_face)
            continue;
        for (unsigned turn = 0; turn < 3; turn++) {
            unsigned move = face * 3 + turn;
            path[0] = (uint8_t) move;
            if (search(p[move], o[move], remaining - 1, face, path + 1))
                return 1;
        }
    }
    return 0;
}

int rubik_solve(const char *state, char *out, size_t cap)
{
    unsigned perm, ori;
    if (!parse_state(state, &perm, &ori))
        return -1;
    if (cap == 0)
        return -2;

    uint8_t path[MAX_DEPTH] = {0};
    unsigned length = heuristic(perm, ori);
    while (length <= MAX_DEPTH && !search(perm, ori, length, 3, path))
        length++;

    if (length > MAX_DEPTH)
        return -1;

    size_t needed = 1; /* NUL */
    for (unsigned i = 0; i < length; i++) {
        needed += i != 0;
        needed += 1 + (move_text[path[i]][1] != '\0');
    }
    if (needed > cap) {
        out[0] = '\0';
        return -2;
    }

    size_t pos = 0;
    for (unsigned i = 0; i < length; i++) {
        unsigned move = path[i];
        if (i != 0)
            out[pos++] = ' ';
        out[pos++] = move_text[move][0];
        if (move_text[move][1])
            out[pos++] = move_text[move][1];
    }
    out[pos] = '\0';
    return (int) length;
}
