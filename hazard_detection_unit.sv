module hazard_detection_unit;
    input [4:0] IF_ID_rs1;
    input [4:0] IF_ID_rs2;
    input [4:0] ID_EX_rd;
    input ID_EX_mem_read;
    output reg stall;

    always @(*) begin
        if(ID_EX_mem_read & ((ID_EX_rd == IF_ID_rs1) | (ID_EX_rd == IF_ID_rs2))) stall = 1;
    end
endmodule