module instruction_decode(input [31:0] instr);
    
    output reg [6:0] opcode;
    output reg [20:0] imm;
    output reg [4:0] rs2;
    output reg [4:0] rs1;
    output reg [4:0] rd;
    output reg [4:0] shamt;
    output reg [2:0] funct3;
    output reg [6:0] funct;

    always @(posedge clk) begin
        opcode = instr[6:0];
        case(opcode):
            7'b0110111: //lui
                begin
                    imm = instr[31:12];
                    rd = instr[11:7];
                end
            7'b0010111: //auipc
                begin
                    imm = instr[31:12];
                    rd = instr[11:7];
                end
            7'b1101111: //jal
                begin
                    imm = {instr[31], instr[19:12], instr[20], instr[30:21]};
                    rd = instr[11:7];
                end
            7'b1100111: //jalr
                begin
                    imm = instr[31:20];
                    rs1 = instr[19:15];
                    funct3 = instr[14:12];
                    rd = instr[11:7];
                end
            7'b1100011: //beq, bne, blt, bge, bltu, bgeu
                begin
                    imm = {instr[31], instr[7], instr[30:25], instr[11:8]};
                    rs2 = instr[24:20];
                    rs1 = instr[19:15];
                    funct3 = instr[14:12];
                end
            7'b0000011: //lb, lh, lw, lbu, lhu
                begin
                    imm = instr[31:20];
                    rs1 = instr[19:15];
                    funct3 = instr[14:12];
                    rd = instr[11:7];
                end
            7'b0100011: //sb, sh, sw
                begin
                    imm = {instr[31:25], instr[11:7]};
                    rs2 = instr[24:20];
                    rs1 = instr[19:15];
                    funct3 = instr[14:12];
                end
            7'b0010011: //addi, slti, sltiu, xori, ori, andi, slli, srli, srai
                begin
                    rs1 = instr[19:15];
                    funct3 = instr[14:12];
                    rd = instr[11:7];
                    if ((funct3 == 3'b001) | (funct3 == 3'b101)) begin
                        funct = instr[31:25];
                        shamt = instr[24:20];
                    end
                    else begin
                        imm = instr[31:20];
                    end
                end
            7'b0110011: //add, sub, sll, slt, sltu, xor, srl, sra, or, and, mul, mulh, mulhsu, mulhu, div, divu, rem, remu
                begin
                    funct = instr[31:25];
                    rs2 = instr[24:20];
                    rs1 = instr[19:15];
                    funct3 = instr[14:12];
                    rd = instr[11:7];
                end
            // 7'b0001111: //fence, fence.i
            // 7'b1110011: //ecall, ebreak, csrrw, csrrs, csrrs, csrrwi, csrrsi, csrrci
            default: begin    
            end
        endcase
    end
endmodule