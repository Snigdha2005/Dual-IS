`timescale 1ns / 1ps

module instruction_fetch_tb;

    // Inputs
    reg clk;
    reg [31:0] pc;
    reg [31:0] instr_mem [0:31];

    // Output
    wire [31:0] instr;

    // Instantiate the Unit Under Test (UUT)
    instruction_fetch uut (
        .clk(clk),
        .pc(pc),
        .instr_mem(instr_mem),
        .instr(instr)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test sequence
    initial begin
        // Initialize instruction memory
        instr_mem[0] = 32'h12345678;
        instr_mem[1] = 32'h9ABCDEF0;
        instr_mem[2] = 32'h0F0F0F0F;
        instr_mem[3] = 32'hF0F0F0F0;
        instr_mem[4] = 32'hAAAAAAAA;
        instr_mem[5] = 32'h55555555;

        // Initialize pc
        pc = 0;

        // Monitor signals
        $monitor("Time: %0t | PC: %0d | Instruction: %h", $time, pc, instr);

        // Test cases
        #10 pc = 1;
        #10 pc = 2;
        #10 pc = 3;
        #10 pc = 4;
        #10 pc = 5;
        #10 $finish;
    end

endmodule
