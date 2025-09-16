// -----------------------------------------------------------
// Module: fwd_logic
// Description: Forwarding for data hazard
// -----------------------------------------------------------

`timescale 1ns/1ps

module fwd_logic (
    input  logic        EX_MEM_RegWrite,
    input  logic [4:0]  EX_MEM_Rd,
    input  logic        MEM_WB_RegWrite,
    input  logic [4:0]  MEM_WB_Rd,
    input  logic [4:0]  ID_EX_Rs1,
    input  logic [4:0]  ID_EX_Rs2,

    output logic [1:0]  forwardA,
    output logic [1:0]  forwardB
);

    always_comb begin
        forwardA = 2'b00;
        forwardB = 2'b00;

        if (EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs1)) 
            forwardA = 2'b10;
        else if (MEM_WB_RegWrite && (MEM_WB_Rd != 0) &&
                 !(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs1)) &&
                 (MEM_WB_Rd == ID_EX_Rs1))
            forwardA = 2'b01;

        if (EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs2))
            forwardB = 2'b10;
        else if (MEM_WB_RegWrite && (MEM_WB_Rd != 0) &&
                 !(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs2)) &&
                 (MEM_WB_Rd == ID_EX_Rs2))
            forwardB = 2'b01;

        // Prevent forwarding for x0 
        if (ID_EX_Rs1 == 5'd0)
            forwardA = 2'b00;
        if (ID_EX_Rs2 == 5'd0)
            forwardB = 2'b00;
    end

endmodule