`timescale 1ns/1ps

module program_counter_tb;

    logic clk;
    logic rst;
    logic PCWrite;
    logic [31:0] pc_next;
    logic [31:0] pc_out;

    program_counter dut (
        .clk(clk),
        .rst(rst),
        .PCWrite(PCWrite),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    always #5 clk = ~clk;

    initial begin
        $display("=== Program Counter Test Start ===");
        clk = 0;
        rst = 1;
        PCWrite = 1;
        pc_next = 32'd0;

        #10 rst = 0;  

        pc_next = 32'd4;
        #10;
        pc_next = 32'd8;
        #10;

        // Disable write (simulate stall)
        PCWrite = 0;
        pc_next = 32'd12;
        #10;

        // Enable write again
        PCWrite = 1;
        pc_next = 32'd100;
        #10;

        // Reset and test again
        rst = 1;
        #10 rst = 0;

        pc_next = 32'd200;
        #10;

        $display("=== Program Counter Test End ===");
        $finish;
    end

    initial begin
        $monitor("Time: %0t | rst=%b | PCWrite=%b | pc_next=%0d | PC=%0d", $time, rst, PCWrite, pc_next, pc_out);
    end

endmodule