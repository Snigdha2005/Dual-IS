module fu1(
    input clk,
    input rst,
    input [31:0] src1,  // Source operand 1
    input [31:0] src2,  // Source operand 2
    output reg [31:0] result // Result of addition
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            result <= 0;
        else
            result <= src1 + src2; // Perform addition
    end
endmodule
