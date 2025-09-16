`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: nexys_top
// Description: This wrapper only has 18 I/O pins (1 clk + 1 reset + 16 LEDs)
//              instead of 132 TO meet Nexys A7's 16 Output LEDs requirements.
//////////////////////////////////////////////////////////////////////////////////


module nexys_top(
    input  logic clk,       // From the Nexys 100MHz oscillator
    input  logic reset,     // From a Nexys button
    output logic [15:0] led // To the 16 Nexys LEDs
);
    
    logic [31:0] alu_result;

    // Instantiate actual processor
    top core_inst (
        .clk(clk),
        .reset(reset),
        .alu_result_EX(alu_result)
    );

    // Only output the lower 16 bits of the ALU to the physical LEDs
    assign led = alu_result[15:0];

endmodule
