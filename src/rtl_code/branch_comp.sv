// ----------------------------------------------------
// Module: branch_comp
// Description: Branch Comparator
// Notes: Implement the branch instructions
// ----------------------------------------------------

`timescale 1ns/1ps

module branch_comp (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic        BrUn,
    output logic        BrEq,
    output logic        BrLt
);

assign BrEq = (a==b);
assign BrLt = BrUn? (a < b) : ( $signed (a) < $signed (b) );

endmodule