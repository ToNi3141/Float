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
#include "VFloatMul.h"

void clk(VFloatMul* t)
{
    t->clk = 0;
    t->eval();
    t->clk = 1;
    t->eval();
}

void testMul(VFloatMul* top, uint32_t a, uint32_t b, uint32_t result)
{
    top->facAIn = a;
    top->facBIn = b;
    // The pipeline has a latency of 4 clocks until the result is computed.
    clk(top);
    clk(top);
    clk(top);
    clk(top);
    REQUIRE(top->prod == result);
}

void commutativeMulTest(VFloatMul* top, uint32_t a, uint32_t b, uint32_t result)
{
    testMul(top, a, b, result);
    testMul(top, b, a, result);
}

TEST_CASE("Range (4 * b[-100'000.00 to 100'000.00])", "[Multiplication]")
{
    int pipelineCounter = 3;
    VFloatMul* top = new VFloatMul;
    top->ce = 1;
    for (int i = -10000000; i < 10000000; i++)
    {
        float a = 4;
        float b = (float)i * 0.01;

        top->facAIn = *(uint32_t*)&a;
        top->facBIn = *(uint32_t*)&b;
        clk(top);
        
        float result = a * (float)(i - 3) * 0.01;
        // Wait till the result is through the pipeline until we start checking the results
        if (pipelineCounter == 0)
            REQUIRE(top->prod == *(uint32_t*)&result);
        else
            pipelineCounter--;
    }
    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}

TEST_CASE("CE stalls the pipeline", "[Multiplication]")
{
    int pipelineCounter = 3;
    VFloatMul* top = new VFloatMul;

    float a = 4;
    float result = 16;
    uint32_t u32Result = *(uint32_t*)&result;

    top->facAIn = *(uint32_t*)&a;
    top->facBIn = *(uint32_t*)&a;
    top->ce = 0;
    clk(top);
    REQUIRE(top->prod != u32Result);

    top->ce = 1;
    clk(top);
    REQUIRE(top->prod != u32Result);

    top->ce = 1;
    clk(top);
    REQUIRE(top->prod != u32Result);

    top->ce = 1;
    clk(top);
    REQUIRE(top->prod != u32Result);

    top->ce = 0;
    clk(top);
    REQUIRE(top->prod != u32Result);
    
    top->ce = 1;
    clk(top);
    REQUIRE(top->prod == u32Result);

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}

TEST_CASE("Range (a[-100'000.00 to 100'000.00] * 4)", "[Multiplication]")
{
    int pipelineCounter = 3;
    VFloatMul* top = new VFloatMul;
    top->ce = 1;
    for (int i = -10000000; i < 10000000; i++)
    {
        float a = (float)i * 0.01;
        float b = 4;
        
        top->facAIn = *(uint32_t*)&a;
        top->facBIn = *(uint32_t*)&b;
        clk(top);
        
        float result = b * (float)(i - 3) * 0.01;
        // Wait till the result is through the pipeline until we start checking the results
        if (pipelineCounter == 0)
            REQUIRE(top->prod == *(uint32_t*)&result);
        else
            pipelineCounter--;
    }
    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}


TEST_CASE("Specific numbers", "[Multiplication]")
{
    VFloatMul* top = new VFloatMul;
    top->ce = 1;

    // Tests with exponent of 0 and small mantissa
    // 0 * 0
    commutativeMulTest(top, 0x0, 0x0, 0x0);

    // 0 * 1.4E-45
    commutativeMulTest(top, 0x0, 0x1, 0x0);

    // 1.4E-45 * 1.4E-45 = 0 (1.96e-90)
    commutativeMulTest(top, 0x1, 0x1, 0x0);

    // 0 * 1.0 = 0
    commutativeMulTest(top, 0x0, 0x3f800000, 0x0);

    // 1.0 * 1.0 = 1.0
    commutativeMulTest(top, 0x3f800000, 0x3f800000, 0x3f800000);

    // 0 * 2.0 = 0
    commutativeMulTest(top, 0x0, 0x40000000, 0x0);

    // 2.0 * 2.0 = 4.0
    commutativeMulTest(top, 0x40000000, 0x40000000, 0x40800000);



    // 0 * 1.1754942E-38 = 0
    commutativeMulTest(top, 0x0, 0x007fffff, 0x0);

    // 1.1754942E-38 * 1.1754942E-38 = 0 (1.3817866e-76)
    commutativeMulTest(top, 0x007fffff, 0x007fffff, 0x0);

    commutativeMulTest(top, 0x3f800000, 0x3f800000, 0x3f800000);

    // 5.42101086243e-20 * 1.0842022E-19 = 1.17549435082e-38
    commutativeMulTest(top, 0x20000000, 0x20000000, 0x00800000);

    // 1.0842022E-19 * 1.0842022E-19 = 0 (5.8774719e-39)
    commutativeMulTest(top, 0x1f800000, 0x20000000, 0x0);

    // Check border between 1.0 and 0.5
    commutativeMulTest(top, 0x3f800000, 0x3f000000, 0x3f000000);

    // Check border between 0.5 and 1.0
    commutativeMulTest(top, 0x3f000000, 0x3f800000, 0x3f000000);

    // 1.40129846432e-45 * 1.0 = 1.40129846432e-45
    commutativeMulTest(top, 0x3f800000, 0x00000001, 0x00000001);

    // 1.0 * 2.80259692865e-45 = 2.80259692865e-45
    commutativeMulTest(top, 0x3f800000, 0x2, 0x2);

    // 1.00000023842 * 2.80259692865e-45 = 2.80259692865e-45
    commutativeMulTest(top, 0x3f800002, 0x2, 0x2);

    // 2.0 * 3.0 = 6.0
    commutativeMulTest(top, 0x40000000, 0x40400000, 0x40c00000);

    // 3.0 * 3.0 = 9.0
    commutativeMulTest(top, 0x40400000, 0x40400000, 0x41100000);

    // 3.14159265 * 2.71828183 = 8.539734
    commutativeMulTest(top, 0x40490fdb, 0x402df854, 0x4108a2c0);



    // 1.84467440737e+19 * 1.84467440737e+19 = 0x7f800000 (inf)
    commutativeMulTest(top, 0x5f800000, 0x5f800000, 0x7f800000);

    // 9.22337203685e+18 * 1.84467440737e+19 = 1.7014118E38
    commutativeMulTest(top, 0x5f000000, 0x5f800000, 0x7f000000);

    // inf * 0.0 = 0.0
    commutativeMulTest(top, 0x7f800000, 0x0, 0x0);

    // inf * inf = inf
    commutativeMulTest(top, 0x7f800000, 0x7f800000, 0x7f800000);

    // 8.50705917302e+37 * 1.0 = 8.50705917302e+37
    commutativeMulTest(top, 0x7e800000, 0x3f800000, 0x7e800000);

    // 8.50705917302e+37 * 2.0 = 1.7014118E38
    commutativeMulTest(top, 0x7e800000, 0x40000000, 0x7f000000);

    // 8.50705917302e+37 * 4.0 = inf
    commutativeMulTest(top, 0x7e800000, 0x40800000, 0x7f800000);

    // 2.5521178E38 * 1.3 = 3.317753E+38
    commutativeMulTest(top, 0x7f400000, 0x3fa66666, 0x7f799999);

    // 2.5521178E38 * 1.4 = inf
    commutativeMulTest(top, 0x7f400000, 0x3fb33333, 0x7f800000);

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}
