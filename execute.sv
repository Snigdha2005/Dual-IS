module execute();
    input [31:0] rs1_value;
    input [31:0] rs2_value;
    input [31:0] pc_value;
    input [20:0] imm;
    input [4:0] shamt;
    input [2:0] funct3;
    input [6:0] funct;
    input [6:0] opcode;
    output reg [31:0] aluout;
    output reg [31:0] pc_adder;
    output reg zero;

    always @(posedge clk) begin
        case(opcode):
            7'b0110111: //lui
                begin
                    aluout = {imm[19:0], 12'b0};
                end
            7'b0010111: //auipc
                begin
                    pc_adder = pc_value + imm;
                end
            7'b1101111: //jal
                begin
                    aluout = pc_value + 1;
                    pc_adder = pc_value + imm;
                end
            7'b1100111: //jalr
                begin
                    aluout = pc_value + 1;
                    pc_adder = rs1_value + imm;
                end
            7'b1100011: //beq, bne, blt, bge, bltu, bgeu
                begin
                    case(funct3):
                        3b'000: begin
                            if (rs1_value == rs2_value) begin pc_adder = pc_value + imm; zero = 1; end
                            else begin zero = 0; end
                        end
                        3'b001: begin
                            if (rs1_value != rs2_value) begin pc_adder = pc_value + imm; zero = 0; end
                            else begin zero = 1; end
                        end
                        3'b100: begin
                            if ($signed(rs1_value) < $signed(rs2_value)) pc_adder = pc_value + imm;
                        end
                        3'b101: begin
                            if ($signed(rs1_value) >= $signed(rs2_value)) pc_adder = pc_value + imm;
                        end
                        3'b110: begin
                            if (rs1_value < rs2_value) pc_adder = pc_value + imm;
                        end
                        3'b111: begin
                            if (rs1_value >= rs2_value) pc_adder = pc_value + imm;
                        end
                    endcase

                end
            7'b0000011: //lb, lh, lw, lbu, lhu
                begin
                    aluout = rs1_value + imm;    
                end
            7'b0100011: //sb, sh, sw
                begin
                    aluout = rs1_value + imm;
                end
            7'b0010011: //addi, slti, sltiu, xori, ori, andi, slli, srli, srai
                begin
                    case(funct3)
                        3'b000: aluout = rs1_value + imm; 
                        3'b010: aluout = ($signed(rs1_value) < $signed(imm)) ? 1 : 0;
                        3'b011: aluout = (rs1_value < imm) ? 1 : 0;
                        3'b100: aluout = rs1_value ^ imm; 
                        3'b110: aluout = rs1_value | imm; 
                        3'b111: aluout = rs1_value & imm; 
                        3'b001: aluout = rs1_value << shamt; 
                        3'b101: aluout = (funct == 7'b0000000) ? rs1_value >> shamt : $signed(rs1_value) >>> shamt; 
                    endcase
                end
            7'b0110011: //add, sub, sll, slt, sltu, xor, srl, sra, or, and, mul, mulh, mulhsu, mulhu, div, divu, rem, remu
                begin
                    case(funct3):
                        3'b000: begin
                            case(funct):
                                7'b0: begin
                                    aluout = rs1_value + rs2_value;
                                end
                                7'b0100000: begin
                                    aluout = rs1_value - rs2_value;
                                end
                                7'b0000001: begin
                                    aluout = rs1_value * rs2_value;
                                end
                            endcase
                        end     
                        3'b001: begin
                            case(funct):
                                7'b0: begin
                                    aluout = rs1_value << rs2_value[4:0];
                                end
                                7'b0000001: begin
                                    aluout = ($signed(rs1_value) * $signed(rs2_value)) >>> 32;
                                end
                            endcase
                        end
                        3'b010: begin
                            case(funct):
                                7'b0: begin
                                    aluout = ($signed(rs1_value) < $signed(rs2_value)) ? 32'b1 : 32'b0;
                                end
                                7'b0000001: begin
                                    aluout = ($signed(rs1_value) * rs2_value) >>> 32;
                                end
                            endcase
                        end
                        3'b011: begin
                            case(funct):
                                7'b0: begin
                                    aluout = (rs1_value < rs2_value) ? 32'b1 : 32'b0;
                                end
                                7'b0000001: begin
                                    aluout = (rs1_value * rs2_value) >> 32;
                                end
                            endcase
                        end
                        3'b100: begin
                            case(funct):
                                7'b0: begin
                                    aluout = rs1_value ^ rs2_value;
                                end
                                7'b0000001: begin
                                    aluout = ($signed(rs1_value) / $signed(rs2_value));
                                end
                            endcase
                        end
                        3'b101: begin
                            case(funct):
                                7'b0000000: begin
                                    aluout = rs1_value >> rs2_value[4:0];
                                end
                                7'b0100000: begin
                                    aluout = $signed(rs1_value) >>> rs2_value[4:0];
                                end
                                7'b0000001: begin
                                    aluout = rs1_value / rs2_value;
                                end
                            endcase
                        end
                        3'b110: begin
                            case(funct):
                                7'b0: begin
                                    aluout = rs1_value | rs2_value;
                                end
                                7'b0000001: begin
                                    aluout = ($signed(rs1_value) % $signed(rs2_value));
                                end
                            endcase
                            
                        end
                        3'b111: begin
                            case(funct):
                                7'b0: begin
                                    aluout = rs1_value & rs2_value;
                                end
                                7'b0000001: begin
                                    aluout = rs1_value % rs2_value;
                                end
                            endcase
                        end
                        default: begin
                            aluout = 32'b0;
                        end
                    endcase
                end
            // 7'b0001111: //fence, fence.i
            // 7'b1110011: //ecall, ebreak, csrrw, csrrs, csrrs, csrrwi, csrrsi, csrrci
            default: begin    
            end
        endcase
    end    
endmodule