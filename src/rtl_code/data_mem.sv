// ---------------------------------------------------------------
// Module: data_mem
// Description: Support S and I type (load and store instructions)
// Notes: For store and load instructions
// ---------------------------------------------------------------

`timescale 1ns/1ps

module data_mem (
    input  logic        clk,
    input  logic [31:0] addr,      
    input  logic [31:0] dataW,     
    input  logic [2:0]  funct3,    
    input  logic        MemRW,     
    output logic [31:0] dataR
);

    logic [31:0] memory [0:511];  // 2KB of RAM (512 x 32-bit words)
    logic [31:0] word_addr;
    assign word_addr = addr[31:2];  
    logic [31:0] word_data;

    assign word_data = (word_addr < 512) ? memory[word_addr] : 32'd0;

    // (load) Combinational read
    always_comb begin
        dataR = 32'd0;
        if (^addr === 1'bx || ^funct3 === 1'bx || word_addr >= 512) begin
            dataR = 32'd0;
            $display("[DMEM][%0t ns] Skipped read: addr = %h", $time, addr, funct3);
        end else begin
            case (funct3)            
                3'b000: begin // lb
                    case (addr[1:0])
                        2'b00: dataR = {{24{word_data[7]}},  word_data[7:0]};
                        2'b01: dataR = {{24{word_data[15]}}, word_data[15:8]};
                        2'b10: dataR = {{24{word_data[23]}}, word_data[23:16]};
                        2'b11: dataR = {{24{word_data[31]}}, word_data[31:24]};
                    endcase
                end
                3'b001: begin // lh
                    case (addr[1])
                        1'b0: dataR = {{16{word_data[15]}}, word_data[15:0]};
                        1'b1: dataR = {{16{word_data[31]}}, word_data[31:16]};
                    endcase
                end
                3'b010: dataR = word_data; // lw
                3'b100: begin // lbu
                    case (addr[1:0])
                        2'b00: dataR = {24'd0, word_data[7:0]};
                        2'b01: dataR = {24'd0, word_data[15:8]};
                        2'b10: dataR = {24'd0, word_data[23:16]};
                        2'b11: dataR = {24'd0, word_data[31:24]};
                    endcase
                end
                3'b101: begin // lhu
                    case (addr[1])
                        1'b0: dataR = {16'd0, word_data[15:0]};
                        1'b1: dataR = {16'd0, word_data[31:16]};
                    endcase
                end
                default: dataR = 32'd0;
            endcase
        end
    end

    // (store) Synchronous write
    always_ff @(posedge clk) begin
        if (MemRW && word_addr < 512) begin
            case (funct3)
                3'b000: begin // sb
                    case (addr[1:0])
                        2'b00: memory[word_addr][7:0]   <= dataW[7:0];
                        2'b01: memory[word_addr][15:8]  <= dataW[7:0];
                        2'b10: memory[word_addr][23:16] <= dataW[7:0];
                        2'b11: memory[word_addr][31:24] <= dataW[7:0];
                    endcase
                end
                3'b001: begin // sh
                    case (addr[1])
                        1'b0: memory[word_addr][15:0]  <= dataW[15:0];
                        1'b1: memory[word_addr][31:16] <= dataW[15:0];
                    endcase
                end
                3'b010: memory[word_addr] <= dataW; // sw
            endcase
        end else if (MemRW) begin
            $display("[DMEM][%0t ns] Skipped write: addr = %h out of bounds", $time, addr);
        end
    end

    // Memory initialization
    initial begin
        integer i;
        for (i = 0; i < 512; i++) begin
            memory[i] = 32'd0;
        end
        $readmemh("data_mem.mem", memory);
    end

endmodule