#include <QCoreApplication>
#include <QDebug>

__inline__ float __attribute__((const)) reciprocal( float x ) {
    union {
        float single;
        #ifdef __cplusplus
            std::uint_least32_t uint;
        #else
            uint_least32_t uint;
        #endif
    } u;
    u.single = x;
    u.uint = ( 0xbe6eb3beU - u.uint ) >> 1;
//    u.uint = ( 0xbe680000U - u.uint ) >> 1;
                                // pow( x, -0.5 )
    u.single *= u.single;       // pow( pow(x,-0.5), 2 ) = pow( x, -1 ) = 1.0 / x
    return u.single;
}

__inline__ double __attribute__((const)) reciprocal( double x ) {
    union {
        double dbl;
        #ifdef __cplusplus
            std::uint_least64_t ull;
        #else
            uint_least64_t ull;
        #endif
    } u;
    u.dbl = x;
    u.ull = ( 0xbfcdd6a18f6a6f52ULL - u.ull ) >> 1;
                                // pow( x, -0.5 )
    u.dbl *= u.dbl;             // pow( pow(x,-0.5), 2 ) = pow( x, -1 ) = 1.0 / x
    return u.dbl;
}

float inv_fast(float x) {
    union { float f; int i; } v;
    float w, sx;
    int m;

    sx = (x < 0) ? -1:1;
    x = sx * x;

    v.i = (int)(0x7EF127EA - *(uint32_t *)&x);
    w = x * v.f;

    // Efficient Iterative Approximation Improvement in horner polynomial form.
    v.f = v.f * (2 - w);     // Single iteration, Err = -3.36e-3 * 2^(-flr(log2(x)))
    // v.f = v.f * ( 4 + w * (-6 + w * (4 - w)));  // Second iteration, Err = -1.13e-5 * 2^(-flr(log2(x)))
    // v.f = v.f * (8 + w * (-28 + w * (56 + w * (-70 + w *(56 + w * (-28 + w * (8 - w)))))));  // Third Iteration, Err = +-6.8e-8 *  2^(-flr(log2(x)))

    return v.f * sx;
}
int main(int argc, char *argv[])
{
    for (int i = 1400; i < 10000; i++)
    {
        float x = (float)i / 10000;
        qDebug() << x << reciprocal(x) << inv_fast(x) << 1.0 / x;
    }

}
