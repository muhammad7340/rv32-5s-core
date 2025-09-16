// -----------------------------------------------------------
// Module: pipe_reg
// Description: Parametric pipeline register for pipelined RISC-V datapath
// -----------------------------------------------------------

`timescale 1ns/1ps

module pipe_reg #(
    parameter WIDTH = 32
)(
    input logic clk,
    input logic rst,
    input logic write_en,
    input logic flush,                   
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

    always_ff @(posedge clk) begin
        if (rst)
            q <= '0;
        else if (flush)  // If flush is active, insert NOP
            q <= '0;
        else if (write_en)
            q <= d;
    end

endmodule