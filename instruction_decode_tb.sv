`timescale 1ns / 1ps

module instruction_decode_tb;

    // Inputs
    reg [31:0] instr;
    reg clk;

    // Outputs
    wire [6:0] opcode;
    wire [20:0] imm;
    wire [4:0] rs2;
    wire [4:0] rs1;
    wire [4:0] rd;
    wire [4:0] shamt;
    wire [2:0] funct3;
    wire [6:0] funct;

    // Instantiate the Unit Under Test (UUT)
    instruction_decode uut (
        .instr(instr),
        .opcode(opcode),
        .imm(imm),
        .rs2(rs2),
        .rs1(rs1),
        .rd(rd),
        .shamt(shamt),
        .funct3(funct3),
        .funct(funct)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Monitor outputs
        $monitor($time, " instr=%h, opcode=%b, imm=%h, rs2=%d, rs1=%d, rd=%d, shamt=%d, funct3=%b, funct=%b", 
                 instr, opcode, imm, rs2, rs1, rd, shamt, funct3, funct);

        // Test case 1: LUI instruction
        instr = 32'b00000000000000000001000010110111; // LUI with rd = 1, imm = 0x00001
        #10;

        // Test case 2: AUIPC instruction
        instr = 32'b00000000000000000001000010010111; // AUIPC with rd = 1, imm = 0x00001
        #10;

        // Test case 3: JAL instruction
        instr = 32'b00000000000100000000000011101111; // JAL with rd = 1, imm = 0x00010
        #10;

        // Test case 4: JALR instruction
        instr = 32'b00000000001000001000000011100111; // JALR with rd = 1, rs1 = 1, imm = 0x00002
        #10;

        // Test case 5: BEQ instruction
        instr = 32'b00000000000100001000000001100011; // BEQ with rs1 = 1, rs2 = 1, imm = 0x00002
        #10;

        // Test case 6: ADDI instruction
        instr = 32'b00000000000100001000000010010011; // ADDI with rd = 1, rs1 = 1, imm = 0x00002
        #10;

        // Test case 7: SLLI instruction
        instr = 32'b00000000000100001001000010010011; // SLLI with rd = 1, rs1 = 1, shamt = 2
        #10;

        // Test case 8: ADD instruction
        instr = 32'b00000000000100001000000010110011; // ADD with rd = 1, rs1 = 1, rs2 = 1
        #10;

        // Test case 9: SB instruction
        instr = 32'b00000000000100001000000000100011; // SB with rs1 = 1, rs2 = 1, imm = 0x00002
        #10;

        // End simulation
        $finish;
    end

endmodule
