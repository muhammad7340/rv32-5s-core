`timescale 1ns/1ps

module top_tb;

    logic clk;
    logic reset;

    logic [31:0] alu_result_EX;

    // Debugging Signal (we can turn them off as well.)

    // IF
    logic [31:0] dbg_pc_IF;
    logic [31:0] dbg_inst_IF;

    // ID
    logic [31:0] dbg_pc_ID;
    logic [31:0] dbg_inst_ID;

    // EX
    logic [31:0] dbg_pc_EX;
    logic [31:0] dbg_alu_result_EX;

    // MEM
    logic [31:0] dbg_pc_MEM;
    logic [31:0] dbg_alu_result_MEM;
    logic        dbg_mem_write_MEM;
    
    // WB
    logic [31:0] dbg_pc_WB;
    logic [4:0]  dbg_rd_WB;
    logic [31:0] dbg_write_data;
    logic        dbg_reg_write_WB;

    // Branch/Jump Flush
    logic        dbg_flush;
    logic [1:0]  dbg_pc_sel;
    logic [31:0] dbg_next_pc;

    top uut (
        .clk(clk),
        .reset(reset),
        .alu_result_EX(alu_result_EX), // EX stage ALU result

        .dbg_pc_IF(dbg_pc_IF),
        .dbg_inst_IF(dbg_inst_IF),
        .dbg_pc_ID(dbg_pc_ID),
        .dbg_inst_ID(dbg_inst_ID),
        .dbg_pc_EX(dbg_pc_EX),
        .dbg_alu_result_EX(dbg_alu_result_EX),
        .dbg_pc_MEM(dbg_pc_MEM),
        .dbg_alu_result_MEM(dbg_alu_result_MEM),
        .dbg_mem_write_MEM(dbg_mem_write_MEM),
        .dbg_pc_WB(dbg_pc_WB),
        .dbg_rd_WB(dbg_rd_WB),
        .dbg_write_data(dbg_write_data),
        .dbg_reg_write_WB(dbg_reg_write_WB),
        .dbg_flush(dbg_flush),
        .dbg_pc_sel(dbg_pc_sel),
        .dbg_next_pc(dbg_next_pc)
    );

    integer cycle;
    initial clk = 0;
    always #5 clk = ~clk;  

    task automatic print_pipeline_state;
    begin

        $display("");
        $display("Cycle %03d | Time = %8.3f ns", cycle, $realtime);

        $display("+-------+------------+----------------------+----------+----------+");
        $display("| Stage | PC         | Main Value           | Dest     | Control  |");
        $display("+-------+------------+----------------------+----------+----------+");

        $display("| IF    | 0x%08h | Inst=0x%08h      | --       | --       |",
                dbg_pc_IF,
                dbg_inst_IF);

        $display("| ID    | 0x%08h | Inst=0x%08h      | --       | --       |",
                dbg_pc_ID,
                dbg_inst_ID);

        $display("| EX    | 0x%08h | ALU =0x%08h      | --       | --       |",
                dbg_pc_EX,
                dbg_alu_result_EX);

        $display("| MEM   | 0x%08h | ALU =0x%08h      | --       | MemW=%1b   |",
                dbg_pc_MEM,
                dbg_alu_result_MEM,
                dbg_mem_write_MEM);

        $display("| WB    | 0x%08h | Data=0x%08h      | x%02d      | RegW=%1b   |",
                dbg_pc_WB,
                dbg_write_data,
                dbg_rd_WB,
                dbg_reg_write_WB);

        $display("+-------+------------+----------------------+----------+----------+");

        $display("| Branch/Control : Flush=%1b | PCSel=%02b | NextPC=0x%08h         |",
                dbg_flush,
                dbg_pc_sel,
                dbg_next_pc);

        $display("+-----------------------------------------------------------------+");
    end
    endtask

    initial begin
        $display("=========== [TOP_TB] STARTED ===========");

        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);

        reset = 1'b1;
        cycle = 0;
        @(posedge clk);

        // Release reset safely between active clock edges
        @(negedge clk);
        reset = 1'b0;
        #1ps;

        // Cycle 000: first instruction is still in IF
        print_pipeline_state();

        repeat (39) begin
            @(posedge clk);
            #1ps;

            cycle = cycle + 1;
            print_pipeline_state();
        end
        $display("=========== [TOP_TB] FINISHED ===========");
        $finish;
    end
endmodule