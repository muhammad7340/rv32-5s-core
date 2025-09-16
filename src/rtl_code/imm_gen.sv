// -------------------------------------------------------------------
// Module: imm_gen
// Description: Immediate generator for I-type, B-Type and J-type instructions
// Notes: Supports I-type (e.g., addi, jalr), B-Type  and J-type (e.g., jal)
// -------------------------------------------------------------------

`timescale 1ns/1ps

module imm_gen (
    input  logic [31:0] instruction,  
    output logic [31:0] imm_out       
);

    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    always_comb begin
        case (opcode)
            7'b1101111: begin // J-Type (JAL)
                imm_out = {{12{instruction[31]}},
                           instruction[19:12],
                           instruction[20],
                           instruction[30:21],
                           1'b0};
            end

            7'b1100011: begin // B-Type (Branches)
                imm_out = {{19{instruction[31]}},
                           instruction[31],
                           instruction[7],
                           instruction[30:25],
                           instruction[11:8],
                           1'b0};
            end
            
            7'b0100011: begin // S-Type (Stores)
                imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end

            7'b0110111, // LUI
            7'b0010111: begin // AUIPC (U-Type)
                imm_out = {instruction[31:12], 12'b0};
            end

            7'b1100111, // JALR
            7'b0000011, // Loads
            7'b0010011: begin // I-Type ALU
                imm_out = {{20{instruction[31]}}, instruction[31:20]};
            end

            default: imm_out = 32'd0;
        endcase
    end

endmodule