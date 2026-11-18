#include "fixed.h"

uint32_t op1(uint32_t a, uint32_t b, int *n)
{
    *n = 0;
    while (b != 0) {
        uint32_t carry = (a & b) << 1;
        a ^= b;
        b = carry;
        (*n)++;
    }
    return a;
}

uint32_t op2(uint32_t a, uint32_t b)
{
    return a - b;
}

uint32_t op3(uint32_t a, uint32_t b)
{
    /* a+b = 2*(a&b) + (a^b) */
    return (a & b) + ((a ^ b) >> 1);
}

int32_t q_mul(int32_t a, int32_t b)
{
    uint32_t ma = a < 0 ? 0u - (uint32_t) a : (uint32_t) a;
    uint32_t mb = b < 0 ? 0u - (uint32_t) b : (uint32_t) b;

    volatile uint64_t product = 0;
    uint64_t term = ma;

    while (mb != 0) {
        if (mb & 1u)
            product += term;
        term <<= 1;
        mb >>= 1;
    }
    if ((a < 0) != (b < 0))
        product = 0u - product;

    product += UINT64_C(1) << (Q - 1);
    uint32_t result = (uint32_t) (product >> Q);

    if (result <= INT32_MAX)
        return (int32_t) result;
    return -1 - (int32_t) (UINT32_MAX - result);
}
