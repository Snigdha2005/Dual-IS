module control_unit();
    input [6:0] opcode;
    output reg reg_write;
    output reg alusrc;
    output reg zero;
    output reg branch;
    output reg mem_write;
    output reg mem_read;
    output reg mem_to_reg;

    always @(posedge clk) begin
        case(opcode):
            7'b0110011: begin
                reg_write = 1;
                alusrc = 0;
                zero = x;
                branch = 0;
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
            end
            7'b0000011: begin
                reg_write = 1;
                alusrc = 1;
                zero = x;
                branch = 0;
                mem_write = 0;
                mem_read = 1;
                mem_to_reg = 1;
            end
            7'b0100011: begin
                reg_write = 0;
                alusrc = 1;
                zero = x;
                branch = 0;
                mem_write = 1;
                mem_read = 0;
                mem_to_reg = 0;
            end
            7'b1100011: begin
                reg_write = 0;
                alusrc = 1;
                zero = 1;
                branch = 1;
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
            end
            7'b1101111: begin
                reg_write = 1;
                alusrc = x;
                zero = x;
                branch = 0;
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
            end
            7'b0110111: begin
                reg_write = 1;
                alusrc = x;
                zero = x;
                branch = 0;
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
            end
            7'b0010111: begin
                reg_write = 1;
                alusrc = x;
                zero = x;
                branch = 0;
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
            end
            default: begin
                reg_write = 1;
                alusrc = 1;
                zero = x;
                branch = 0;
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
            end
        endcase
    end
endmodule