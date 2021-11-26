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

// Float to signed integer conversion
// This module is pipelined. It can calculate one conversion per clock
// This module has a latency of 4 clock cycles
module FloatToInt 
# (
    parameter MANTISSA_SIZE = 23,
    parameter EXPONENT_SIZE = 8,

    // Has to be at least the size of the mantissa plus the hidden bit and plus sign. 
    // In other words: MANTISSA_SIZE + 2.
    parameter INT_SIZE = 32, 

    // This value can be used to shift the bias of the exponent in the float. 
    // This conversion can be useful when converting to a fix point format without any extra cost.
    // For instance a EXPONENT_BIAS_OFFSET of -1 is equal to a multiplication with 2.0,
    // a EXPONENT_BIAS_OFFSET of -2 is equal to a multiplication with 4.0, ...
    parameter EXPONENT_BIAS_OFFSET = 0,

    localparam FLOAT_SIZE = 1 + EXPONENT_SIZE + MANTISSA_SIZE
)
(
    input  wire                         clk,
    input  wire [FLOAT_SIZE - 1 : 0]    in,
    output reg  [INT_SIZE - 1 : 0]      out
);
    localparam UNSIGNED_INT_SIZE = INT_SIZE - 1;
    localparam INT_SIGN_POS = INT_SIZE - 1;
    localparam USNIGNED_INT_SIZE_LOG2 = $clog2(UNSIGNED_INT_SIZE);
    localparam MANTISSA_POS = 0;
    localparam EXPONENT_POS = MANTISSA_SIZE;
    localparam SIGN_POS = EXPONENT_POS + EXPONENT_SIZE;
    localparam EXPONENT_SIGNED_SIZE = EXPONENT_SIZE + 1;
    localparam EXPONENT_BIAS = ((2 ** (EXPONENT_SIZE - 1)) - 1) + EXPONENT_BIAS_OFFSET;

    reg  [INT_SIZE - 1 : 0]             one_number;
    reg                                 one_sign;
    reg                                 one_overflow;
    reg                                 one_underflow;
    reg                                 one_shiftLeft;    
    reg  [USNIGNED_INT_SIZE_LOG2 - 1 : 0] one_shiftSize;
    always @(posedge clk)
    begin : Unpack
        reg signed [EXPONENT_SIGNED_SIZE - 1 : 0] exponent;
        reg signed [EXPONENT_SIGNED_SIZE - 1 : 0] shiftSize;

        one_sign <= in[SIGN_POS +: 1];
        exponent = in[EXPONENT_POS +: EXPONENT_SIZE] - EXPONENT_BIAS;

        // A float in the range of an integer will always have set the hidden bit to one since we can't display fractions with an integer
        one_number <= {{(INT_SIZE - MANTISSA_SIZE - 1){1'b0}}, 1'b1, in[MANTISSA_POS +: MANTISSA_SIZE]};

        one_shiftLeft = exponent > MANTISSA_SIZE;
        if (one_shiftLeft)
        begin
            shiftSize = exponent - MANTISSA_SIZE[0 +: EXPONENT_SIGNED_SIZE];
        end
        else
        begin
            shiftSize = MANTISSA_SIZE[0 +: EXPONENT_SIGNED_SIZE] - exponent;
        end
        one_shiftSize <= shiftSize[0 +: USNIGNED_INT_SIZE_LOG2];

        one_overflow <= exponent >= (INT_SIZE - 1); // Substracting sign bit
        one_underflow <= exponent < 0;
    end

    reg  [INT_SIZE - 1 : 0]     two_number;
    reg                         two_sign;
    reg                         two_overflow;
    reg                         two_underflow;
    reg                         two_round;
    always @(posedge clk)
    begin
        if (one_shiftLeft)
        begin
            two_round <= 0;
            two_number <= one_number << one_shiftSize;
        end
        else 
        begin
            two_round <= one_number[one_shiftSize - 1];
            two_number <= one_number >> one_shiftSize;
        end
        two_sign <= one_sign;
        two_overflow <= one_overflow;
        two_underflow <= one_underflow;
    end

    reg                     three_underflow;
    reg                     three_overflow;
    reg                     three_sign;
    reg  [INT_SIZE - 1 : 0] three_number;
    always @(posedge clk)
    begin
        // Reevaluate underflow
        if (two_underflow)
        begin
            // If we where able to round, then the last value was bigger than 0.5. Therefor we can round now.
            if (two_round)
            begin
                three_underflow <= 0;
                three_number <= 1; 
            end
            else
            begin
                three_underflow <= 1;
                three_number <= 0; 
            end
        end
        else 
        begin
            three_underflow <= two_underflow;
            three_number <= two_number + {{(INT_SIZE - 1){1'b0}}, two_round};
        end
        three_overflow <= two_overflow;
        three_sign <= two_sign;
    end

    always @(posedge clk) 
    begin
        if (three_overflow)
        begin
            out <= 0;
        end
        else
        begin
            if (three_sign)
            begin
                out <= ~three_number + 1;
            end
            else
            begin
                out <= three_number;
            end
        end
    end

endmodule