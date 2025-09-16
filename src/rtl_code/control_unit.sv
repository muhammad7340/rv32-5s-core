// -----------------------------------------------------------
// Module: control_unit
// Description: Control signal generator for RISC-V processor
// -----------------------------------------------------------

`timescale 1ns/1ps

module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    input  logic       equal,
    input  logic       lessThan,
    output logic       alu_src,
    output logic       ASel,
    output logic [3:0] alu_op,
    output logic       reg_write_en,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic [1:0] pc_src
);

    always_comb begin
        // Defaults
        alu_src      = 0;
        alu_op       = 4'b0000;
        reg_write_en = 0;
        mem_write    = 0;
        mem_to_reg   = 0;
        ASel         = 0;
        pc_src       = 2'b00; // Default: PC+4

        case (opcode)
            7'b0110011: begin // R-type
                alu_src      = 0;
                reg_write_en = 1;
                case ({funct7, funct3})
                    10'b0000000000: alu_op = 4'b0000; // add
                    10'b0100000000: alu_op = 4'b0001; // sub
                    10'b0000000001: alu_op = 4'b0010; // sll
                    10'b0000000010: alu_op = 4'b0011; // slt
                    10'b0000000011: alu_op = 4'b0100; // sltu
                    10'b0000000100: alu_op = 4'b0101; // xor
                    10'b0000000101: alu_op = 4'b0110; // srl
                    10'b0100000101: alu_op = 4'b0111; // sra
                    10'b0000000110: alu_op = 4'b1000; // or
                    10'b0000000111: alu_op = 4'b1001; // and
                    default: alu_op = 4'b1111;
                endcase
            end

            7'b0010011: begin // I-type ALU
                alu_src      = 1;
                reg_write_en = 1;
                case (funct3)
                    3'b000: alu_op = 4'b0000; // addi
                    3'b010: alu_op = 4'b0011; // slti
                    3'b011: alu_op = 4'b0100; // sltiu
                    3'b100: alu_op = 4'b0101; // xori
                    3'b101: alu_op = (funct7 == 7'b0100000) ? 4'b0111 : 4'b0110; // srai/srli
                    3'b110: alu_op = 4'b1000; // ori
                    3'b111: alu_op = 4'b1001; // andi
                    default: alu_op = 4'b1111;
                endcase
            end

            7'b0000011: begin // Load
                alu_src      = 1;
                reg_write_en = 1;
                mem_to_reg   = 1;
                alu_op       = 4'b0000;
            end

            7'b0100011: begin // Store
                alu_src    = 1;
                mem_write  = 1;
                alu_op     = 4'b0000;
            end

            7'b1101111: begin // JAL
                ASel         = 1;
                alu_src      = 1;
                reg_write_en = 1;
                alu_op       = 4'b0000;
                pc_src       = 2'b01;
            end

            7'b1100111: begin // JALR
                reg_write_en = 1;
                alu_src      = 1;
                alu_op       = 4'b0000;
                pc_src       = 2'b10;
            end

            7'b0110111: begin // LUI
                alu_src      = 1;
                reg_write_en = 1;
                alu_op       = 4'b0000;
            end

            7'b0010111: begin // AUIPC
                ASel         = 1;
                alu_src      = 1;
                reg_write_en = 1;
                alu_op       = 4'b0000;
            end

            7'b1100011: begin // Branch
                ASel    = 1'b1;       // ALU input A = PC
                alu_src = 1'b1;       // ALU input B = immediate
                alu_op  = 4'b0000;    // ADD: PC + immediate
                pc_src  = 2'b01;      // conditional branch
            end

            default: begin
                alu_op = 4'b1111;
                pc_src = 2'b00;
            end
        endcase
    end

endmodule