// Float
// https://github.com/ToNi3141/Float
// Copyright (c) 2021 ToNi3141

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.


#define CATCH_CONFIG_MAIN  // This tells Catch to provide a main() - only do this in one cpp file
#include "catch.hpp"

// Include common routines
#include <verilated.h>

// Include model header, generated from Verilating "top.v"
#include "VFloatFastRecip.h"

void clk(VFloatFastRecip* t)
{
    t->clk = 0;
    t->eval();
    t->clk = 1;
    t->eval();
}

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

TEST_CASE("Specific numbers", "[FloatFastRecip]")
{
    VFloatFastRecip* top = new VFloatFastRecip;
    top->ce = 1;

    for (int i = 0; i < 1000000; i++)
    {
        float a = (float)i * 0.001;
        top->in = *(uint32_t*)&a;
        clk(top);
        top->in = 0; // To test the pipeline
        clk(top);
        clk(top);
        clk(top);
        float out;
        *(uint32_t*)&out = top->out;

        float ref = reciprocal(a);
        REQUIRE(Approx(out).epsilon(0.000001) == ref);
    }

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}
