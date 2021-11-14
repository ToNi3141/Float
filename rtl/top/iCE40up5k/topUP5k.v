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

// This top is just a test to get a rough idea how big the modules are and with what frequency they operatre
module top
(
    // Reset
    input  wire resetn_in,

    // Serial stream
    input  wire serial_mosi,
    // output wire serial_miso, not used right now
    input  wire serial_sck,
    input  wire serial_cs,
    output wire serial_cts,

    output wire P1B1 ,
    output wire P1B2 ,
    output wire P1B3 ,
    output wire P1B4 ,
    output wire P1B7 ,
    output wire P1B8 ,
    output wire P1B9 ,
    output wire P1B10,
    output wire P2_1 ,
    output wire P2_2 ,
    output wire P2_3 ,
    output wire P2_4 ,
    output wire P2_7 ,
    output wire P2_8 ,
    output wire P2_9 ,
    output wire P2_10
);
    wire clk;
    reg resetn;

    wire [31 : 0]   s_cmd_axis_tdata;
    wire            s_cmd_axis_tlast;
    reg             s_cmd_axis_tready = 1;
    wire            s_cmd_axis_tvalid;

    wire [18 : 0]   val;
    reg  [18 : 0]   valReg;

    assign {  P1B10, P1B9, P1B8, P1B7, P1B4, P1B3, P1B2, P1B1, 
                P2_10, P2_9, P2_8, P2_7, P2_4, P2_3, P2_2, P2_1} = valReg;

    ///////////////////////////
    // Clock Instantiation
    ///////////////////////////
    // Source = 48MHz, CLKHF_DIV = 2’b00 : 00 = div1, 01 = div2, 10 = div4, 11 = div8 ; Default = “00”
    SB_HFOSC #(.CLKHF_DIV("0b01")) osc (
        .CLKHFPU(1'b1),
        .CLKHFEN(1'b1),
        .CLKHF(clk)
    );

    Serial2AXIS serial2axis(
        .aclk(clk),
        .resetn(resetn),

        .serial_mosi(serial_mosi),
        // .serial_miso(serial_miso),
        .serial_miso(),
        .serial_sck(serial_sck),
        .serial_cs(serial_cs),
        .serial_cts(serial_cts),
        
        .m_axis_tvalid(s_cmd_axis_tvalid),
        .m_axis_tready(s_cmd_axis_tready),
        .m_axis_tlast(s_cmd_axis_tlast),
        .m_axis_tdata(s_cmd_axis_tdata)
    );

    FloatSub
    #(
        .MANTISSA_SIZE(10),
        .EXPONENT_SIZE(8),
        .ENABLE_OPTIMIZATION(1)
    )
    floatSub
    (
        .clk(clk),
        .aIn(s_cmd_axis_tdata[0 +: 19]),
        .bIn(valReg),
        .sum(val),
    );

    always @(posedge clk)
    begin
        valReg <= val;
        if (resetn_in)
        begin
            resetn <= 1;
        end
        else
        begin
            resetn <= 0;
        end
    end
endmodule