// -----------------------------------------------------------
// Module: hazard_detection
// Description: Detects load-use hazards and generates stall signals
// -----------------------------------------------------------

`timescale 1ns/1ps

module hazard_detection (
    input  logic        ID_EX_MemRead,
    input  logic [4:0]  ID_EX_Rd,
    input  logic [4:0]  IF_ID_Rs1,
    input  logic [4:0]  IF_ID_Rs2,

    output logic        PCWrite,
    output logic        IF_ID_Write,
    output logic        control_mux_sel
);

    always_comb begin
        PCWrite         = 1;
        IF_ID_Write     = 1;
        control_mux_sel = 0;

        // 3 Functions will be performed after the Hazard detetction
        if (ID_EX_MemRead &&
           ((ID_EX_Rd == IF_ID_Rs1) || (ID_EX_Rd == IF_ID_Rs2)) &&
           (ID_EX_Rd != 0)) begin   
            PCWrite         = 0;
            IF_ID_Write     = 0;
            control_mux_sel = 1;
        end
    end
endmodule