`timescale 1ns/1ps

module branch_comp_tb;

    logic [31:0] a, b;
    logic        BrUn;
    logic        BrEq, BrLt;

    branch_comp dut (
        .a(a),
        .b(b),
        .BrUn(BrUn),
        .BrEq(BrEq),
        .BrLt(BrLt)
    );

    task run_test(input [31:0] a_in, input [31:0] b_in, input BrUn_in, 
                  input expected_BrEq, input expected_BrLt, input string label);
        begin
            a = a_in; b = b_in; BrUn = BrUn_in;
            #1;
            assert(BrEq == expected_BrEq && BrLt == expected_BrLt)
                else $fatal(" %s: Failed | BrEq = %0b (exp %0b), BrLt = %0b (exp %0b)", 
                            label, BrEq, expected_BrEq, BrLt, expected_BrLt);
            $display(" %s: Passed | BrEq = %0b, BrLt = %0b", label, BrEq, BrLt);
        end
    endtask

    initial begin
        $display("=== Branch Comparator Test Start ===");

        run_test(32'd10, 32'd10, 0, 1, 0, "Equal (signed)");
        run_test(-5,     3,     0, 0, 1, "Less than (signed)");
        run_test(10,    -20,    0, 0, 0, "Greater than (signed)");
        run_test(32'h00000001, 32'hFFFFFFFF, 1, 0, 1, "Less than (unsigned)");
        run_test(32'hFFFFFFFE, 32'h00000001, 1, 0, 0, "Greater than (unsigned)");
        run_test(32'hFFFFFFFF, 32'hFFFFFFFF, 1, 1, 0, "Equal (unsigned)");

        $display("=== Branch Comparator Test Complete ===");
        $finish;
    end

endmodule