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

// Floating point reciprocal
// This module is pipelined. It can calculate one reciprocal per clock.
// To get a first approximation of 1/x, it uses some magic number. See the following link:
// Refer to https://en.wikipedia.org/wiki/Fast_inverse_square_root
// Later it does newton iterations reduce the error of the initial approximation. The number
// of iterations can be adapted to get the best tradeoff between logic utilization and accuracy.
// This module has by default a latency of 18 + 1 clock cycles (3 iterations)
// Minimum is one iteration (6 + 1 clock cycles of delay)
module FloatFastRecip2
# (
    parameter MANTISSA_SIZE = 23,
    parameter ITERATIONS = 3, // Reduce the iterations to lower the latency. Each iteration requires 8 clock cycles
    localparam EXPONENT_SIZE = 8, // To avoid problems with the MAGIC_NUMBER, disable the configuration of the exponent
    localparam FLOAT_SIZE = 1 + EXPONENT_SIZE + MANTISSA_SIZE
)
(
    input  wire                      clk,
    input  wire [FLOAT_SIZE - 1 : 0] in,
    output wire [FLOAT_SIZE - 1 : 0] out
);
    localparam MAGIC_NUMBER = 32'h7EF127EA >> (32 - FLOAT_SIZE);
    localparam SIGN_POS = FLOAT_SIZE - 1;
    localparam DELAY = 8;

    wire [FLOAT_SIZE - 1 : 0] inUnsigned = {1'b0, in[0 +: FLOAT_SIZE - 1]};
    wire [FLOAT_SIZE - 1 : 0] invEstimation = MAGIC_NUMBER[0 +: FLOAT_SIZE] - inUnsigned;

    reg  [FLOAT_SIZE - 1 : 0] inUnsignedReg;
    reg  [FLOAT_SIZE - 1 : 0] invEstimationReg;

    wire [FLOAT_SIZE - 1 : 0] result;
    wire                      signDelay;

    wire [FLOAT_SIZE - 1 : 0] x [0 : ITERATIONS];
    wire [FLOAT_SIZE - 1 : 0] iteration [0 : ITERATIONS];

    ValueDelay #(.VALUE_SIZE(1), .DELAY((DELAY * ITERATIONS) + 1)) 
        signDelayInst (.clk(clk), .in(in[SIGN_POS]), .out(signDelay));

    always @(posedge clk)
    begin
        inUnsignedReg <= inUnsigned;
        invEstimationReg <= invEstimation;
    end

    assign x[0] = inUnsignedReg;
    assign iteration[0] = invEstimationReg;

    generate
    genvar i;
    for (i = 0; i < ITERATIONS; i = i + 1) 
    begin : NewtonIterations
        ReciprocalNewtonIteration #(
            .MANTISSA_SIZE(MANTISSA_SIZE),
            .EXPONENT_SIZE(EXPONENT_SIZE)
        ) newtonIteration (
            .clk(clk),
            .x(x[i]),
            .currentIteration(iteration[i]),
            .newIteration(iteration[i + 1])
        );

        ValueDelay #(.VALUE_SIZE(FLOAT_SIZE), .DELAY(DELAY)) 
            xDelay (.clk(clk), .in(x[i]), .out(x[i + 1]));
    end
    endgenerate

    assign out = {signDelay, iteration[ITERATIONS][0 +: FLOAT_SIZE - 1]};
endmodule

module ReciprocalNewtonIteration #(
    parameter MANTISSA_SIZE = 23,
    parameter EXPONENT_SIZE = 8,
    localparam FLOAT_SIZE = 1 + EXPONENT_SIZE + MANTISSA_SIZE
)
(
    input  wire                      clk,
    input  wire [FLOAT_SIZE - 1 : 0] x,
    input  wire [FLOAT_SIZE - 1 : 0] currentIteration,
    output wire [FLOAT_SIZE - 1 : 0] newIteration
);
    localparam TWO_POINT_ZERO = 32'h40000000 >> (32 - FLOAT_SIZE); // float representation for 2.0

    wire [FLOAT_SIZE - 1 : 0] twoMinusX;
    wire [FLOAT_SIZE - 1 : 0] currItMultX;
    wire [FLOAT_SIZE - 1 : 0] currentIterationDelay;

    FloatMul 
    #(
        .MANTISSA_SIZE(MANTISSA_SIZE),
        .EXPONENT_SIZE(EXPONENT_SIZE),
        .DELAY(0)
    ) 
    floatMul 
    (
        .clk(clk),
        .facAIn(x),
        .facBIn(currentIteration),
        .prod(currItMultX)
    );

    FloatSub
    #(
        .MANTISSA_SIZE(MANTISSA_SIZE),
        .EXPONENT_SIZE(EXPONENT_SIZE),
        .ENABLE_OPTIMIZATION(1)
    )
    floatSub
    (
        .clk(clk),
        .aIn(TWO_POINT_ZERO[0 +: FLOAT_SIZE]),
        .bIn(currItMultX),
        .sum(twoMinusX)
    );

    FloatMul 
    #(
        .MANTISSA_SIZE(MANTISSA_SIZE),
        .EXPONENT_SIZE(EXPONENT_SIZE),
        .DELAY(0)
    ) 
    floatMul2
    (
        .clk(clk),
        .facAIn(currentIterationDelay),
        .facBIn(twoMinusX),
        .prod(newIteration)
    );

    ValueDelay #(.VALUE_SIZE(FLOAT_SIZE), .DELAY(6)) 
        currentIterationDelayer (.clk(clk), .in(currentIteration), .out(currentIterationDelay));
endmodule