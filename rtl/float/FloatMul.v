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

// Floating point multiplication
// This module is pipelined. It can calculate one multiplication per clock
// This module has a latency of 4 clock cycles
module FloatMul
# (
    parameter MANTISSA_SIZE = 23,
    parameter EXPONENT_SIZE = 8,
    localparam FLOAT_SIZE = 1 + EXPONENT_SIZE + MANTISSA_SIZE
)
(
    input  wire                      clk,
    input  wire [FLOAT_SIZE - 1 : 0] facAIn,
    input  wire [FLOAT_SIZE - 1 : 0] facBIn,
    output reg  [FLOAT_SIZE - 1 : 0] prod
);
    localparam MANTISSA_POS = 0;
    localparam EXPONENT_POS = MANTISSA_SIZE;
    localparam SIGN_POS = EXPONENT_POS + EXPONENT_SIZE;

    localparam EXPONENT_BIAS = (2 ** (EXPONENT_SIZE - 1)) - 1;
    localparam EXPONENT_INF = (2 ** EXPONENT_SIZE) - 1;

    localparam MANTISSA_CALC_SIZE = MANTISSA_SIZE + 1; // Add hidden bit
    localparam MANTISSA_PROD_SIZE = MANTISSA_CALC_SIZE * 2;
    localparam EXPONENT_SUM_ADDITIONAL_BITS = 1 + 1; // Add one bit for sign and one for overflow
    localparam EXPONENT_SUM_SIZE = EXPONENT_SIZE + EXPONENT_SUM_ADDITIONAL_BITS; 

    reg                               one_facASign;
    reg                               one_facBSign;
    reg  [EXPONENT_SUM_SIZE - 1 : 0]  one_facAExponent;
    reg  [EXPONENT_SUM_SIZE - 1 : 0]  one_facBExponent;
    reg  [MANTISSA_CALC_SIZE - 1 : 0] one_facAMantissa;
    reg  [MANTISSA_CALC_SIZE - 1 : 0] one_facBMantissa;
    reg  [MANTISSA_CALC_SIZE - 1 : 0] one_facBMantissaDenormalized;
    always @(posedge clk)
    begin : UnpackAndAdapt
        reg  [FLOAT_SIZE - 1 : 0] facA;
        reg  [FLOAT_SIZE - 1 : 0] facB;
        reg                       expFacBGreaterThanZero;
        reg                       expFacAGreaterThanZero;
        reg  [MANTISSA_CALC_SIZE - 1 : 0] facAMantissa;
        reg  [MANTISSA_CALC_SIZE - 1 : 0] facBMantissa;

        facA = facBIn;
        facB = facAIn;

        one_facAExponent = {{EXPONENT_SUM_ADDITIONAL_BITS{1'b0}}, facA[EXPONENT_POS +: EXPONENT_SIZE]};
        one_facBExponent = {{EXPONENT_SUM_ADDITIONAL_BITS{1'b0}}, facB[EXPONENT_POS +: EXPONENT_SIZE]};

        expFacBGreaterThanZero = one_facBExponent > 0;
        expFacAGreaterThanZero = one_facAExponent > 0;

        facAMantissa = {expFacAGreaterThanZero, facA[MANTISSA_POS +: MANTISSA_SIZE]};
        facBMantissa = {expFacBGreaterThanZero, facB[MANTISSA_POS +: MANTISSA_SIZE]};
        one_facASign <= facA[SIGN_POS];
        one_facBSign <= facB[SIGN_POS];

        one_facAMantissa <= facAMantissa;
        one_facBMantissa <= facBMantissa;
    end

    reg  [MANTISSA_PROD_SIZE - 1 : 0] two_mantissaProd;
    reg                               two_mantissaProdSign;
    reg  [EXPONENT_SIZE - 1 : 0]      two_facAExponent;
    reg  [EXPONENT_SIZE - 1 : 0]      two_facBExponent;
    reg  [EXPONENT_SIZE - 1 : 0]      two_exponentSum;
    reg                               two_exponentUnderflow;
    reg                               two_exponentOverflow;
    always @(posedge clk)
    begin : Calc
        reg signed [EXPONENT_SUM_SIZE - 1 : 0]  sumExponent;

        // Calculate the mantissa product
        two_mantissaProd <= one_facBMantissa * one_facAMantissa;

        // Calculate the exponent
        sumExponent = $signed(one_facBExponent) + ($signed(one_facAExponent) - EXPONENT_BIAS);
        
        // Clamp the exponent
        if ((sumExponent < 0) || (one_facBMantissa == 0) || (one_facAMantissa == 0))
        begin
            two_exponentUnderflow <= 1;
            two_exponentOverflow <= 0;
            two_exponentSum <= 0;
        end
        else if (sumExponent >= EXPONENT_INF)
        begin
            two_exponentUnderflow <= 0;
            two_exponentOverflow <= 1;
            two_exponentSum <= EXPONENT_INF;
        end
        else 
        begin
            two_exponentUnderflow <= 0;
            two_exponentOverflow <= 0;
            two_exponentSum <= sumExponent[0 +: EXPONENT_SIZE];
        end

        // Safe the sign of the product
        two_mantissaProdSign <= one_facASign ^ one_facBSign;

        two_facAExponent <= one_facAExponent[0 +: EXPONENT_SIZE];
        two_facBExponent <= one_facBExponent[0 +: EXPONENT_SIZE];
    end
    
    // Bubble cylce to add one clock latency. 
    // Reason: I want to have the same amout of latency in the multiplication like i have in the addition
    reg  [EXPONENT_SIZE - 1 : 0]      three_facAExponent;
    reg  [EXPONENT_SIZE - 1 : 0]      three_facBExponent;
    reg  [MANTISSA_PROD_SIZE - 1 : 0] three_prodMantissa;
    reg                               three_prodMantissaSign;
    reg  [EXPONENT_SIZE - 1 : 0]      three_exponentSum;
    reg                               three_exponentUnderflow;
    reg                               three_exponentOverflow;
    always @(posedge clk)
    begin
        three_facAExponent <= two_facAExponent;
        three_facBExponent <= two_facBExponent;
        three_prodMantissa <= two_mantissaProd;
        three_prodMantissaSign <= two_mantissaProdSign;
        three_exponentSum <= two_exponentSum;
        three_exponentUnderflow <= two_exponentUnderflow;
        three_exponentOverflow <= two_exponentOverflow;
    end

    always @(posedge clk)
    begin : Pack
        reg  [EXPONENT_SIZE - 1 : 0] exponentSum;
        reg  [EXPONENT_SIZE : 0]     exponentSumTmp;
        reg  [MANTISSA_SIZE - 1 : 0] mantissaNormalized;
        reg                          normalizationRequired;
        reg                          mantissaOverlow;

        normalizationRequired = (three_facAExponent != 0) || (three_facBExponent != 0);
        mantissaOverlow = three_prodMantissa[(MANTISSA_SIZE * 2) + 1];

        // Check if the exponent underflows (for instance when you multiply two numbers where the result is too small to encode)
        if (three_exponentUnderflow)
        begin
            exponentSum = 0;
            mantissaNormalized = 0;
        end
        // Check if the exponent overflows (for instance when you multiply two numbers where the result is too big to encode)
        else if (three_exponentOverflow)
        begin
            exponentSum = EXPONENT_INF;
            mantissaNormalized = 0;
        end
        else 
        begin
            // Check if the mantissa is too big so the mantissa has to be shifted.
            // If so, we have to add each step, we shift the mantissa, to the exponent
            if (normalizationRequired)
            begin
                // Standard case where we have a normalized mantissa. In this case we can just use the calculated sum.
                exponentSumTmp = three_exponentSum + {{EXPONENT_SIZE{1'b0}}, mantissaOverlow};
            end
            else
            begin
                // Set exponent to zero because the mantissa is not big enough for a shift. This also implies that the exponent where already zero. Otherwise this case wouldn't happen
                exponentSumTmp = 0;
            end

            exponentSum = exponentSumTmp[0 +: EXPONENT_SIZE];

            // Check if we have to normalize the mantissa
            if (exponentSumTmp == EXPONENT_INF)
            begin
                mantissaNormalized = 0;
            end
            else if (normalizationRequired)
            begin
                mantissaNormalized = {(three_prodMantissa >> ({{(MANTISSA_PROD_SIZE - MANTISSA_SIZE){1'b0}}, MANTISSA_SIZE[0 +: MANTISSA_SIZE]} 
                                                                 + {{(MANTISSA_PROD_SIZE - 1){1'b0}}, mantissaOverlow}))}[0 +: MANTISSA_SIZE];
            end
            else 
            begin
                mantissaNormalized = three_prodMantissa[0 +: MANTISSA_SIZE];
            end
        end

        prod <= {three_prodMantissaSign, exponentSum, mantissaNormalized};
    end
endmodule
