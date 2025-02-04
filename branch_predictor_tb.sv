`timescale 1ns / 1ps

module tb_branch_predictor_2bit;

    // Testbench signals
    reg clk;
    reg branch_taken;
    wire predict_taken;

    // Instantiate the branch predictor module
    branch_predictor_2bit uut (
        .clk(clk),
        .branch_taken(branch_taken),
        .predict_taken(predict_taken)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Generate a clock with a period of 10ns
    end

    // Test sequence
    initial begin
        // Initialize inputs
        branch_taken = 0;

        // Apply test cases
        $display("Starting testbench...");

        // Case 1: Branch not taken repeatedly
        #10 branch_taken = 0; // Expect predictor to remain in NOT_TAKEN states
        #10 branch_taken = 0;
        #10 branch_taken = 0;

        // Case 2: Branch taken repeatedly
        #10 branch_taken = 1; // Expect predictor to move toward TAKEN states
        #10 branch_taken = 1;
        #10 branch_taken = 1;

        // Case 3: Alternating branch outcomes
        #10 branch_taken = 0; // Expect predictor to adjust dynamically
        #10 branch_taken = 1;
        #10 branch_taken = 0;
        #10 branch_taken = 1;

        // Case 4: Long sequence of taken branches
        repeat (5) begin
            #10 branch_taken = 1;
        end

        // Case 5: Long sequence of not taken branches
        repeat (5) begin
            #10 branch_taken = 0;
        end

        // End simulation
        $display("Testbench complete.");
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0t | branch_taken: %b | predict_taken: %b",
                 $time, branch_taken, predict_taken);
    end

endmodule
