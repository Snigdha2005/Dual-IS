module riscv #(parameter MEMLEN = 10, parameter XLEN = 32)(
    input clk, output reg done);

    reg [31:0] instruction_mem [0:MEMLEN-1];
    reg [31:0] data_mem [0:MEMLEN-1];
    reg [XLEN-1:0] x [0:XLEN-1];
    reg [31:0] pc;
    // reg [FLEN-1:0] f [0:FLEN-1];
    reg [31:0] instr, if_id_instr;
    reg [31:0] ex_mem_pc;
    reg [31:0] if_id_pc, id_ex_pc;
    reg [6:0] opcode, id_ex_opcode;
    reg [31:0] imm;
    reg [31:0] signed_imm, id_ex_imm;
    reg [4:0] rd, id_ex_rd, ex_mem_rd, mem_wb_rd;
    reg [4:0] rs1, id_ex_rs1;
    reg [4:0] rs2, id_ex_rs2;
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg [31:0] alu_src1, alu_src2, id_ex_rs1_value, id_ex_rs2_value, forward_rs1, forward_rs2, ex_mem_rs1_value;
    reg [1:0] forwardA, forwardB;
    reg [31:0] mem_wb_data, ex_mem_result, alu_result, mem_wb_alu, write_data;
    reg [4:0] shamt;
    reg if_id_pred_taken, predict_taken, pc_src_from_predictor;
    reg [31:0] if_id_pred_target, predict_target;
    reg [1:0] predictor_state;

    reg flush;
    reg zero;
    reg stall;
    reg pc_src, ex_mem_pc_src;
    reg pc_write;
    reg if_id_write;
    reg reg_write, id_ex_reg_write, ex_mem_reg_write, mem_wb_reg_write;
    reg alu_src, id_ex_alu_src;
    reg mem_read, id_ex_mem_read, ex_mem_mem_read;
    reg mem_write, id_ex_mem_write, ex_mem_mem_write;
    reg mem_to_reg, id_ex_mem_to_reg, ex_mem_mem_to_reg, mem_wb_mem_to_reg;
    reg branch, id_ex_branch, ex_mem_branch, branch_taken;

    initial begin
        // Initialize Program Counter and other special-purpose registers
        $readmemb("instruction_mem.bin", instruction_mem);
        $readmemb("data_mem.bin", data_mem);
        $readmemb("registers.bin", x);

        pc = 0;
        // fcsr = 0;
        instr = 0;
        shamt = 0;
        funct7 = 0;
        funct3 = 0;
        flush = 0;
        // Initialize pipeline registers
        if_id_pc = 0;
        if_id_instr = 0;
        id_ex_pc = 0;
        id_ex_imm = 0;
        id_ex_opcode = 0;
        id_ex_rd = 0;
        id_ex_rs1 = 0;
        id_ex_rs2 = 0;
        id_ex_rs1_value = 0;
        id_ex_rs2_value = 0;
        id_ex_reg_write = 0;
        id_ex_alu_src = 0;
        id_ex_mem_read = 0;
        id_ex_mem_write = 0;
        id_ex_mem_to_reg = 0;
        id_ex_branch = 0;

        ex_mem_pc = 0;
        ex_mem_rd = 0;
        ex_mem_result = 0;
        ex_mem_rs1_value = 0;
        ex_mem_pc_src = 0;
        ex_mem_reg_write = 0;
        ex_mem_mem_read = 0;
        ex_mem_mem_write = 0;
        ex_mem_mem_to_reg = 0;
        ex_mem_branch = 0;

        mem_wb_rd = 0;
        mem_wb_data = 0;
        mem_wb_alu = 0;
        mem_wb_reg_write = 0;
        mem_wb_mem_to_reg = 0;

        // Initialize control signals
        pc_src = 0;
        pc_write = 0;
        if_id_write = 0;
        reg_write = 0;
        alu_src = 0;
        mem_read = 0;
        mem_write = 0;
        mem_to_reg = 0;
        branch = 0;
        stall = 0;

        // Initialize ALU and forwarding logic
        alu_result = 0;
        alu_src1 = 0;
        alu_src2 = 0;
        forwardA = 0;
        forwardB = 0;
        forward_rs1 = 0;
        forward_rs2 = 0;
        zero = 0;
        write_data = 0;

        // Instruction decode stage temp variables
        opcode = 0;
        funct3 = 0;
        funct7 = 0;
        rd = 0;
        rs1 = 0;
        rs2 = 0;
        signed_imm = 0;
        imm = 0;
    end

    // always @(posedge clk) begin
    //     // for (int i = 0; i < XLEN; i = i + 1) begin
    //     //     x1[i*XLEN +: XLEN] <= x[i];
    //     // end

    //     // Flatten data_mem into datamem1
    //     for (int i = 0; i < MEMLEN; i = i + 1) begin
    //         data_mem1 <= data_mem[i];
    //     end
    // end

    always @(posedge clk) begin
        if(flush == 0) begin
            if (pc_write) begin
                instr <= instruction_mem[pc];
                if (pc_src_from_predictor) begin
                    pc <= predict_target;  // Branch taken, use predicted target
                end else begin
                    pc <= pc + 1;  // No branch, increment normally
                end
            end

            if (if_id_write) begin
                if_id_instr <= instr;
                if_id_pc    <= pc;
                if_id_pred_taken <= predict_taken; 
                if_id_pred_target <= predict_target;
            end
        end
        else begin
            instr <= 0;
            pc <= pc;
            if_id_instr <= instr;
            if_id_pc <= pc;
            if_id_pred_taken <= predict_taken; 
            if_id_pred_target <= predict_target;
        end
        if (pc == MEMLEN) done <= 1;
        else done <= 0;
    end

    always @(posedge clk) begin
        if (flush == 0) begin
            opcode <= if_id_instr[6:0];
            stall <= (id_ex_mem_read && ((id_ex_rd != 0) && ((id_ex_rd == if_id_instr[19:15]) || (id_ex_rd == if_id_instr[24:20])))) ? 1 : 0;
            if_id_write <= ~stall;
            pc_write <= ~stall;

            if (stall) begin
                opcode <= 7'b0000000;
            end
            case(opcode)
                7'b0110111: begin
                    imm <= {if_id_instr[31:12], 12'b0};
                    rd <= if_id_instr[11:7];
                    signed_imm <= $signed(imm);
                    pc_src <= 0;
                    reg_write <= 1;
                    alu_src <= 1;
                    mem_read <= 0;
                    mem_write <= 0;
                    mem_to_reg <= 0;
                    branch <= 0;
                end
                7'b0010111: begin
                    imm <= {if_id_instr[31:12], 12'b0};
                    rd <= if_id_instr[11:7];
                    signed_imm <= $signed(imm);
                    pc_src <= 0;
                    reg_write <= 1;
                    alu_src <= 1;
                    mem_read <= 0;
                    mem_write <= 0;
                    mem_to_reg <= 0;
                    branch <= 0;
                end
                7'b1101111: begin
                    imm[20] <= if_id_instr[31];
                    imm[10:1] <= if_id_instr[30:21];
                    imm[11] <= if_id_instr[20];
                    imm[19:12] <= if_id_instr[19:12];
                    imm[0] <= 1'b0;
                    signed_imm <= $signed(imm);
                    rd <= if_id_instr[11:7];
                    pc_src <= 1;
                    reg_write <= 1;
                    alu_src <= 0;
                    mem_read <= 0;
                    mem_write <= 0;
                    mem_to_reg <= 0;
                    branch <= 0;
                end
                7'b1100111: begin
                    imm[11:0] <= if_id_instr[31:20];
                    signed_imm <= $signed(imm);
                    rs1 <= if_id_instr[19:15];
                    funct3 <= if_id_instr[14:12];
                    rd <= if_id_instr[11:7];
                    pc_src <= 1;
                    reg_write <= 1;
                    alu_src <= 1;
                    mem_read <= 0;
                    mem_write <= 0;
                    mem_to_reg <= 0;
                    branch <= 0;
                end
                7'b1100011: begin
                    funct3 <= if_id_instr[14:12];
                    imm[12] <= if_id_instr[31];
                    imm[10:5] <= if_id_instr[30:25];
                    imm[4:1] <= if_id_instr[11:8];
                    imm[11] <= if_id_instr[7];
                    signed_imm <= $signed(imm);
                    rs2 <= if_id_instr[24:20];
                    rs1 <= if_id_instr[19:15];
                    case(funct3)
                        3'b000: begin
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 1;
                        end
                        3'b001: begin
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 1;
                        end
                        3'b100: begin
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 1;
                        end
                        3'b101: begin
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 1;
                        end
                        3'b110: begin
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 1;
                        end
                        3'b111: begin
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 1;
                        end
                        default: begin
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                    endcase
                end
                7'b0000011: begin
                    imm[11:0] <= if_id_instr[31:20];
                    signed_imm <= $signed(imm);
                    rs1 <= if_id_instr[19:15];
                    funct3 <= if_id_instr[14:12];
                    rd <= if_id_instr[11:7];
                    case(funct3)
                        3'b000: begin
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 1;
                            mem_read <= 1;
                            mem_write <= 0;
                            mem_to_reg <= 1;
                            branch <= 0;
                        end
                        3'b001: begin
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 1;
                            mem_read <= 1;
                            mem_write <= 0;
                            mem_to_reg <= 1;
                            branch <= 0;
                        end
                        3'b010: begin
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 1;
                            mem_read <= 1;
                            mem_write <= 0;
                            mem_to_reg <= 1;
                            branch <= 0;
                        end
                        3'b100: begin
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 1;
                            mem_read <= 1;
                            mem_write <= 0;
                            mem_to_reg <= 1;
                            branch <= 0;
                        end
                        3'b101: begin
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 1;
                            mem_read <= 1;
                            mem_write <= 0;
                            mem_to_reg <= 1;
                            branch <= 0;
                        end
                        default: begin
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                    endcase
                end
                7'b0100011: begin
                    imm[11:5] <= if_id_instr[31:25];
                    imm[4:0] <= if_id_instr[11:7];
                    rs2 <= if_id_instr[24:20];
                    rs1 <= if_id_instr[19:15];
                    funct3 <= if_id_instr[14:12];
                    case(funct3)
                        3'b000: begin
                            
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 1;
                            mem_read <= 0;
                            mem_write <= 1;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b001: begin
                            
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 1;
                            mem_read <= 0;
                            mem_write <= 1;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b010: begin
                            
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 1;
                            mem_read <= 0;
                            mem_write <= 1;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        default: begin
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                    endcase
                end
                7'b0010011: begin
                    rs1 <= if_id_instr[19:15];
                    funct3 <= if_id_instr[14:12];
                    rd <= if_id_instr[11:7];
                    case(funct3)
                        3'b000: begin
                            imm[11:0] <= if_id_instr[31:20];
                            signed_imm <= $signed(imm);
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 1;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b010: begin
                            imm[11:0] <= if_id_instr[31:20];
                            signed_imm <= $signed(imm);
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 1;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b011: begin
                            imm[11:0] <= if_id_instr[31:20];
                            signed_imm <= $signed(imm);
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 1;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b100: begin
                            imm[11:0] <= if_id_instr[31:20];
                            signed_imm <= $signed(imm);
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 1;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b110: begin
                            imm[11:0] <= if_id_instr[31:20];
                            signed_imm <= $signed(imm);
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 1;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b111: begin
                            imm[11:0] <= if_id_instr[31:20];
                            signed_imm <= $signed(imm);
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 1;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b001: begin
                            funct7 <= if_id_instr[31:25];
                            shamt <= if_id_instr[24:20];
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 1;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b101: begin
                            funct7 <= if_id_instr[31:25];
                            shamt <= if_id_instr[24:20];
                            case(funct7)
                                7'b0000000: begin
                                    
                                    pc_src <= 0;
                                    reg_write <= 1;
                                    alu_src <= 1;
                                    mem_read <= 0;
                                    mem_write <= 0;
                                    mem_to_reg <= 0;
                                    branch <= 0;
                                end
                                7'b0100000: begin
                                    
                                    pc_src <= 0;
                                    reg_write <= 1;
                                    alu_src <= 1;
                                    mem_read <= 0;
                                    mem_write <= 0;
                                    mem_to_reg <= 0;
                                    branch <= 0;
                                end
                                default: begin
                                    
                                    pc_src <= 0;
                                    reg_write <= 0;
                                    alu_src <= 0;
                                    mem_read <= 0;
                                    mem_write <= 0;
                                    mem_to_reg <= 0;
                                    branch <= 0;
                                end
                                
                            endcase
                        end
                        default: begin
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                    endcase
                end
                7'b0110011: begin
                    funct7 <= if_id_instr[31:25];
                    funct3 <= if_id_instr[14:12];
                    rs2 <= if_id_instr[24:20];
                    rs1 <= if_id_instr[19:15];
                    case(funct3)
                        3'b000: begin
                            case(funct7)
                                7'b0000000: begin
                                    
                                    pc_src <= 0;
                                    reg_write <= 1;
                                    alu_src <= 0;
                                    mem_read <= 0;
                                    mem_write <= 0;
                                    mem_to_reg <= 0;
                                    branch <= 0;
                                end
                                7'b0100000: begin
                                    
                                    pc_src <= 0;
                                    reg_write <= 1;
                                    alu_src <= 0;
                                    mem_read <= 0;
                                    mem_write <= 0;
                                    mem_to_reg <= 0;
                                    branch <= 0;
                                end
                                default: begin
                                    pc_src <= 0;
                                    reg_write <= 0;
                                    alu_src <= 0;
                                    mem_read <= 0;
                                    mem_write <= 0;
                                    mem_to_reg <= 0;
                                    branch <= 0;
                                end
                            endcase
                        end
                        3'b001: begin
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b010: begin
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b011: begin
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b100: begin
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b101: begin
                            case(funct7)
                                7'b0000000: begin
                                    
                                    pc_src <= 0;
                                    reg_write <= 1;
                                    alu_src <= 0;
                                    mem_read <= 0;
                                    mem_write <= 0;
                                    mem_to_reg <= 0;
                                    branch <= 0;
                                end
                                7'b0100000: begin
                                    
                                    pc_src <= 0;
                                    reg_write <= 1;
                                    alu_src <= 0;
                                    mem_read <= 0;
                                    mem_write <= 0;
                                    mem_to_reg <= 0;
                                    branch <= 0;
                                end
                                default: begin
                                    pc_src <= 0;
                                    reg_write <= 0;
                                    alu_src <= 0;
                                    mem_read <= 0;
                                    mem_write <= 0;
                                    mem_to_reg <= 0;
                                    branch <= 0;
                                end
                            endcase
                        end
                        3'b110: begin
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        3'b111: begin
                            
                            pc_src <= 0;
                            reg_write <= 1;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                        default: begin
                            pc_src <= 0;
                            reg_write <= 0;
                            alu_src <= 0;
                            mem_read <= 0;
                            mem_write <= 0;
                            mem_to_reg <= 0;
                            branch <= 0;
                        end
                    endcase
                end
                7'b0000000: begin
                    
                    pc_src <= 0;
                    reg_write <= 0;
                    alu_src <= 0;
                    mem_read <= 0;
                    mem_write <= 0;
                    mem_to_reg <= 0;
                    branch <= 0;
                end
                default: begin
                    pc_src <= 0;
                    reg_write <= 0;
                    alu_src <= 0;
                    mem_read <= 0;
                    mem_write <= 0;
                    mem_to_reg <= 0;
                    branch <= 0;
                end
            endcase

            id_ex_rs2_value <= x[rs2];
            id_ex_rs1_value <= x[rs1];
            id_ex_rs1 <= rs1;
            id_ex_rs2 <= rs2;
            id_ex_imm <= signed_imm;
            id_ex_opcode <= opcode;
            id_ex_pc <= if_id_pc;
            id_ex_rd <= rd;
            id_ex_reg_write <= reg_write;
            id_ex_alu_src <= alu_src;
            id_ex_mem_read <= mem_read;
            id_ex_mem_write <= mem_write;
            id_ex_mem_to_reg <= mem_to_reg;
            id_ex_branch <= branch;
        end
        else begin
            id_ex_rs2_value <= 0;
            id_ex_rs1_value <= 0;
            id_ex_rs1 <= 0;
            id_ex_rs2 <= 0;
            id_ex_imm <= 0;
            id_ex_opcode <= 0;
            id_ex_pc <= 0;
            id_ex_rd <= 0;
            id_ex_reg_write <= 0;
            id_ex_alu_src <= 0;
            id_ex_mem_read <= 0;
            id_ex_mem_write <= 0;
            id_ex_mem_to_reg <= 0;
            id_ex_branch <= 0;
        end
    end

    always @(posedge clk) begin
        if(mode == 0 && switch == 0) begin
        if ((ex_mem_reg_write) && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1)) forwardA <= 2'b10;
        if ((ex_mem_reg_write) && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2)) forwardB <= 2'b10;
        if ((mem_wb_reg_write) && (mem_wb_rd != 0) && (~((ex_mem_reg_write) && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1))) && (mem_wb_rd == id_ex_rs1)) forwardA <= 2'b01;
        if ((mem_wb_reg_write) && (mem_wb_rd != 0) && (~((ex_mem_reg_write) && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1))) && (mem_wb_rd == id_ex_rs2)) forwardB <= 2'b01;

        case (forwardA)
            2'b00: forward_rs1 <= id_ex_rs1_value;
            2'b01: forward_rs1 <= mem_wb_data;
            2'b10: forward_rs1 <= ex_mem_result;
            default: forward_rs1 <= id_ex_rs1_value;
        endcase

        // Forwarding mux for alu_src2
        case (forwardB)
            2'b00: forward_rs2 <= id_ex_rs2_value;
            2'b01: forward_rs2 <= mem_wb_data;
            2'b10: forward_rs2 <= ex_mem_result;
            default: forward_rs2 <= id_ex_rs2_value;
        endcase

        // ALU input selection
        alu_src1 <= (id_ex_alu_src == 0) ? forward_rs1 : id_ex_imm;
        alu_src2 <= forward_rs2;

        case(id_ex_opcode)
            7'b0110111: begin // LUI
                alu_result <= alu_src1; // id_ex_imm
            end
            7'b0010111: begin // AUIPC
                alu_result <= id_ex_pc + alu_src1; // id_ex_imm
            end
            7'b1101111: begin // JAL
                alu_result <= id_ex_pc + alu_src1; // id_ex_imm
            end
            7'b1100111: begin // JALR
                alu_result <= alu_src1 + alu_src2; // rs1 + imm
            end
            7'b1100011: begin // Branch
                case(funct3)
                    3'b000: zero <= (alu_src1 == alu_src2) ? 1 : 0; // BEQ
                    3'b001: zero <= (alu_src1 != alu_src2) ? 1 : 0; // BNE
                    3'b100: zero <= ($signed(alu_src1) < $signed(alu_src2)) ? 1 : 0; // BLT
                    3'b101: zero <= ($signed(alu_src1) >= $signed(alu_src2)) ? 1 : 0; // BGE
                    3'b110: zero <= (alu_src1 < alu_src2) ? 1 : 0; // BLTU
                    3'b111: zero <= (alu_src1 >= alu_src2) ? 1 : 0; // BGEU
                    default: begin
                        alu_result <= 0;
                    end

                endcase
            end
            7'b0000011: begin // Loads (LB, LH, LW, etc.)
                alu_result <= alu_src1 + alu_src2; // rs1 + imm
            end
            7'b0100011: begin // Stores (SB, SH, SW)
                alu_result <= alu_src1 + alu_src2; // rs1 + imm
            end
            7'b0010011: begin // Immediate ALU ops
                case(funct3)
                    3'b000: alu_result <= alu_src1 + alu_src2; // ADDI
                    3'b010: alu_result <= ($signed(alu_src1) < $signed(alu_src2)) ? 1 : 0; // SLTI
                    3'b011: alu_result <= (alu_src1 < alu_src2) ? 1 : 0; // SLTIU
                    3'b100: alu_result <= alu_src1 ^ alu_src2; // XORI
                    3'b110: alu_result <= alu_src1 | alu_src2; // ORI
                    3'b111: alu_result <= alu_src1 & alu_src2; // ANDI
                    3'b001: alu_result <= alu_src1 << alu_src2[4:0]; // SLLI
                    3'b101: begin
                        case(funct7)
                            7'b0000000: alu_result <= alu_src1 >> alu_src2[4:0]; // SRLI
                            7'b0100000: alu_result <= $signed(alu_src1) >>> alu_src2[4:0]; // SRAI
                            default: begin
                                alu_result <= 0;
                            end
                        endcase
                    end
                endcase
            end
            7'b0110011: begin // Register-Register ALU ops
                case(funct3)
                    3'b000: begin
                        case(funct7)
                            7'b0000000: alu_result <= alu_src1 + alu_src2; // ADD
                            7'b0100000: alu_result <= alu_src1 - alu_src2; // SUB
                            default: alu_result <= 0;
                        endcase
                    end
                    3'b001: alu_result <= alu_src1 << alu_src2[4:0]; // SLL
                    3'b010: alu_result <= ($signed(alu_src1) < $signed(alu_src2)) ? 1 : 0; // SLT
                    3'b011: alu_result <= (alu_src1 < alu_src2) ? 1 : 0; // SLTU
                    3'b100: alu_result <= alu_src1 ^ alu_src2; // XOR
                    3'b101: begin
                        case(funct7)
                            7'b0000000: alu_result <= alu_src1 >> alu_src2[4:0]; // SRL
                            7'b0100000: alu_result <= $signed(alu_src1) >>> alu_src2[4:0]; // SRA
                            default: alu_result <= 0;
                        endcase
                    end
                    3'b110: alu_result <= alu_src1 | alu_src2; // OR
                    3'b111: alu_result <= alu_src1 & alu_src2; // AND
                    default: begin
                        alu_result <= 0;
                    end
                endcase
            end
            default: begin
                alu_result <= 0;
            end
        endcase
        branch_taken <= branch & zero;
        if(branch_taken) begin
            pc_src_from_predictor <= 1;  // Correct prediction: take branch
            predict_target <= id_ex_pc + id_ex_imm/4;
            if (predictor_state != 2'b11) begin
                predictor_state <= predictor_state + 1;  // Increment counter towards "taken"
            end
        end
        else begin
            pc_src_from_predictor <= 0;  // Mispredicted: branch not taken
            predict_target <= id_ex_pc + 1;
            if (predictor_state != 2'b11) begin
                predictor_state <= predictor_state - 1;  // Increment counter towards "taken"
            end
        end
        predict_taken <= branch_taken;
        if (branch && (if_id_pred_taken != branch_taken)) begin
            flush <= 1;
        end

        ex_mem_result <= alu_result;
        ex_mem_pc <= predict_target;
        ex_mem_rd <= id_ex_rd;
        ex_mem_rs1_value <= id_ex_rs1_value;
        ex_mem_pc_src <= branch_taken;
        ex_mem_reg_write <= id_ex_reg_write;
        ex_mem_mem_read <= id_ex_mem_read;
        ex_mem_mem_write <= id_ex_mem_write;
        ex_mem_mem_to_reg <= id_ex_mem_to_reg;
        ex_mem_branch <= branch;
    end
    end

    always @(posedge clk) begin
        if(mode == 0 && switch == 0) begin
        // ex_mem_pc_src <= branch & ex_mem_zero;
        if (ex_mem_mem_read == 1) begin
            mem_wb_data <= data_mem[ ex_mem_result];
        end
        else if (ex_mem_mem_write == 1) begin
            data_mem[ex_mem_result] <= ex_mem_rs1_value;
        end
        mem_wb_alu <= ex_mem_result;
        mem_wb_rd <= ex_mem_rd;
        mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
        mem_wb_reg_write <= ex_mem_reg_write;
        end
    end

    always @(posedge clk) begin
        if(mode == 0 && switch == 0) begin
        write_data <= (mem_wb_mem_to_reg == 0)? mem_wb_alu: mem_wb_data;
        if(mem_wb_reg_write == 1) begin
            x[mem_wb_rd] <= write_data;
        end
        end
    end

endmodule
