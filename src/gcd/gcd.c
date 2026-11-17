#include "gcd.h"

uint32_t gcd_u32(uint32_t a, uint32_t b)
{
    if (a == 0)
        return b;
    if (b == 0)
        return a;

    unsigned common_twos = 0;
    while (((a | b) & 1u) == 0) {
        a >>= 1;
        b >>= 1;
        common_twos++;
    }

    /* Keep a odd for the rest of the algorithm. */
    while ((a & 1u) == 0)
        a >>= 1;

    do {
        /* b is nonzero here. Removing its twos does not change the GCD. */
        while ((b & 1u) == 0)
            b >>= 1;

        /* Subtract the smaller odd number from the larger one. */
        if (a > b) {
            uint32_t temp = a;
            a = b;
            b = temp;
        }
        b -= a;
    } while (b != 0);

    return a << common_twos;
}
