`timescale 1ns / 1ps

module data_mem_tb;

    // Inputs
    reg [31:0] aluout;
    reg [31:0] store_data;
    reg mem_write;
    reg mem_read;
    reg branch;
    reg zero;
    reg clk;

    // Outputs
    wire [31:0] read_data;
    wire pcsrc;

    // Memory
    reg [31:0] data_mem [31:0];

    // Instantiate the Unit Under Test (UUT)
    data_mem uut (
        .aluout(aluout),
        .store_data(store_data),
        .read_data(read_data),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .data_mem(data_mem),
        .branch(branch),
        .zero(zero),
        .pcsrc(pcsrc)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Initialize and run test cases
    initial begin
        // Initialize memory to zero
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            data_mem[i] = 32'b0;
        end

        // Test case 1: Write to memory
        aluout = 5;          // Address to write
        store_data = 32'hDEADBEEF; // Data to write
        mem_write = 1;
        mem_read = 0;
        branch = 0;
        zero = 0;
        @(posedge clk);
        mem_write = 0;

        // Test case 2: Read from memory
        aluout = 5;          // Address to read
        mem_write = 0;
        mem_read = 1;
        @(posedge clk);
        mem_read = 0;

        // Test case 3: Branch and zero
        branch = 1;
        zero = 1;
        @(posedge clk);

        // Test case 4: No branch
        branch = 1;
        zero = 0;
        @(posedge clk);

        // Test case 5: Default behavior
        aluout = 10;         // Unused address
        store_data = 32'h12345678;
        mem_write = 0;
        mem_read = 0;
        branch = 0;
        zero = 0;
        @(posedge clk);

        // Finish simulation
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0d | aluout=%0d | store_data=0x%h | read_data=0x%h | mem_write=%b | mem_read=%b | branch=%b | zero=%b | pcsrc=%b", 
                 $time, aluout, store_data, read_data, mem_write, mem_read, branch, zero, pcsrc);
    end

endmodule
