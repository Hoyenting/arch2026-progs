#include "bf16.h"

enum { BF16_INF = 0x7F80, BF16_NAN = 0x7FC0 };

uint16_t bf16_from_f32(uint32_t bits)
{
    /* Preserve the upper bits of infinity and NaN exactly as specified. */
    if ((bits & 0x7F800000u) == 0x7F800000u)
        return (uint16_t) (bits >> 16);

    uint32_t round = 0x7FFFu + ((bits >> 16) & 1u);
    return (uint16_t) ((bits + round) >> 16);
}

uint16_t bf16_mul(uint16_t a, uint16_t b)
{
    unsigned sign = (a ^ b) & 0x8000u;
    int ea = (a >> 7) & 0xFF;
    int eb = (b >> 7) & 0xFF;
    unsigned ma = a & 0x7Fu;
    unsigned mb = b & 0x7Fu;

    /* Operand order matters: an infinite a takes precedence over a NaN b. */
    if (ea == 255) {
        if (ma != 0)
            return a;
        if ((b & 0x7FFFu) == 0)
            return BF16_NAN;
        return (uint16_t) (sign | BF16_INF);
    }
    if (eb == 255) {
        if (mb != 0)
            return b;
        if ((a & 0x7FFFu) == 0)
            return BF16_NAN;
        return (uint16_t) (sign | BF16_INF);
    }
    if ((a & 0x7FFFu) == 0 || (b & 0x7FFFu) == 0)
        return (uint16_t) sign;

    /* Normalize each nonzero significand, including denormal operands. */
    if (ea != 0)
        ma |= 0x80u;
    else {
        ea = 1;
        while (ma < 0x80u) {
            ma <<= 1;
            ea--;
        }
    }
    if (eb != 0)
        mb |= 0x80u;
    else {
        eb = 1;
        while (mb < 0x80u) {
            mb <<= 1;
            eb--;
        }
    }

    unsigned product = ma * mb;
    int exponent = ea + eb - 127;
    if (product >= 0x8000u) {
        product >>= 1;
        exponent++;
    }

    unsigned result_fraction = (product >> 7) & 0x7Fu;
    if (exponent >= 255)
        return (uint16_t) (sign | BF16_INF);
    if (exponent <= 0) {
        if (exponent < -6)
            return (uint16_t) sign;
        return (uint16_t) (sign | (result_fraction >> (1 - exponent)));
    }
    return (uint16_t) (sign | ((unsigned) exponent << 7) | result_fraction);
}

uint16_t bf16_sqrt(uint16_t a)
{
    unsigned exponent = (a >> 7) & 0xFFu;
    unsigned fraction = a & 0x7Fu;
    if (exponent == 255) {
        if (fraction != 0)
            return a;
        return (a & 0x8000u) ? BF16_NAN : a;
    }
    if ((a & 0x7FFFu) == 0)
        return 0; /* Both signed zeros become positive zero. */
    if (a & 0x8000u)
        return BF16_NAN;
    if (exponent == 0)
        return 0;

    unsigned mantissa = 0x80u | fraction;
    int power = (int) exponent - 127;
    if ((exponent & 1u) == 0) {
        mantissa <<= 1;
        power--; /* Make the unbiased exponent even. */
    }

    /* Match the contract's truncated square comparison, not a rounded sqrt. */
    unsigned low = 90, high = 256, root = 0;
    while (low <= high) {
        unsigned mid = (low + high) >> 1;
        if (((mid * mid) >> 7) <= mantissa) {
            root = mid;
            low = mid + 1;
        } else
            high = mid - 1;
    }
    unsigned result_exponent = (unsigned) (power / 2 + 127);
    return (uint16_t) ((result_exponent << 7) | (root & 0x7Fu));
}
