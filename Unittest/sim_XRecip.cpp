// Float
// https://github.com/ToNi3141/Float
// Copyright (c) 2024 ToNi3141

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
#include "VXRecip.h"

void clk(VXRecip* t)
{
    t->clk = 0;
    t->eval();
    t->clk = 1;
    t->eval();
}

TEST_CASE("Specific number", "[XRecip]")
{
    VXRecip* top = new VXRecip;

    top->ce = 1;
    top->in = 0x7fffff; // 0.5
    clk(top);
    top->in = 0; // To test the pipeline
    for (uint32_t i = 0; i < 12; i++)
    {
        clk(top);
    }

    REQUIRE(top->out >> 24 == 2ULL);

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}

TEST_CASE("CE stalls the pipeline", "[XRecip]")
{
    VXRecip* top = new VXRecip;

    top->ce = 1;
    top->in = 0x7fffff; // 0.5
    clk(top);

    top->in = 0; // To test the pipeline
    top->ce = 0;
    clk(top);
    REQUIRE(top->out >> 24 != 2ULL);

    top->ce = 1;
    for (uint32_t i = 0; i < 11; i++)
    {
        clk(top);
        REQUIRE(top->out >> 24 != 2ULL);
    }
    clk(top);
    REQUIRE(top->out >> 24 == 2ULL);

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}

TEST_CASE("Range", "[XRecip]")
{
    VXRecip* top = new VXRecip;
    top->ce = 1;

    for (uint32_t i = 0; i < (1 << 20); i++)
    {
        top->in = i;
        for (int j = 0; j < 13; j++)
        {
            clk(top);
            top->in = 0; // To test the pipeline
        }
        const float out = static_cast<float>(top->out) / (1ull << 48);

        if (i != 0) // Avoid division through zero
        {
            REQUIRE(Approx(1.0f/i).epsilon(0.000001) == out);
        }
    }

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}
