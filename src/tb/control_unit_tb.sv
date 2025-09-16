`timescale 1ns / 1ps

module control_unit_tb;

    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic        equal;
    logic        lessThan;
    logic        alu_src;
    logic        ASel;
    logic [3:0]  alu_op;
    logic        reg_write_en;
    logic        mem_write;
    logic        mem_to_reg;
    logic [1:0]  pc_src;

    control_unit dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .equal(equal),
        .lessThan(lessThan),
        .alu_src(alu_src),
        .ASel(ASel),
        .alu_op(alu_op),
        .reg_write_en(reg_write_en),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .pc_src(pc_src)
    );

    task print_signals(string label);
        $display("[%s] alu_src=%b ASel=%b alu_op=%b reg_wr=%b mem_wr=%b mem2reg=%b pc_src=%b",
                  label, alu_src, ASel, alu_op, reg_write_en, mem_write, mem_to_reg, pc_src);
    endtask

    initial begin
        $display("=== CONTROL UNIT TEST START ===");

        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0000000; equal = 0; lessThan = 0;
        #5; print_signals("R-type ADD");

        funct7 = 7'b0100000;
        #5; print_signals("R-type SUB");

        opcode = 7'b0010011; funct3 = 3'b000; funct7 = 7'b0000000;
        #5; print_signals("I-type ADDI");

        funct3 = 3'b101; funct7 = 7'b0100000;
        #5; print_signals("I-type SRAI");

        opcode = 7'b0000011; funct3 = 3'b010;
        #5; print_signals("I-type LW");

        opcode = 7'b0100011;
        #5; print_signals("S-type SW");

        opcode = 7'b1100011; funct3 = 3'b000; equal = 1; lessThan = 0;
        #5; print_signals("B-type BEQ");

        funct3 = 3'b001; equal = 0;
        #5; print_signals("B-type BNE");

        funct3 = 3'b100; equal = 0; lessThan = 1;
        #5; print_signals("B-type BLT");

        opcode = 7'b1101111;
        #5; print_signals("J-type JAL");

        opcode = 7'b1100111;
        #5; print_signals("I-type JALR");

        opcode = 7'b0110111;
        #5; print_signals("U-type LUI");

        opcode = 7'b0010111;
        #5; print_signals("U-type AUIPC");

        $display("=== CONTROL UNIT TEST COMPLETE ===");
        $finish;
    end

endmodule
