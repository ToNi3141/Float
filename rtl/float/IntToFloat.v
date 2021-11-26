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

// Signed integer to float conversion
// This module is pipelined. It can calculate one conversion per clock
// This module has a latency of 4 clock cycles
module IntToFloat 
# (
    parameter MANTISSA_SIZE = 23,
    parameter EXPONENT_SIZE = 8,

    // Has to be at least the size of the mantissa plus the hidden bit and plus sign. 
    // In other words: MANTISSA_SIZE + 2.
    parameter INT_SIZE = 32, 

    localparam FLOAT_SIZE = 1 + EXPONENT_SIZE + MANTISSA_SIZE
)
(
    input  wire                         clk,
    input  wire [INT_SIZE - 1 : 0]      in,
    output reg  [FLOAT_SIZE - 1 : 0]    out
);
    localparam SIGN_POS = MANTISSA_SIZE + EXPONENT_SIZE;
    localparam UNSIGNED_INT_SIZE = INT_SIZE - 1;
    localparam INT_SIGN_POS = INT_SIZE - 1;
    localparam [EXPONENT_SIZE - 1 : 0] EXPONENT_BIAS = (2 ** (EXPONENT_SIZE - 1)) - 1;
    localparam USNIGNED_INT_SIZE_LOG2 = $clog2(UNSIGNED_INT_SIZE);

    wire [EXPONENT_SIZE - 1 : 0] exponent;
    FindExponent #(.EXPONENT_SIZE(EXPONENT_SIZE), .VALUE_SIZE(UNSIGNED_INT_SIZE)) findExponent (one_number, exponent);

    reg  [UNSIGNED_INT_SIZE - 1 : 0]    one_number;
    reg                                 one_sign;
    always @(posedge clk)
    begin : Prepare
        reg [INT_SIZE - 1 : 0] numberUnsigned;
        numberUnsigned = ~in + 1;
        if ($signed(in) < 0)
        begin
            one_number <= numberUnsigned[0 +: UNSIGNED_INT_SIZE];
        end
        else 
        begin
            one_number <= in[0 +: UNSIGNED_INT_SIZE];
        end
        one_sign <= in[INT_SIGN_POS];
    end

    reg  [EXPONENT_SIZE - 1 : 0]        two_exponent;
    reg                                 two_sign;
    reg  [UNSIGNED_INT_SIZE - 1 : 0]    two_number;
    always @(posedge clk)
    begin
        two_exponent <= exponent;
        two_sign <= one_sign;
        two_number <= one_number;
    end

    reg                                 three_mantissaOverflow;
    reg                                 three_shiftLeft;    
    reg  [USNIGNED_INT_SIZE_LOG2 - 1 : 0] three_shiftSize;
    reg  [EXPONENT_SIZE - 1 : 0]        three_exponent;
    reg                                 three_sign;
    reg  [UNSIGNED_INT_SIZE - 1 : 0]    three_number;
    always @(posedge clk)
    begin : PreparePack
        reg [UNSIGNED_INT_SIZE - 1 : 0] tmp;

        three_mantissaOverflow = two_number[two_exponent[0 +: USNIGNED_INT_SIZE_LOG2] - MANTISSA_SIZE[0 +: USNIGNED_INT_SIZE_LOG2] - 1];
        three_shiftLeft = two_exponent < MANTISSA_SIZE[0 +: EXPONENT_SIZE];
        if (two_number == 0)
        begin
            three_number <= 0;
            three_exponent <= 0;
        end
        else if (three_shiftLeft)
        begin
            three_shiftSize <= MANTISSA_SIZE[0 +: USNIGNED_INT_SIZE_LOG2] - two_exponent[0 +: USNIGNED_INT_SIZE_LOG2];
            three_number <= two_number;
            three_exponent <= two_exponent + EXPONENT_BIAS;
        end
        else
        begin
            three_shiftSize <= ((two_exponent[0 +: USNIGNED_INT_SIZE_LOG2] + {{(USNIGNED_INT_SIZE_LOG2 - 1){1'b0}}, three_mantissaOverflow}) - MANTISSA_SIZE[0 +: USNIGNED_INT_SIZE_LOG2]);
            three_number <= two_number;
            three_exponent <= two_exponent + EXPONENT_BIAS + {{(EXPONENT_SIZE - 1){1'b0}}, three_mantissaOverflow};
        end

        three_sign <= two_sign;
    end

    always @(posedge clk)
    begin : Pack
        reg [UNSIGNED_INT_SIZE - 1 : 0] tmp;

        if (three_shiftLeft)
        begin
            tmp = three_number << three_shiftSize;
        end
        else
        begin
            tmp = three_number >> three_shiftSize;
        end
        out <= {three_sign, three_exponent, tmp[0 +: MANTISSA_SIZE] + {{(MANTISSA_SIZE - 1){1'b0}}, three_mantissaOverflow}};
    end
endmodule