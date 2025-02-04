module instruction_fetch(input clk, input [31:0] pc, input [31*N:0] instr_mem[31:0], output reg [32:0] instr);
    always @(posegde clk) begin
        instr = instr_mem[pc];
    end
endmodule