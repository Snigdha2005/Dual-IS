`timescale 1ns / 1ps

module control_unit_tb;

    // Inputs
    reg [6:0] opcode;
    reg clk;

    // Outputs
    wire reg_write;
    wire alusrc;
    wire zero;
    wire branch;
    wire mem_write;
    wire mem_read;
    wire mem_to_reg;

    // Instantiate the control_unit module
    control_unit uut (
        .opcode(opcode),
        .reg_write(reg_write),
        .alusrc(alusrc),
        .zero(zero),
        .branch(branch),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock period: 10ns
    end

    // Test sequence
    initial begin
        // Monitor outputs
        $monitor($time, " Opcode: %b | reg_write: %b, alusrc: %b, zero: %b, branch: %b, mem_write: %b, mem_read: %b, mem_to_reg: %b",
                 opcode, reg_write, alusrc, zero, branch, mem_write, mem_read, mem_to_reg);

        // Apply test cases
        opcode = 7'b0110011; // R-type instruction
        #10;

        opcode = 7'b0000011; // Load instruction
        #10;

        opcode = 7'b0100011; // Store instruction
        #10;

        opcode = 7'b1100011; // Branch instruction
        #10;

        opcode = 7'b1101111; // JAL instruction
        #10;

        opcode = 7'b0110111; // LUI instruction
        #10;

        opcode = 7'b0010111; // AUIPC instruction
        #10;

        opcode = 7'b1111111; // Default case (invalid opcode)
        #10;

        // End simulation
        $finish;
    end

endmodule
