// ---------------------------------------------
// Module: top
// Description: Fully pipelined RISC-V processor 
// ---------------------------------------------

`timescale 1ns/1ps

module top (
    input  logic clk,
    input  logic reset,

    output logic [31:0] alu_result_EX,

    // Debugging Signal (we can turn them off as well.)
    // IF
    output logic [31:0] dbg_pc_IF,
    output logic [31:0] dbg_inst_IF,

    // ID
    output logic [31:0] dbg_pc_ID,
    output logic [31:0] dbg_inst_ID,

    // EX
    output logic [31:0] dbg_pc_EX,
    output logic [31:0] dbg_alu_result_EX,

    // MEM
    output logic [31:0] dbg_pc_MEM,
    output logic [31:0] dbg_alu_result_MEM,
    output logic        dbg_mem_write_MEM,

    // WB
    output logic [31:0] dbg_pc_WB,
    output logic [4:0]  dbg_rd_WB,
    output logic [31:0] dbg_write_data,
    output logic        dbg_reg_write_WB,

    // Branch/Jump Flush
    output logic        dbg_flush,
    output logic [1:0]  dbg_pc_sel,
    output logic [31:0] dbg_next_pc
);

    // --------------------------- PC Logic --------------------------
    logic [31:0] pc, next_pc, pc_plus4;
    assign pc_plus4 = pc + 32'd4;
    assign dbg_next_pc = next_pc;

    // ---------------------- Instruction Fetch ----------------------
    logic [31:0] instruction;
    inst_mem imem (
        .addr(pc), 
        .inst(instruction)
    );

    // ---------------------- IF/ID Pipeline Registers ----------------------
    logic IF_flush;
    logic [31:0] pc_ID, pc_IF;
    logic [31:0] inst_IF, inst_ID;

    logic IF_ID_Write;

    pipe_reg #(32) IF_ID_PC (.clk(clk), .rst(reset), .write_en(IF_ID_Write), .d(pc_IF), .q(pc_ID));
    pipe_reg #(32) IF_ID_INST (.clk(clk), .rst(reset), .write_en(IF_ID_Write), .flush(IF_flush), .d(inst_IF), .q(inst_ID));

    assign pc_IF = pc;
    assign inst_IF = instruction;
    assign dbg_inst_IF = inst_IF;

    // Debug Signal Assignments
    assign dbg_pc_IF   = pc_IF;    
    assign dbg_pc_ID   = pc_ID;
    assign dbg_inst_ID = inst_ID;

    assign dbg_flush           = IF_flush;

    // ---------------------- Instruction Decode ----------------------
    logic [6:0] opcode, funct7;
    logic [2:0] funct3;
    logic [4:0] rs1, rs2, rd;
    always_comb begin
        opcode = inst_ID[6:0];
        rd     = inst_ID[11:7];
        funct3 = inst_ID[14:12];
        rs1    = inst_ID[19:15];
        rs2    = inst_ID[24:20];
        funct7 = inst_ID[31:25];
    end

    // ---------------------- Register File ----------------------
    logic [31:0] reg_data1, reg_data2, write_data;
    logic [4:0]  rd_WB;
    reg_file rf (
        .clk(clk), .write_en(reg_write_en),
        .rs1(rs1), .rs2(rs2), .rsW(rd_WB),
        .write_data(write_data),
        .read_data1(reg_data1), .read_data2(reg_data2)
    );

    assign dbg_rd_WB          = rd_WB;
    assign dbg_write_data     = write_data;

    // ---------------------- Immediate Generation ----------------------
    logic [31:0] imm_out;
    imm_gen immgen (.instruction(inst_ID), .imm_out(imm_out));

    // ---------------------- Control Signals ----------------------
    logic alu_src_ID, ASel_ID, reg_write_en_ID, mem_write_ID, mem_to_reg_ID;
    logic [3:0] alu_op_ID;
    logic [1:0] pc_src_ID, pc_src_ID_mux;

    // ---------------------- Branch Comparator ----------------------
    logic BrEq, BrLt, BrUn;
    logic [31:0] alu_forwardA_in, alu_forwardB_in;
    logic jal_ID;

    assign jal_ID = (opcode == 7'b1101111);

    // Trigger unsigned math for BLTU (110) and BGEU (111) instructions
    assign BrUn = (opcode == 7'b1100011) && (funct3 == 3'b110 || funct3 == 3'b111);

    branch_comp bc (.a(alu_forwardA_in), .b(alu_forwardB_in), .BrUn(BrUn), .BrEq(BrEq), .BrLt(BrLt));

    // ---------------------- Control Unit ----------------------
    control_unit cu (
        .opcode(opcode), .funct3(funct3), .funct7(funct7),
        .equal(BrEq), .lessThan(BrLt),
        .alu_src(alu_src_ID), .ASel(ASel_ID), .alu_op(alu_op_ID),
        .reg_write_en(reg_write_en_ID), .mem_write(mem_write_ID),
        .mem_to_reg(mem_to_reg_ID), .pc_src(pc_src_ID)
    );

    //---------------------- control_mux_sel for NOP ----------------------
    logic control_mux_sel;
    logic alu_src_ID_mux, ASel_ID_mux, reg_write_en_ID_mux, mem_write_ID_mux, mem_to_reg_ID_mux;
    logic [3:0] alu_op_ID_mux;

    assign alu_src_ID_mux      = (control_mux_sel || IF_flush) ? 1'b0       : alu_src_ID;
    assign ASel_ID_mux         = (control_mux_sel || IF_flush) ? 1'b0       : ASel_ID;
    assign reg_write_en_ID_mux = (control_mux_sel || IF_flush) ? 1'b0       : reg_write_en_ID;
    assign mem_write_ID_mux    = (control_mux_sel || IF_flush) ? 1'b0       : mem_write_ID;
    assign mem_to_reg_ID_mux   = (control_mux_sel || IF_flush) ? 1'b0       : mem_to_reg_ID;
    assign alu_op_ID_mux       = (control_mux_sel || IF_flush) ? 4'b1111    : alu_op_ID;
    assign pc_src_ID_mux       = (control_mux_sel || IF_flush) ? 2'b00      : pc_src_ID;

    // ---------------------- ID/EX Pipeline Registers ----------------------
    logic [31:0] reg_data1_EX, reg_data2_EX, imm_EX;
    logic [4:0]  rs1_EX, rs2_EX, rd_EX;
    logic [31:0] pc_EX;
    logic [2:0] funct3_EX;
    
    pipe_reg #(5) ID_EX_Rs1 (.clk(clk), .rst(reset), .write_en(1'b1), .d(rs1), .q(rs1_EX));
    pipe_reg #(5) ID_EX_Rs2 (.clk(clk), .rst(reset), .write_en(1'b1), .d(rs2), .q(rs2_EX));

    logic alu_src_EX, a_sel_EX, reg_write_en_EX, mem_write_EX, mem_to_reg_EX;
    logic [3:0]  alu_op_EX;
    logic [1:0]  pc_src_EX;
    logic jal_EX;

    pipe_reg #(32) ID_EX_Reg1 (.clk(clk), .rst(reset), .write_en(1'b1), .d(reg_data1), .q(reg_data1_EX));
    pipe_reg #(32) ID_EX_Reg2 (.clk(clk), .rst(reset), .write_en(1'b1), .d(reg_data2), .q(reg_data2_EX));
    pipe_reg #(32) ID_EX_Imm  (.clk(clk), .rst(reset), .write_en(1'b1), .d(imm_out), .q(imm_EX));
    pipe_reg #(32) ID_EX_PC   (.clk(clk), .rst(reset), .write_en(1'b1), .d(pc_ID), .q(pc_EX));
    pipe_reg #(5)  ID_EX_Rd   (.clk(clk), .rst(reset), .write_en(1'b1), .d(rd), .q(rd_EX));

    pipe_reg #(1)  ID_EX_AluSrc (.clk(clk), .rst(reset), .write_en(1'b1), .d(alu_src_ID_mux), .q(alu_src_EX));
    pipe_reg #(1)  ID_EX_ASel   (.clk(clk), .rst(reset), .write_en(1'b1), .d(ASel_ID_mux), .q(a_sel_EX));
    pipe_reg #(1)  ID_EX_RegWEn (.clk(clk), .rst(reset), .write_en(1'b1), .d(reg_write_en_ID_mux), .q(reg_write_en_EX));
    pipe_reg #(1)  ID_EX_MemW   (.clk(clk), .rst(reset), .write_en(1'b1), .d(mem_write_ID_mux), .q(mem_write_EX));
    pipe_reg #(1)  ID_EX_Mem2Reg(.clk(clk), .rst(reset), .write_en(1'b1), .d(mem_to_reg_ID_mux), .q(mem_to_reg_EX));
    pipe_reg #(4)  ID_EX_ALUOp  (.clk(clk), .rst(reset), .write_en(1'b1), .d(alu_op_ID_mux), .q(alu_op_EX));
    pipe_reg #(2)  ID_EX_PCSrc  (.clk(clk), .rst(reset), .write_en(1'b1), .d(pc_src_ID_mux), .q(pc_src_EX));
    pipe_reg #(3)  ID_EX_Funct3 (.clk(clk), .rst(reset), .write_en(1'b1), .d(funct3), .q(funct3_EX));
    pipe_reg #(1) ID_EX_JAL  (.clk(clk), .rst(reset), .write_en(1'b1), .d(jal_ID), .q(jal_EX));

    assign dbg_pc_EX          = pc_EX;

    // ---------------------- Fowarding Logic ----------------------
    logic [1:0] forwardA, forwardB;
    logic [31:0] alu_result_MEM;
    logic [4:0] rd_MEM;
    logic        reg_write_en_MEM, reg_write_en_WB;


    fwd_logic forward_unit (
    .EX_MEM_RegWrite(reg_write_en_MEM), .EX_MEM_Rd(rd_MEM),
    .MEM_WB_RegWrite(reg_write_en_WB), .MEM_WB_Rd(rd_WB),
    .ID_EX_Rs1(rs1_EX), .ID_EX_Rs2(rs2_EX),
    .forwardA(forwardA), .forwardB(forwardB)
    );

    always_comb begin
        case (forwardA)
            2'b00: alu_forwardA_in = reg_data1_EX;
            2'b10: alu_forwardA_in = alu_result_MEM;
            2'b01: alu_forwardA_in = write_data;
            default: alu_forwardA_in = reg_data1_EX;
        endcase
        case (forwardB)
            2'b00: alu_forwardB_in = reg_data2_EX;
            2'b10: alu_forwardB_in = alu_result_MEM;
            2'b01: alu_forwardB_in = write_data;
            default: alu_forwardB_in = reg_data2_EX;
        endcase
    end

    assign dbg_alu_result_MEM = alu_result_MEM;
    assign dbg_reg_write_WB   = reg_write_en_WB;

    // ---------------------- ALU Stage ----------------------
    logic [31:0] alu_in1, alu_in2;
    assign alu_in1 = (a_sel_EX) ? pc_EX : alu_forwardA_in;
    assign alu_in2 = (alu_src_EX) ? imm_EX : alu_forwardB_in;
    assign dbg_alu_result_EX  = alu_result_EX;

    alu_logic alu (.op1(alu_in1), .op2(alu_in2), .alu_op(alu_op_EX), .result(alu_result_EX));

    logic [1:0] pc_branch_taken;
    logic ASel_EX;
    pipe_reg #(1) ID_EX_ASelReg (.clk(clk), .rst(reset), .write_en(1'b1), .d(ASel_ID_mux), .q(ASel_EX));

    always_comb begin
        pc_branch_taken = 2'b00; // default = PC+4

        // JAL
        if ((pc_src_EX == 2'b01) && ASel_EX) begin
            pc_branch_taken = 2'b01; 

        // Conditional Branches
        end else if (pc_src_EX == 2'b01) begin
            case (funct3_EX)
                3'b000: if (BrEq)        pc_branch_taken = 2'b01; // beq
                3'b001: if (!BrEq)       pc_branch_taken = 2'b01; // bne
                3'b100: if (BrLt)        pc_branch_taken = 2'b01; // blt
                3'b101: if (!BrLt)       pc_branch_taken = 2'b01; // bge
                3'b110: if (BrLt)        pc_branch_taken = 2'b01; // bltu
                3'b111: if (!BrLt)       pc_branch_taken = 2'b01; // bgeu
                default:                 pc_branch_taken = 2'b00; // default to PC+4
            endcase
        
        // JALR
        end else if (pc_src_EX == 2'b10) begin
            pc_branch_taken = 2'b10; 
        end
    end

    assign dbg_pc_sel          = pc_branch_taken;

    // ---------------------- EX/MEM Pipeline Registers ----------------------
    logic [31:0] reg_data2_MEM;
    logic        mem_write_MEM, mem_to_reg_MEM;
    logic [31:0] pc_MEM;
    logic jal_MEM;
    


    pipe_reg #(32) EX_MEM_ALURes  (.clk(clk), .rst(reset), .write_en(1'b1), .d(alu_result_EX),   .q(alu_result_MEM));
    pipe_reg #(32) EX_MEM_Reg2    (.clk(clk), .rst(reset), .write_en(1'b1), .d(alu_forwardB_in), .q(reg_data2_MEM));
    pipe_reg #(5)  EX_MEM_Rd      (.clk(clk), .rst(reset), .write_en(1'b1), .d(rd_EX),           .q(rd_MEM));
    pipe_reg #(1)  EX_MEM_RegWEn  (.clk(clk), .rst(reset), .write_en(1'b1), .d(reg_write_en_EX), .q(reg_write_en_MEM));
    pipe_reg #(1)  EX_MEM_MemW    (.clk(clk), .rst(reset), .write_en(1'b1), .d(mem_write_EX),    .q(mem_write_MEM));
    pipe_reg #(1)  EX_MEM_Mem2Reg (.clk(clk), .rst(reset), .write_en(1'b1), .d(mem_to_reg_EX),   .q(mem_to_reg_MEM));
    pipe_reg #(32) EX_MEM_PC      (.clk(clk), .rst(reset), .write_en(1'b1), .d(pc_EX),           .q(pc_MEM));
    pipe_reg #(1)  EX_MEM_JAL     (.clk(clk), .rst(reset), .write_en(1'b1), .d(jal_EX),          .q(jal_MEM));

    assign dbg_pc_MEM         = pc_MEM;
    assign dbg_mem_write_MEM  = mem_write_MEM;

    // ---------------------- Data Memory ----------------------
    logic [31:0] data_mem_out;
    logic [2:0] funct3_MEM;
    
    data_mem dmem (
        .clk(clk), .addr(alu_result_MEM), .dataW(reg_data2_MEM),
        .funct3(funct3_MEM), .MemRW(mem_write_MEM), .dataR(data_mem_out)
    );

    // ---------------------- MEM/WB Pipeline Registers ----------------------
    logic [31:0] alu_result_WB, data_mem_WB;
    logic  mem_to_reg_WB;
    logic [31:0] pc_WB;
    logic jal_WB;

    pipe_reg #(32) MEM_WB_ALURes  (.clk(clk), .rst(reset), .write_en(1'b1), .d(alu_result_MEM),   .q(alu_result_WB));
    pipe_reg #(32) MEM_WB_DataMem (.clk(clk), .rst(reset), .write_en(1'b1), .d(data_mem_out),     .q(data_mem_WB));
    pipe_reg #(5)  MEM_WB_Rd      (.clk(clk), .rst(reset), .write_en(1'b1), .d(rd_MEM),           .q(rd_WB));
    pipe_reg #(1)  MEM_WB_RegWEn  (.clk(clk), .rst(reset), .write_en(1'b1), .d(reg_write_en_MEM), .q(reg_write_en_WB));
    pipe_reg #(1)  MEM_WB_Mem2Reg (.clk(clk), .rst(reset), .write_en(1'b1), .d(mem_to_reg_MEM),   .q(mem_to_reg_WB));
    pipe_reg #(32) MEM_WB_PC      (.clk(clk), .rst(reset), .write_en(1'b1), .d(pc_MEM),           .q(pc_WB));
    pipe_reg #(3)  EX_MEM_Funct3  (.clk(clk), .rst(reset), .write_en(1'b1), .d(funct3_EX),        .q(funct3_MEM));
    pipe_reg #(1)  MEM_WB_JAL     (.clk(clk), .rst(reset), .write_en(1'b1), .d(jal_MEM),          .q(jal_WB));
    
    assign dbg_pc_WB          = pc_WB;

    // ---------------------- Writeback Mux ----------------------
    assign write_data = 
        jal_WB        ? (pc_WB + 32'd4) :
        mem_to_reg_WB ? data_mem_WB : 
                        alu_result_WB;

    // ---------------------- Final Register Write Control ----------------------
    assign reg_write_en = reg_write_en_WB;
    assign MemRW = mem_write_MEM;
    assign alu_result_out = alu_result_MEM;

    // ---------------------- Hazard Detection Unit ----------------------
    logic PCWrite;
    hazard_detection hd_unit (
        .ID_EX_MemRead(mem_to_reg_EX), .ID_EX_Rd(rd_EX),
        .IF_ID_Rs1(rs1), .IF_ID_Rs2(rs2),
        .PCWrite(PCWrite), .IF_ID_Write(IF_ID_Write), .control_mux_sel(control_mux_sel)
    );

    // ---------------------- PC Selection Mux ----------------------
    logic [31:0] jalr_target;
    assign jalr_target = (alu_in1 + imm_EX) & ~32'd1; 



    always_comb begin
        case (pc_branch_taken)
            2'b00: next_pc = pc_plus4;
            2'b01: next_pc = alu_result_EX;  // branch/jal target address= PC + imm 
            2'b10: next_pc = jalr_target;
            default: next_pc = 32'd0;
        endcase
    end

    // Flush if branch is taken
    assign IF_flush = (pc_branch_taken != 2'b00);
 

    // -------------------- Program Counter --------------------
    logic [31:0] pc_next, pc_out;
    program_counter pc_inst (
        .clk(clk), .rst(reset), .pc_next(pc_next), .pc_out(pc_out), .PCWrite(PCWrite)
    );

    assign pc = pc_out;
    assign pc_next = next_pc;

endmodule