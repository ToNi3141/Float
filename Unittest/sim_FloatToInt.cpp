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
#include "VFloatToInt.h"

void clk(VFloatToInt* t)
{
    t->clk = 0;
    t->eval();
    t->clk = 1;
    t->eval();
}

void testConversion(VFloatToInt* top, int32_t result, uint32_t in, int8_t offset = 0)
{
    top->in = in;
    top->offset = offset;
    // The pipeline has a latency of 4 clocks until the result is computed.
    clk(top);
    top->in = 0;
    clk(top);
    clk(top);
    clk(top);
    REQUIRE(top->out == result);
}

TEST_CASE("Specific numbers", "[FloatToInt]")
{
    VFloatToInt* top = new VFloatToInt;

    testConversion(top, 0, 0x0);

    testConversion(top, 1, 0x3f800000);
    testConversion(top, -1, 0xbf800000);

    testConversion(top, 2, 0x40000000);
    testConversion(top, -2, 0xc0000000);

    testConversion(top, 3, 0x40400000);
    testConversion(top, -3, 0xc0400000);

    testConversion(top, 123, 0x42f60000);
    testConversion(top, -123, 0xc2f60000);

    testConversion(top, 123, 0x42f60000);
    testConversion(top, -123, 0xc2f60000);

    testConversion(top, 314159264, 0x4d95cd85); // Actual value would be 314159265 but because if conversions error the result is 314159264
    testConversion(top, -314159264, 0xcd95cd85);

    testConversion(top, 8388607, 0x4afffffe);
    testConversion(top, -8388607, 0xcafffffe);

    testConversion(top, 16777215, 0x4b7fffff);
    testConversion(top, -16777215, 0xcb7fffff);

    // Highest values
    testConversion(top, 2147483520, 0x4effffff);
    testConversion(top, -2147483520, 0xceffffff);

    // Overflow
    testConversion(top, 0, 0x4f000000); // Because of conversion errors it overflow now
    testConversion(top, 0, 0xcf000000); // Reduce the min value by one, because internally we calculate with unsigned 32 bit values. INT32_MIN will overflow INT32_MAX.

    // Overflow
    testConversion(top, 0, 0x4f000001);
    testConversion(top, 0, 0xcf000001); 

    // Underflow (0.5) (rounding)
    testConversion(top, 1, 0x3f000000);
    testConversion(top, -1, 0xbf000000); 

    // Underflow (0.499999970198)
    testConversion(top, 0, 0x3effffff);
    testConversion(top, 0, 0xbeffffff); 

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}

TEST_CASE("Exponent Offset", "[FloatToInt]")
{
    VFloatToInt* top = new VFloatToInt;

    testConversion(top, 8, 0x40800000, -1);
    testConversion(top, -8, 0xc0800000, -1);

    testConversion(top, 2, 0x40800000, 1);
    testConversion(top, -2, 0xc0800000, 1);

    testConversion(top, 4096, 0x43800000, -4);
    testConversion(top, -4096, 0xc3800000, -4);
    
    testConversion(top, 16, 0x43800000, 4);
    testConversion(top, -16, 0xc3800000, 4);

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}
