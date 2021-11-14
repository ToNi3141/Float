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
#include "VFloatSub.h"

void clk(VFloatSub* t)
{
    t->clk = 0;
    t->eval();
    t->clk = 1;
    t->eval();
}

void testSub(VFloatSub* top, uint32_t a, uint32_t b, uint32_t result)
{
    top->aIn = a;
    top->bIn = b;
    // The pipeline has a latency of 4 clocks until the result is computed.
    clk(top);
    clk(top);
    clk(top);
    clk(top);
    REQUIRE(top->sum == result);
}

TEST_CASE( "Check cascating add ", "[Substraction]" ) 
{
    VFloatSub* top = new VFloatSub;
    top->sum = 0;
    for (uint32_t i = 0; i < 1000001; i++)
    {
        top->aIn = top->sum;
        top->bIn = 0xbf800000; // -1
        clk(top);
        clk(top);
        clk(top);
        clk(top);
    }
    REQUIRE(top->sum == 0x49742410);

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}

TEST_CASE( "Check cascating sub ", "[Substraction]" ) 
{
    VFloatSub* top = new VFloatSub;

    top->sum = 0;
    for (uint32_t i = 0; i < 1000001; i++)
    {
        top->aIn = top->sum; 
        top->bIn = 0x3f800000; // +1
        clk(top);
        clk(top);
        clk(top);
        clk(top);
    }
    REQUIRE(top->sum == 0xc9742410);
    
    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}

TEST_CASE("Specific numbers", "[Substraction]")
{
    VFloatSub* top = new VFloatSub;

    // Tests with exponent of 0 and small mantissa
    // 0 - 0
    testSub(top, 0x0, 0x0, 0x0);

    // 0 - 1.4E-45
    testSub(top, 0x0, 0x1, 0x80000001);

    // 1.4E-45 - 0
    testSub(top, 0x1, 0x0, 0x00000001);

    // 1.4E-45 - 1.4E-45
    testSub(top, 0x1, 0x1, 0x0);

    
    // Tests with exponent between 0 and 1 and big manissa (test the edge between big mantissa and exp 0 and exp 1 and mantissa 0)

    // 0 - 1.1754942E-38 = -1.1754942E-38
    testSub(top, 0x0, 0x007fffff, 0x807fffff);

    // 1.1754942E-38 - 0 = 1.1754942E-38
    testSub(top, 0x007fffff, 0x0, 0x007fffff);

    // 1.1754942E-38 - 1.1754942E-38 = 0
    testSub(top, 0x007fffff, 0x007fffff, 0x0);


    // Underflow / Overflow checks

    // Check if we add one to big mantissa, that we overflow
    // 1.1754942E-38 - (-1.4E-45) = 1.17549435E-38
    testSub(top, 0x007fffff, 0x80000001, 0x00800000);

    // Substract one from a zero mantissa and check if we underflow 
    // 1.17549435E-38 - 1.4E-45 = 1.1754942E-38
    testSub(top, 0x00800000, 0x00000001, 0x007fffff);

    // Check if we overflow the mantissa and increment the exponent
    // 4.701978E-38 - -9.403954E-38 = 1.4105933E-37
    testSub(top, 0x01800001, 0x81ffffff, 0x02400000);

    // Check if we underflow the mantissa and decrement the exponent
    // 1.4105933E-37 - 9.403954E-38 = 4.7019785E-38
    testSub(top, 0x02400001, 0x01ffffff, 0x01800002);

    // Check if we can substract from the biggest exponent, which is possible
    // 1.7014118E38 - 1.7014118E38 = 0
    testSub(top, 0x7f000000, 0x7f000000, 0);

    // Check if we can substract from the biggest possible number
    // 3.4028235E38 - 3.4028235E38 = 0
    testSub(top, 0x7f7fffff, 0x7f7fffff, 0);


    // Inf/NaN

    // Check if a Inf/NaN stays an Inf/NaN when we add something
    // Inf/NaN - 123 = Inf/NaN
    testSub(top, 0x7fffffff, 0x42f60000, 0x7fffffff);

    // Check if a Inf/NaN stays an Inf/NaN when we add something
    // Inf/NaN - -123 = Inf/NaN
    testSub(top, 0x7fffffff, 0xc2f60000, 0x7fffffff);

    // Check if a Inf/NaN stays an Inf/NaN when we add something
    // 123 - Inf/NaN = Inf/NaN
    testSub(top, 0x42f60000, 0x7fffffff, 0xffffffff);

    // Check if a Inf/NaN stays an Inf/NaN when we add something
    // -123 - Inf/NaN = Inf/NaN
    testSub(top, 0xc2f60000, 0x7fffffff, 0xffffffff);

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}
