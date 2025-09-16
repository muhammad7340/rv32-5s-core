module hazard_detection_tb;

    logic        ID_EX_MemRead;
    logic [4:0]  ID_EX_Rd;
    logic [4:0]  IF_ID_Rs1;
    logic [4:0]  IF_ID_Rs2;

    logic        PCWrite;
    logic        IF_ID_Write;
    logic        control_mux_sel;

    hazard_detection dut (
        .ID_EX_MemRead(ID_EX_MemRead),
        .ID_EX_Rd(ID_EX_Rd),
        .IF_ID_Rs1(IF_ID_Rs1),
        .IF_ID_Rs2(IF_ID_Rs2),
        .PCWrite(PCWrite),
        .IF_ID_Write(IF_ID_Write),
        .control_mux_sel(control_mux_sel)
    );

    task run_test(
        input logic       memRead,
        input logic [4:0] rd,
        input logic [4:0] rs1,
        input logic [4:0] rs2
    );
        begin
            ID_EX_MemRead = memRead;
            ID_EX_Rd      = rd;
            IF_ID_Rs1     = rs1;
            IF_ID_Rs2     = rs2;

            #1;

            $display("MemRead=%0b, Rd=%0d, Rs1=%0d, Rs2=%0d => PCWrite=%0b, IF_ID_Write=%0b, ControlMuxSel=%0b",
                     memRead, rd, rs1, rs2, PCWrite, IF_ID_Write, control_mux_sel);
        end
    endtask

    initial begin
        $display("=== Hazard Detection Testbench ===");

        // Hazard on Rs1
        run_test(1'b1, 5'd10, 5'd10, 5'd0); 

        // Hazard on Rs2
        run_test(1'b1, 5'd5, 5'd0, 5'd5);   

        // No hazard (rd != rs1/rs2)
        run_test(1'b1, 5'd3, 5'd1, 5'd2);   

        // MemRead is 0 (even if rd matches)
        run_test(1'b0, 5'd2, 5'd2, 5'd0);   

        // Rd = x0 (no hazard should be detected)
        run_test(1'b1, 5'd0, 5'd0, 5'd0);

        $finish;
    end

endmodule