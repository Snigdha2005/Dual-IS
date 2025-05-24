`timescale 1ns/1ps

module riscv_tb;

    // Parameters
    parameter MEMLEN = 3;
    parameter XLEN = 32;
    parameter N = 4;

    // Signals
    reg clk;
    reg mode;
    wire done;

    // Instantiate the RISC-V module
    riscv #(.MEMLEN(MEMLEN), .XLEN(XLEN), .N(N)) uut (
        .clk(clk),
        .mode(mode),
        .done(done)
    );

    // Clock generation
    always #4000 clk = ~clk; // 100MHz clock -> 10ns period

    // Initial setup
    initial begin
        // Initialize inputs
        clk = 0;
        mode = 0; // Assuming mode 0 is for normal operation (change if needed)

        // Display header
        $display("Time\tPC\tDone");

        // Wait for initialization
        #20;

        // Optionally, set mode = 1 if you want to test TTA mode (depends on design)
        // mode = 1;

        // Run until 'done' becomes 1
        wait(done == 1);

        // Wait a few more cycles to capture any last writes
        #120000;

        // Dump register and memory contents for checking
        $display("\nFinal Register File Contents:");
        for (int i = 0; i < XLEN; i = i + 1) begin
            $display("x[%0d] = %h", i, uut.x[i]);
        end

        $display("\nFinal Data Memory Contents:");
        for (int i = 0; i < MEMLEN; i = i + 1) begin
            $display("data_mem[%0d] = %h", i, uut.data_mem[i]);
        end

        $finish;
    end

    // Optional: Monitor basic info
    initial begin
        $monitor("%0dns | PC=%h | Switch=%b | Done=%b |\n\
    Instr[0]=%b Opcode[0]=%b RS1[0]=%b RS2[0]=%b RD[0]=%b Imm[0]=%b |\n\
    ",
            $time,
            uut.pc, uut.switch, done,
            uut.if_id_instr[0], uut.opcode[0], uut.rs1[0], uut.rs2[0], uut.rd[0], uut.signed_imm[0]
        );
    end
    initial begin
        $dumpfile("main2.vcd");  // Specify the VCD output file name
        $dumpvars(0, uut, uut.transport_add[0], uut.transport_add[1], uut.transport_add[2], uut.transport_add[3], uut.add_result[0], uut.add_result[1], uut.add_result[2], uut.add_result[3], uut.add_in1[0], uut.add_in1[1],uut.add_in1[2],uut.add_in1[3], uut.add_in2[0],uut.add_in2[1],uut.add_in2[2],uut.add_in2[3],uut.trigger_add[0], uut.trigger_add[1], uut.trigger_add[2], uut.trigger_add[3], uut.if_id_instr[0], uut.id_ex_opcode[0], uut.id_ex_imm[0], uut.id_ex_rs1[0], uut.id_ex_rs2[0], uut.id_ex_rd[0], uut.id_ex_funct3[0], uut.x[3], uut.x[4], uut.x[1], uut.if_id_instr[1], uut.if_id_instr[2], uut.if_id_instr[3], uut.id_ex_opcode[1], uut.id_ex_opcode[2], uut.id_ex_opcode[3], uut.id_ex_rs1[1], uut.id_ex_rs1[2], uut.id_ex_rs1[3], uut.id_ex_rs2[1], uut.id_ex_rs2[2], uut.id_ex_rs2[3], uut.id_ex_rd[1], uut.id_ex_rd[2], uut.id_ex_rd[3], uut.dest[0], uut.dest[1], uut.dest[2], uut.dest[3]);       // Dump all variables in module 'uut'
    end


endmodule
