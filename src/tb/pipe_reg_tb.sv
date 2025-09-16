`timescale 1ns/1ps

module pipe_reg_tb;

    parameter WIDTH = 8;
    logic clk;
    logic rst;
    logic write_en;
    logic flush;
    logic [WIDTH-1:0] d;
    logic [WIDTH-1:0] q;

    pipe_reg #(.WIDTH(WIDTH)) uut (
        .clk(clk),
        .rst(rst),
        .write_en(write_en),
        .flush(flush),
        .d(d),
        .q(q)
    );

    always #5 clk = ~clk;

    initial begin
        $display("==== PIPE_REG TESTBENCH STARTED ====");
        $monitor("Time: %0t | rst=%0b | flush=%0b | write_en=%0b | d=0x%0h | q=0x%0h",
                 $time, rst, flush, write_en, d, q);

        clk = 0;
        rst = 1;
        flush = 0;
        write_en = 0;
        d = 8'hAA;
        #10;

        // Release reset, enable write
        rst = 0;
        write_en = 1;
        d = 8'h55;
        #10;

        // Normal write
        d = 8'hF0;
        #10;

        // Flush (should zero out output regardless of d)
        flush = 1;
        d = 8'hCC;
        #10;

        // Flush off, normal write again
        flush = 0;
        d = 8'h3C;
        #10;

        // Disable write (should retain previous value)
        write_en = 0;
        d = 8'h99;
        #10;

        // Reset again
        rst = 1;
        #10;

        $display("==== PIPE_REG TESTBENCH FINISHED ====");
        $finish;
    end

endmodule