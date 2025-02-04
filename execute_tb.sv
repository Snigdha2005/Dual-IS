`timescale 1ns / 1ps

module execute_tb();

    // Inputs
    reg [31:0] rs1_value;
    reg [31:0] rs2_value;
    reg [31:0] pc_value;
    reg [20:0] imm;
    reg [4:0] shamt;
    reg [2:0] funct3;
    reg [6:0] funct;
    reg [6:0] opcode;
    reg clk;

    // Outputs
    wire [31:0] aluout;
    wire [31:0] pc_adder;
    wire zero;

    // Instantiate the execute module
    execute uut (
        .rs1_value(rs1_value),
        .rs2_value(rs2_value),
        .pc_value(pc_value),
        .imm(imm),
        .shamt(shamt),
        .funct3(funct3),
        .funct(funct),
        .opcode(opcode),
        .aluout(aluout),
        .pc_adder(pc_adder),
        .zero(zero)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10ns clock period

    // Testbench logic
    initial begin
        // Initialize inputs
        rs1_value = 0;
        rs2_value = 0;
        pc_value = 0;
        imm = 0;
        shamt = 0;
        funct3 = 0;
        funct = 0;
        opcode = 0;

        // Test LUI operation
        #10;
        opcode = 7'b0110111; // LUI
        imm = 21'hABCDE;
        #10;
        $display("LUI: aluout = %h", aluout);

        // Test AUIPC operation
        #10;
        opcode = 7'b0010111; // AUIPC
        pc_value = 32'h1000;
        imm = 21'h12345;
        #10;
        $display("AUIPC: pc_adder = %h", pc_adder);

        // Test JAL operation
        #10;
        opcode = 7'b1101111; // JAL
        pc_value = 32'h2000;
        imm = 21'h6789A;
        #10;
        $display("JAL: aluout = %h, pc_adder = %h", aluout, pc_adder);

        // Test ADDI operation
        #10;
        opcode = 7'b0010011; // ADDI
        funct3 = 3'b000;
        rs1_value = 32'h1234;
        imm = 21'h5678;
        #10;
        $display("ADDI: aluout = %h", aluout);

        // Test BEQ operation
        #10;
        opcode = 7'b1100011; // BEQ
        funct3 = 3'b000;
        rs1_value = 32'h10;
        rs2_value = 32'h10;
        pc_value = 32'h3000;
        imm = 21'h100;
        #10;
        $display("BEQ (equal): pc_adder = %h, zero = %b", pc_adder, zero);

        #10;
        rs2_value = 32'h20; // Not equal
        #10;
        $display("BEQ (not equal): zero = %b", zero);

        // Test R-type ADD operation
        #10;
        opcode = 7'b0110011; // R-type
        funct3 = 3'b000;
        funct = 7'b0000000;
        rs1_value = 32'h1000;
        rs2_value = 32'h2000;
        #10;
        $display("ADD: aluout = %h", aluout);

        // Test R-type SUB operation
        #10;
        funct = 7'b0100000;
        #10;
        $display("SUB: aluout = %h", aluout);

        // Test R-type MUL operation
        #10;
        funct = 7'b0000001;
        #10;
        $display("MUL: aluout = %h", aluout);

        // End simulation
        #20;
        $finish;
    end

endmodule
