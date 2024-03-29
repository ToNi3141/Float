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
#include "VFloatRecip.h"

void clk(VFloatRecip* t)
{
    t->clk = 0;
    t->eval();
    t->clk = 1;
    t->eval();
}

TEST_CASE("Specific number", "[FloatRecip]")
{
    VFloatRecip* top = new VFloatRecip;

    float a = 0.999999940395f; // Number which observed to trigger rounding issues
    top->in = *(uint32_t*)&a;
    clk(top);
    clk(top);
    clk(top);
    clk(top);
    clk(top);
    clk(top);
    clk(top);
    clk(top);
    clk(top);
    clk(top);
    clk(top);
    top->in = 0; // To test the pipeline
    float out;
    *(uint32_t*)&out = top->out;

    REQUIRE(Approx(out).epsilon(0.000001) == (1.0f / a));

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}


TEST_CASE("Range", "[FloatRecip]")
{
    VFloatRecip* top = new VFloatRecip;

    for (int i = -1000000; i < 1000000; i++)
    {
        float a = (float)i * 0.001;
        top->in = *(uint32_t*)&a;
        for (int j = 0; j < 11; j++)
        {
            clk(top);
            top->in = 0; // To test the pipeline
        }
        float out;
        *(uint32_t*)&out = top->out;
        // TODO: The library currently has a bug with inf and nan and so on.
        // The handling is in the verilog code not implemented.
        if (i != 0)
        {
            REQUIRE(Approx(out).epsilon(0.000001) == 1.0f/a);
        }
    }

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;
}
