module writeback(
    input clk, 
    input [31:0] aluout,         // ALU result
    input [31:0] read_data,      // Data read from memory
    input mem_to_reg,            // Control signal: 1 = memory data, 0 = ALU result
    output reg [31:0] wb_data    // Data to write back to the register file
);
    always @(posedge clk) begin
        if (mem_to_reg) 
            wb_data = read_data; // Data from memory
        else 
            wb_data = aluout;    // Data from ALU
    end
endmodule
