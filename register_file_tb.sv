`timescale 1ns / 1ps

module register_file_tb;

    // Inputs
    reg [4:0] read_reg1;
    reg [4:0] read_reg2;
    reg [4:0] write_reg;
    reg [31:0] write_data;
    reg reg_write;

    // Outputs
    wire [31:0] read_reg1_value;
    wire [31:0] read_reg2_value;

    // Instantiate the Unit Under Test (UUT)
    register_file uut (
        .read_reg1(read_reg1),
        .read_reg2(read_reg2),
        .write_reg(write_reg),
        .write_data(write_data),
        .read_reg1_value(read_reg1_value),
        .read_reg2_value(read_reg2_value),
        .reg_write(reg_write)
    );

    // Testbench logic
    initial begin
        // Initialize inputs
        read_reg1 = 0;
        read_reg2 = 0;
        write_reg = 0;
        write_data = 0;
        reg_write = 0;

        // Test 1: Write to register 5 and read it
        #10;
        write_reg = 5;
        write_data = 32'hDEADBEEF;
        reg_write = 1;
        #10;
        reg_write = 0;
        read_reg1 = 5;
        #10;
        $display("Test 1: Write to register 5, Read value: %h", read_reg1_value);

        // Test 2: Write to register 10 and read it
        #10;
        write_reg = 10;
        write_data = 32'hCAFEBABE;
        reg_write = 1;
        #10;
        reg_write = 0;
        read_reg2 = 10;
        #10;
        $display("Test 2: Write to register 10, Read value: %h", read_reg2_value);

        // Test 3: Read from an uninitialized register (should be 0)
        #10;
        read_reg1 = 15;
        #10;
        $display("Test 3: Read from uninitialized register 15, Value: %h", read_reg1_value);

        // Test 4: Attempt to write to register 0 (should remain 0)
        #10;
        write_reg = 0;
        write_data = 32'h12345678;
        reg_write = 1;
        #10;
        reg_write = 0;
        read_reg1 = 0;
        #10;
        $display("Test 4: Write to register 0, Read value: %h", read_reg1_value);

        // Finish simulation
        $finish;
    end

endmodule
