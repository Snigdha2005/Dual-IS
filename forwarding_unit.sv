module forwarding_unit;
    input [4:0] ID_EX_rs1;
    input [4:0] ID_EX_rs2;
    input [4:0] EX_MEM_rd;
    input [4:0] MEM_WB_rd;
    input EX_MEM_reg_write;
    input MEM_WB_reg_write;
    output reg [1:0] forward_a;
    output reg [1:0] forward_b;

always @(*) begin
    if ((EX_MEM_reg_write) & (EX_MEM_rd != 0) & (EX_MEM_rd == ID_EX_rs1)) forward_a = 2'b10;
    if ((EX_MEM_reg_write) & (EX_MEM_rd != 0) & (EX_MEM_rd == ID_EX_rs2)) forward_b = 2'b10;
    if ((MEM_WB_reg_write) & (MEM_WB_rd != 0) & !((EX_MEM_reg_write) & (EX_MEM_rd != 0) & (EX_MEM_rd == ID_EX_rs1)) & (MEM_WB_rd == ID_EX_rs1)) forward_a = 2'b01;
    if ((MEM_WB_reg_write) & (MEM_WB_rd != 0) & !((EX_MEM_reg_write) & (EX_MEM_rd != 0) & (EX_MEM_rd == ID_EX_rs2)) & (MEM_WB_rd == ID_EX_rs2)) forward_b = 2'b01;
end
endmodule