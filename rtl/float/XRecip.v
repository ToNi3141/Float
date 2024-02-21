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

// Integer reciprocal
// It does not really belong into here, but the float and integer versions are really equal
// and using the same base.
// This is based on the paper: An Efficient Hardware Implementation for a Reciprocal Unit
// See: https://www.researchgate.net/publication/220804890_An_Efficient_Hardware_Implementation_for_a_Reciprocal_Unit
// The calculation of the initial value is basically the same, but the multiplexers are 
// all removed. They are not needed in a pipelined version, because all hardware is by
// the nature of a pipeline always utilized and must exist several times.
// Note: It currently does not handle special cases like inf, NaN or division through zero.
// This module is pipelined. It can calculate one reciprocal per clock.
// It requires 13 clocks to calculate the inverse of a number.
module XRecip
# (
    parameter NUMBER_WIDTH = 24,
    localparam SIGNED_NUMBER_WIDTH = NUMBER_WIDTH + 1,
    localparam EXPONENT_SIZE = $clog2(NUMBER_WIDTH) + 1
)
(
    input  wire                         clk,
    input  wire [NUMBER_WIDTH - 1 : 0]  in,
    output reg  [NUMBER_WIDTH - 1 : 0]  out
);
    ////////////////////////////////////////////////////////////////////////////
    // STEP 0
    // Find exponent
    // Clocks: 1
    ////////////////////////////////////////////////////////////////////////////
    reg  [NUMBER_WIDTH - 1 : 0]     step0_number;
    reg  [EXPONENT_SIZE - 1 : 0]    step0_exponent;

    wire [EXPONENT_SIZE - 1 : 0]    exponent;
    FindExponent #(
        .EXPONENT_SIZE(EXPONENT_SIZE),
        .VALUE_SIZE(NUMBER_WIDTH)
    ) findExponent (
        .value(in),
        .exponent(exponent)
    );
    always @(posedge clk)
    begin
        step0_number <= in;
        step0_exponent <= exponent;
        
    end

    ////////////////////////////////////////////////////////////////////////////
    // STEP 1
    // Normalize number
    // Clocks: 1
    ////////////////////////////////////////////////////////////////////////////
    reg  [SIGNED_NUMBER_WIDTH - 1 : 0]  step1_number;
    reg  [EXPONENT_SIZE - 1 : 0]        step1_exponent;
    always @(posedge clk)
    begin
        step1_exponent <= step0_exponent;
        step1_number <= { 1'b0, step0_number << (NUMBER_WIDTH[0 +: EXPONENT_SIZE] - step0_exponent - 1) };
    end

    ////////////////////////////////////////////////////////////////////////////
    // STEP 2
    // Compute 
    // Clocks: 1
    ////////////////////////////////////////////////////////////////////////////
    wire [SIGNED_NUMBER_WIDTH - 1 : 0]  step2_number;
    wire [EXPONENT_SIZE - 1 : 0]        step2_exponent;

    ComputeRecip #(
        .MS(SIGNED_NUMBER_WIDTH),
        .ITR(2)
    ) step2recip (
        .clk(clk),
        .d(step1_number),
        .v(step2_number)
    );

    ValueDelay #(.VALUE_SIZE(EXPONENT_SIZE), .DELAY(10)) 
        step2exponent (.clk(clk), .in(step1_exponent), .out(step2_exponent));


    ////////////////////////////////////////////////////////////////////////////
    // STEP 3 
    // Denormalize 
    // Clocks: 1
    ////////////////////////////////////////////////////////////////////////////

    always @(posedge clk)
    begin
        out <= step2_number[0 +: NUMBER_WIDTH] >> step2_exponent;
    end

endmodule
