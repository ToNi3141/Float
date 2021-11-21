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
#include "VIntToFloat.h"

void clk(VIntToFloat* t)
{
    t->clk = 0;
    t->eval();
    t->clk = 1;
    t->eval();
}

void testConversion(VIntToFloat* top, int32_t in, uint32_t result)
{
    top->in = in;
    // The pipeline has a latency of 3 clocks until the result is computed.
    clk(top);
    clk(top);
    clk(top);
    clk(top);
    REQUIRE(top->out == result);
}

TEST_CASE("Specific numbers", "[IntToFloat]")
{
    VIntToFloat* top = new VIntToFloat;

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

    testConversion(top, 314159265, 0x4d95cd85);
    testConversion(top, -314159265, 0xcd95cd85);

    testConversion(top, 8388607, 0x4afffffe);
    testConversion(top, -8388607, 0xcafffffe);

    testConversion(top, 16777215, 0x4b7fffff);
    testConversion(top, -16777215, 0xcb7fffff);

    testConversion(top, INT32_MAX, 0x4f000000);
    testConversion(top, INT32_MIN + 1, 0xcf000000); // Reduce the min value by one, because internally we calculate with unsigned 32 bit values. INT32_MIN will overflow INT32_MAX.

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}
