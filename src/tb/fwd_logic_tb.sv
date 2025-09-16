module fwd_logic_tb;

    logic        EX_MEM_RegWrite;
    logic [4:0]  EX_MEM_Rd;
    logic        MEM_WB_RegWrite;
    logic [4:0]  MEM_WB_Rd;
    logic [4:0]  ID_EX_Rs1;
    logic [4:0]  ID_EX_Rs2;

    logic [1:0]  forwardA;
    logic [1:0]  forwardB;

    fwd_logic dut (
        .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .EX_MEM_Rd(EX_MEM_Rd),
        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .MEM_WB_Rd(MEM_WB_Rd),
        .ID_EX_Rs1(ID_EX_Rs1),
        .ID_EX_Rs2(ID_EX_Rs2),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );

    task run_test(
        input logic [4:0] ex_mem_rd,
        input logic       ex_mem_we,
        input logic [4:0] mem_wb_rd,
        input logic       mem_wb_we,
        input logic [4:0] rs1,
        input logic [4:0] rs2
    );
        begin
            EX_MEM_Rd       = ex_mem_rd;
            EX_MEM_RegWrite = ex_mem_we;
            MEM_WB_Rd       = mem_wb_rd;
            MEM_WB_RegWrite = mem_wb_we;
            ID_EX_Rs1       = rs1;
            ID_EX_Rs2       = rs2;

            #1;

            $display("EX_MEM: RegWrite=%0b Rd=%0d | MEM_WB: RegWrite=%0b Rd=%0d | ID_EX: Rs1=%0d Rs2=%0d => forwardA=%b forwardB=%b",
                ex_mem_we, ex_mem_rd, mem_wb_we, mem_wb_rd, rs1, rs2, forwardA, forwardB);
        end
    endtask

    initial begin
        $display("=== Forwarding Logic Testbench ===");

        run_test(5'd10, 1, 5'd0, 0, 5'd10, 5'd0);   
        run_test(5'd0,  0, 5'd11, 1, 5'd11, 5'd0);  
        run_test(5'd10, 1, 5'd11, 1, 5'd11, 5'd10); // ForwardA from EX_MEM (takes priority as we have learnt this), ForwardB from MEM_WB
        run_test(5'd12, 1, 5'd12, 1, 5'd0,  5'd12); 
        run_test(5'd12, 0, 5'd12, 1, 5'd0,  5'd12); 
        run_test(5'd0,  0, 5'd0,  0, 5'd5,  5'd6);  // No forwarding

        $finish;
    end

endmodule