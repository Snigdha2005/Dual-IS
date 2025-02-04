module register_file(input [4:0] read_reg1, input [4:0] read_reg2, input [4:0] write_reg, input [31:0] write_data, output [31:0] read_reg1_value, output [31:0] read_reg2_value, input reg_write);
    // register x1 holds return address on call

    logic [31:0] gen_reg[31:0];
    assign gen_reg[0] = 32'b0;
    always @(*) begin
        if (reg_write == 1) begin
            gen_reg[write_reg] <= write_data;
        end
        read_reg1_value <= gen_reg[read_reg1];
        read_reg2_value <= gen_reg[read_reg2];
    end
endmodule