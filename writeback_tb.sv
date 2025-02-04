module writeback_tb;

    // Testbench signals
    reg clk;
    reg [31:0] aluout;
    reg [31:0] read_data;
    reg mem_to_reg;
    wire [31:0] wb_data;

    // Instantiate the writeback module
    writeback uut (
        .clk(clk),
        .aluout(aluout),
        .read_data(read_data),
        .mem_to_reg(mem_to_reg),
        .wb_data(wb_data)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10-time unit clock period
    end

    // Test sequence
    initial begin
        // Initialize inputs
        aluout = 32'h00000000;
        read_data = 32'h00000000;
        mem_to_reg = 0;

        // Wait for a few clock cycles
        #10;

        // Test 1: Write ALU result to wb_data
        aluout = 32'h12345678;
        mem_to_reg = 0;
        #10; // Wait for clock edge
        $display("Test 1: wb_data = %h (Expected: 12345678)", wb_data);

        // Test 2: Write memory data to wb_data
        read_data = 32'h87654321;
        mem_to_reg = 1;
        #10; // Wait for clock edge
        $display("Test 2: wb_data = %h (Expected: 87654321)", wb_data);

        // Test 3: Change ALU result, ensure wb_data follows mem_to_reg
        aluout = 32'hAABBCCDD;
        mem_to_reg = 0;
        #10; // Wait for clock edge
        $display("Test 3: wb_data = %h (Expected: AABBCCDD)", wb_data);

        // Test 4: Change memory data, ensure wb_data follows mem_to_reg
        read_data = 32'hDEADBEEF;
        mem_to_reg = 1;
        #10; // Wait for clock edge
        $display("Test 4: wb_data = %h (Expected: DEADBEEF)", wb_data);

        // End simulation
        $stop;
    end

endmodule
