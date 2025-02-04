module fu3(
    input clk,
    input rst,
    input [31:0] address,      // Address for load/store
    input [31:0] write_data,   // Data to be written to memory
    input mem_read,            // Read enable signal
    input mem_write,           // Write enable signal
    inout [31:0] data_mem[31:0], // Shared data memory
    output reg [31:0] read_data // Data read from memory
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_data <= 0;
        end else if (mem_read) begin
            read_data <= data_mem[address]; // Perform memory read
        end else if (mem_write) begin
            data_mem[address] <= write_data; // Perform memory write
        end
    end
endmodule
