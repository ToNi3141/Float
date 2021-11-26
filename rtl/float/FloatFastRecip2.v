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
// This module is pipelined. It can calculate one reciprocal per clock
// This module uses an magic algorithm to calculate that. It is similar to the FloatFastRecip modul, but
// this module is much more accurate with the disadvantage that it uses more logic and has much more delay.
// Refer to https://en.wikipedia.org/wiki/Fast_inverse_square_root
// This module has a latency of 12 clock cycles
module FloatFastRecip2
# (
    parameter MANTISSA_SIZE = 23,
    localparam EXPONENT_SIZE = 8, // To make the implementation a bit more simple, disallow exponent adaption
    localparam FLOAT_SIZE = 1 + EXPONENT_SIZE + MANTISSA_SIZE
)
(
    input  wire                      clk,
    input  wire [FLOAT_SIZE - 1 : 0] in,
    output wire [FLOAT_SIZE - 1 : 0] out
);
    localparam MAGIC_NUMBER = 32'h7EF127EA >> (32 - FLOAT_SIZE); // Some magic number
    localparam TWO_POINT_ZERO = 32'h40000000 >> (32 - FLOAT_SIZE); // float representation for 2.0
    localparam SIGN_POS = FLOAT_SIZE - 1;

    wire [FLOAT_SIZE - 1 : 0] inUnsigned = {1'b0, in[0 +: FLOAT_SIZE - 1]};
    wire [FLOAT_SIZE - 1 : 0] v = MAGIC_NUMBER[0 +: FLOAT_SIZE] - inUnsigned;

    wire [FLOAT_SIZE - 1 : 0] w;
    wire [FLOAT_SIZE - 1 : 0] tmp;

    wire [FLOAT_SIZE - 1 : 0] result;

    FloatMul 
    #(
        .MANTISSA_SIZE(MANTISSA_SIZE),
        .EXPONENT_SIZE(EXPONENT_SIZE)
    ) 
    floatMul 
    (
        .clk(clk),
        .facAIn(inUnsigned),
        .facBIn(v),
        .prod(w)
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
        .bIn(w),
        .sum(tmp)
    );

    FloatMul 
    #(
        .MANTISSA_SIZE(MANTISSA_SIZE),
        .EXPONENT_SIZE(EXPONENT_SIZE)
    ) 
    floatMul2
    (
        .clk(clk),
        .facAIn(vDelay[0]),
        .facBIn(tmp),
        .prod(result)
    );

    // Used to delay some values
    integer i;
    reg [FLOAT_SIZE - 1 : 0]    vDelay [0 : 7];
    reg                         signDelay[0 : 11];
    always @(posedge clk)
    begin
        for (i = 0; i < 7; i = i + 1)
        begin
            vDelay[i] <= vDelay[i + 1];
        end
        vDelay[7] <= v;

        for (i = 0; i < 11; i = i + 1)
        begin
            signDelay[i] <= signDelay[i + 1];
        end
        signDelay[11] <= in[SIGN_POS];
    end

    assign out = {signDelay[0], result[0 +: FLOAT_SIZE - 1]};
endmodule