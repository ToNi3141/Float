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

// Floating point reciprocal
// This is based on the paper: An Efficient Hardware Implementation for a Reciprocal Unit
// See: https://www.researchgate.net/publication/220804890_An_Efficient_Hardware_Implementation_for_a_Reciprocal_Unit
// The calculation of the initial value is basically the same, but the multiplexers are 
// all removed. They are not needed in a pipelined version, because all hardware is by
// the nature of a pipeline always utilized.
// Note: It currently does not handle special cases like inf, NaN or division through zero.
// This module is pipelined. It can calculate one reciprocal per clock.
// It requires 11 clocks to calculate the inverse of a number.
module FloatRecip
# (
    parameter MANTISSA_SIZE = 23,
    parameter EXPONENT_SIZE = 8, // To avoid problems with the MAGIC_NUMBER, disable the configuration of the exponent
    localparam SIGNED_MANZISSA_SIZE = MANTISSA_SIZE + 2, // S1.23
    localparam FLOAT_SIZE = 1 + EXPONENT_SIZE + MANTISSA_SIZE,
    localparam EXPONENT_BIAS = (2 ** (EXPONENT_SIZE - 1)) - 1,
    localparam EXPONENT_INF = (2 ** EXPONENT_SIZE) - 1
)
(
    input  wire                      clk,
    input  wire [FLOAT_SIZE - 1 : 0] in,
    output reg  [FLOAT_SIZE - 1 : 0] out
);
    ////////////////////////////////////////////////////////////////////////////
    // STEP 0 Unpack
    // Clocks: 0
    ////////////////////////////////////////////////////////////////////////////
    wire [EXPONENT_SIZE - 1 : 0]    step0_exp       = in[MANTISSA_SIZE +: EXPONENT_SIZE];
    wire                            step0_sign      = in[MANTISSA_SIZE + EXPONENT_SIZE +: 1];
    wire [MANTISSA_SIZE - 1 : 0]    step0_mantissa  = in[0 +: MANTISSA_SIZE];

    ////////////////////////////////////////////////////////////////////////////
    // STEP 1 Calculate the initial estimation with a precission of around 6 bits
    // Note: This equation has only the precission on a range from 0.5 - 1.0.
    // Therefore always add to the mantissa the hidden one. The lowest value of
    // mantissa will then be 1.0 and the highest 1.9999. The calculation 
    // 1 / mantissa will now have a range between 0.5 - 1.0.
    // Clocks: 4
    ////////////////////////////////////////////////////////////////////////////
    wire signed [SIGNED_MANZISSA_SIZE - 1 : 0]  step1_mantissa;
    wire signed [SIGNED_MANZISSA_SIZE - 1 : 0]  step1_mantissaDenumerator;
    wire        [EXPONENT_SIZE - 1 : 0]         step1_exponent;
    wire                                        step1_sign;

    wire signed [SIGNED_MANZISSA_SIZE - 1 : 0]  mt = { 1'b0, 1'b1, step0_mantissa[0 +: MANTISSA_SIZE] };
    NewtonRaphsonIterationInit #(
        .MS(SIGNED_MANZISSA_SIZE)
    ) newtonIterationInit (
        .clk(clk),
        .a(18'b0_010_10100111110011), // 2.65548
        .b(18'b1_010_00010010011111), // -5.92781
        .c(18'b0_100_01001000101011), // 4.28387
        .D(mt),
        .x0(step1_mantissa)
    );

    ValueDelay #(.VALUE_SIZE(SIGNED_MANZISSA_SIZE), .DELAY(4)) 
        step1mantissaNegative (.clk(clk), .in(~mt + 1), .out(step1_mantissaDenumerator));

    ValueDelay #(.VALUE_SIZE(EXPONENT_SIZE), .DELAY(4)) 
        step1exponent (.clk(clk), .in(EXPONENT_BIAS - (step0_exp - EXPONENT_BIAS + 1)), .out(step1_exponent));

    ValueDelay #(.VALUE_SIZE(1), .DELAY(4)) 
        step1sign (.clk(clk), .in(step0_sign), .out(step1_sign));

    ////////////////////////////////////////////////////////////////////////////
    // STEP 2 Calculate the first iteration
    // It will increase the precission from 6 to 12 bit
    // Clocks: 3
    ////////////////////////////////////////////////////////////////////////////
    wire signed [SIGNED_MANZISSA_SIZE - 1 : 0]  step2_mantissa;
    wire signed [SIGNED_MANZISSA_SIZE - 1 : 0]  step2_mantissaDenumerator;
    wire        [EXPONENT_SIZE - 1 : 0]         step2_exponent;
    wire                                        step2_sign;

    NewtonRaphsonIteration #(
        .MS(SIGNED_MANZISSA_SIZE)
    ) newtonIteration1 (
        .clk(clk),
        .x0(step1_mantissa),
        .Dn(step1_mantissaDenumerator),
        .x1(step2_mantissa)
    );

    ValueDelay #(.VALUE_SIZE(SIGNED_MANZISSA_SIZE), .DELAY(3)) 
        step2mantissaNegative (.clk(clk), .in(step1_mantissaDenumerator), .out(step2_mantissaDenumerator));

    ValueDelay #(.VALUE_SIZE(EXPONENT_SIZE), .DELAY(3)) 
        step2exponent (.clk(clk), .in(step1_exponent), .out(step2_exponent));

    ValueDelay #(.VALUE_SIZE(1), .DELAY(3)) 
        step2sign (.clk(clk), .in(step1_sign), .out(step2_sign));

    ////////////////////////////////////////////////////////////////////////////
    // STEP 3 Calculate the last iteration
    // It will increase the precission from 12 to 24 bit
    // Clocks: 3
    ////////////////////////////////////////////////////////////////////////////
    wire signed [SIGNED_MANZISSA_SIZE - 1 : 0]  step3_mantissa;
    wire        [EXPONENT_SIZE - 1 : 0]         step3_exponent;
    wire                                        step3_sign;
    NewtonRaphsonIteration #(
        .MS(SIGNED_MANZISSA_SIZE)
    ) newtonIteration2 (
        .clk(clk),
        .x0(step2_mantissa),
        .Dn(step2_mantissaDenumerator),
        .x1(step3_mantissa)
    );

    ValueDelay #(.VALUE_SIZE(EXPONENT_SIZE), .DELAY(3)) 
        step3exponent (.clk(clk), .in(step2_exponent), .out(step3_exponent));

    ValueDelay #(.VALUE_SIZE(1), .DELAY(3)) 
        step3sign (.clk(clk), .in(step2_sign), .out(step3_sign));

    ////////////////////////////////////////////////////////////////////////////
    // STEP 4 Pack 
    // Clocks: 1
    ////////////////////////////////////////////////////////////////////////////
    always @(posedge clk)
    begin
        out <= { step3_sign, step3_exponent + { EXPONENT_SIZE { !(step3_mantissa[MANTISSA_SIZE]) } }, step3_mantissa[0 +: MANTISSA_SIZE] };
    end

endmodule

// This module implements the following equation: x1 = x0 * (2 - x0 * D) = x0 * (x0 * -D + 2)
// Clocks: 4
module NewtonRaphsonIteration #(
    // Includes 1 Sign, 1 Integer and rest are the fraction bits. For a float 32 with 23 bit mantissa, this must be 25.
    parameter MS = 25 // S1.23
)
(
    input  wire                     clk,
    input  wire signed [MS - 1 : 0] x0, // S1.23
    input  wire signed [MS - 1 : 0] Dn, // S1.23
    output reg  signed [MS - 1 : 0] x1 // S1.23
);
    localparam [(MS + 2) - 1 : 0] TWO = { 3'b0_10, { ((MS + 2) - 3) { 1'b0 } } }; // signed 2.0 as S2.24

    ////////////////////////////////////////////////////////////////////////////
    // STEP 0 x1 = x0 * -D
    // Clocks: 1
    ////////////////////////////////////////////////////////////////////////////
    reg signed [MS - 1 : 0]         step0_x0; // S1.23
    reg signed [MS + MS - 1 : 0]    step0_x1; // S2.x
    always @(posedge clk)
    begin
        step0_x0 <= x0;
        step0_x1 <= x0 * Dn;
    end

    ////////////////////////////////////////////////////////////////////////////
    // STEP 1 x1 = x1 + 2.0
    // Clocks: 1
    ////////////////////////////////////////////////////////////////////////////
    reg signed [MS - 1 : 0]         step1_x0; // S1.23
    reg signed [(MS + 2) - 1 : 0]   step1_x1; // S2.x
    always @(posedge clk)
    begin
        step1_x0 <= step0_x0;
        step1_x1 <= $signed(step0_x1[(MS + MS) - (MS + 2) +: (MS + 2)]) + $signed(TWO);
    end

    ////////////////////////////////////////////////////////////////////////////
    // STEP 2 x1 = x0 * x1
    // Clocks: 1
    ////////////////////////////////////////////////////////////////////////////
    reg signed [MS + MS - 1 : 0] step2_x1; // S2.x
    always @(posedge clk)
    begin : step2
        reg signed [(MS + 1) - 1 : 0] tmp; // S2.x
        step2_x1 = step1_x0 * step1_x1[0 +: MS]; // Cutoff sign and one integer bit. This number should exceed the range from 0.0 - 1.9999.. and is not negative
        tmp = $signed(step2_x1[(MS + MS) - (MS + 1) +: (MS + 1)]); 
        x1 <= $signed(tmp[0 +: MS]); // Convert S4.x to S1.x by shiftig by three
    end
endmodule

// This module implements the following equation: x0 = a*x² + b*D + c
// Clocks: 4
module NewtonRaphsonIterationInit #(
    // Includes 1 Sign, 1 Integer and rest are the fraction bits. For a float 32 with 23 bit mantissa, this must be 25.
    parameter MS = 25, // S1.23
    localparam FS = 18 // S3.14
)
(
    input  wire                         clk,
    input  wire signed [FS - 1 : 0]     a, // S3.14
    input  wire signed [FS - 1 : 0]     b, // S3.14
    input  wire signed [FS - 1 : 0]     c, // S3.14
    input  wire signed [MS - 1 : 0]     D, // S1.23
    output reg  signed [MS - 1 : 0]     x0 // S1.23
);
`define ConvertFStoMS(x) { x[(FS > MS) ? (FS - MS) : 0 +: (FS > MS) ? MS : FS], { (MS > FS) ? (MS - FS) : 0 { 1'b0 } } }

    ////////////////////////////////////////////////////////////////////////////
    // STEP 0 x0 = a * D 
    // Clocks: 1
    ////////////////////////////////////////////////////////////////////////////
    reg signed [FS - 1 : 0]         step0_b; // S3.14
    reg signed [FS - 1 : 0]         step0_c; // S3.14
    reg signed [MS - 1 : 0]         step0_x; // S1.23
    reg signed [FS + MS - 1 : 0]    step0_x0; // S4.38
    always @(posedge clk)
    begin
        step0_b <= b;
        step0_c <= c;
        step0_x <= D;
        step0_x0 <= a * D;
    end

    ////////////////////////////////////////////////////////////////////////////
    // STEP 1 x0 = x0 + b
    // Clocks: 1
    ////////////////////////////////////////////////////////////////////////////
    reg signed [FS - 1 : 0] step1_c; // S3.14
    reg signed [MS - 1 : 0] step1_x; // S1.23
    reg signed [MS - 1 : 0] step1_x0; // S4.x
    always @(posedge clk)
    begin
        step1_c <= step0_c;
        step1_x <= step0_x;
        step1_x0 <= $signed(step0_x0[(FS + MS) - MS +: MS]) + ($signed(`ConvertFStoMS(step0_b)) >>> 1);
    end

    ////////////////////////////////////////////////////////////////////////////
    // STEP 2 x0 = x0 * D
    // Clocks: 1
    ////////////////////////////////////////////////////////////////////////////
    reg signed [FS - 1 : 0]         step2_c; // S3.14
    reg signed [MS + MS - 1 : 0]    step2_x0; // S5.x
    always @(posedge clk)
    begin
        step2_c <= step1_c;
        step2_x0 <= step1_x * step1_x0;
    end

    ////////////////////////////////////////////////////////////////////////////
    // STEP 3 x0 = x0 + c
    // Clocks: 1
    ////////////////////////////////////////////////////////////////////////////.x
    always @(posedge clk)
    begin : step3
        reg signed [MS - 1 : 0] tmp; // S5.x
        tmp = $signed(step2_x0[(MS + MS) - MS +: MS]) + ($signed(`ConvertFStoMS(step2_c)) >>> 2); 
        x0 <= $signed({ tmp[0 +: MS - 4], 4'b0 }); // Convert S5.x to S1.x by shiftig by four
    end
endmodule
