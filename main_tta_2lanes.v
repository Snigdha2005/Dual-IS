module riscv #(parameter MEMLEN = 3, parameter XLEN = 32, parameter N = 2)(
    input clk, input mode, output reg done);

    reg [31:0] instruction_mem [0:MEMLEN-1];
    reg [31:0] data_mem [0:MEMLEN-1];
    reg [XLEN-1:0] x [0:XLEN-1];
    reg [31:0] pc;
    reg [31:0] instr [0:N-1]; 
    reg [31:0] if_id_instr [0:N-1];
    reg [31:0] ex_mem_pc;
    reg [31:0] if_id_pc, id_ex_pc;
    reg [6:0] opcode [0:N-1];
    reg [6:0]  id_ex_opcode [0:N-1];
    reg [31:0] imm;
    reg [31:0] signed_imm [0:N-1];
    reg [31:0] id_ex_imm [0:N-1];
    reg [4:0] rd [0:N-1]; 
    reg [4:0] id_ex_rd [0:N-1];
    reg [4:0] ex_mem_rd;
    reg [4:0] mem_wb_rd;
    reg [4:0] rs1[0:N-1];
    reg [4:0] id_ex_rs1 [0:N-1];
    reg [4:0] rs2 [0:N-1];
    reg [4:0] id_ex_rs2 [0:N-1];
    reg [2:0] funct3 [0:N-1];
    reg [2:0] id_ex_funct3 [0:N-1];
    reg [6:0] funct7[0:N-1];
    reg [6:0] id_ex_funct7[0:N-1];
    reg [31:0] alu_src1, alu_src2;
    reg [31:0] id_ex_rs1_value [0:N-1];
    reg [31:0]  id_ex_rs2_value [0:N-1];
    reg [31:0] forward_rs1, forward_rs2, ex_mem_rs1_value;
    reg [1:0] forwardA, forwardB;
    reg [31:0] mem_wb_data, ex_mem_result, alu_result, mem_wb_alu, write_data;
    reg [4:0] shamt;
    reg if_id_pred_taken, predict_taken, pc_src_from_predictor;
    reg [31:0] if_id_pred_target, predict_target;
    reg [1:0] predictor_state;
    reg trigger_add[0:N-1];
    reg trigger_sub[0:N-1];
    reg trigger_and[0:N-1];
    reg trigger_or[0:N-1];
    reg trigger_xor[0:N-1];
    reg trigger_srl[0:N-1];
    reg trigger_sra[0:N-1];
    reg trigger_slt[0:N-1];
    reg [31:0] add_result[0:N-1];
    reg [31:0] add_in1[0:N-1];
    reg [31:0] add_in2[0:N-1];
    reg [31:0] sub_result[0:N-1];
    reg [31:0] sub_in1[0:N-1];
    reg [31:0] sub_in2[0:N-1];
    reg [31:0] and_result[0:N-1];
    reg [31:0] and_in1[0:N-1];
    reg [31:0] and_in2[0:N-1];
    reg [31:0] or_result[0:N-1];
    reg [31:0] or_in1[0:N-1];
    reg [31:0] or_in2[0:N-1];
    reg [31:0] xor_result[0:N-1];
    reg [31:0] xor_in1[0:N-1];
    reg [31:0] xor_in2[0:N-1];
    reg [31:0] srl_result[0:N-1];
    reg [31:0] srl_in1[0:N-1];
    reg [31:0] srl_in2[0:N-1];
    reg [31:0] sra_result[0:N-1];
    reg [31:0] sra_in1[0:N-1];
    reg [31:0] sra_in2[0:N-1];
    reg [31:0] slt_result[0:N-1];
    reg [31:0] slt_in1[0:N-1];
    reg [31:0] slt_in2[0:N-1];
    reg [31:0] address[0:N-1];
    reg transport_add [0:N-1];
    reg transport_sub [0:N-1];
    reg transport_srl [0:N-1];
    reg transport_sra [0:N-1];
    reg transport_and [0:N-1];
    reg transport_or [0:N-1];
    reg transport_xor [0:N-1];
    reg transport_slt [0:N-1];
    reg [4:0] dest [0:N-1];

    reg switch;
    reg flush;
    reg zero;
    reg stall;
    reg pc_src, ex_mem_pc_src;
    reg pc_write;
    reg if_id_write;
    reg reg_write [0:N-1];
    reg id_ex_reg_write [0:N-1]; 
    reg ex_mem_reg_write, mem_wb_reg_write;
    reg alu_src [0:N-1];
    reg id_ex_alu_src [0:N-1];
    reg mem_read [0:N-1]; 
    reg id_ex_mem_read [0:N-1];
    reg ex_mem_mem_read;
    reg mem_write [0:N-1];
    reg id_ex_mem_write [0:N-1];
    reg ex_mem_mem_write;
    reg mem_to_reg [0:N-1];
    reg id_ex_mem_to_reg [0:N-1];
    reg ex_mem_mem_to_reg, mem_wb_mem_to_reg;
    reg branch, id_ex_branch, ex_mem_branch, branch_taken;

    initial begin
        // Initialize Program Counter and other special-purpose registers
        $readmemb("instruction_mem.bin", instruction_mem);
        $readmemb("data_mem.bin", data_mem);
        $readmemb("registers.bin", x);
        $display("Initialisation started");
        pc = 0;
        done = 0;
        // fcsr = 0;
        predict_target = 0;
        for(int i = 0; i < N; i = i + 1) begin
            instr[i] = 0;
            // fused_instr[i] = 0;
            if_id_instr[i] = 0;
            
            funct7[i] = 0;
            funct3[i] = 0;
            id_ex_funct3[i] = 0;
            id_ex_funct7[i] = 0;
            id_ex_imm[i] = 0;
            id_ex_opcode[i] = 0;
            
            id_ex_rd[i] = 0;
            id_ex_rs1[i] = 0;
            id_ex_rs2[i] = 0;
            id_ex_rs1_value[i] = 0;
            id_ex_rs2_value[i] = 0;
            id_ex_reg_write[i] = 0;
            id_ex_alu_src[i] = 0;
            id_ex_mem_read[i] = 0;
            id_ex_mem_write[i] = 0;
            id_ex_mem_to_reg[i] = 0;
            reg_write[i] = 0;
            alu_src[i] = 0;
            mem_read[i] = 0;
            mem_write[i] = 0;
            mem_to_reg[i] = 0;
            opcode[i] = 0;
            funct3[i] = 0;
            funct7[i] = 0;
            rd[i] = 0;
            rs1[i] = 0;
            rs2[i] = 0;
            signed_imm[i] = 0;
            add_in1[i] = 0;
            add_in2[i] = 0;
            add_result[i] = 0;
            trigger_add[i] = 0;
        end
        // instr = 0;
        // fused_instr = 0;
        shamt = 0;
        flush = 0;
        switch = 0;
        // Initialize pipeline registers
        if_id_pc = 0;
        // if_id_instr = 0;
        id_ex_pc = 0;
        
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
        
        imm = 0;
        $display("Initialisation done");
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
        $display("mode=%b, done=%b, flush = %b, pc_write = %b", mode, done, flush, pc_write);
        if(mode == 0) begin
            if(flush == 0) begin
                if(done == 0) begin
                if (pc_write) begin
                    for(int i = 0; i < N; i = i +1) begin
                        if((mode == 0 && pc + i <= MEMLEN-1) || (switch == 1 && pc + i <= MEMLEN))begin
                        instr[i] <= instruction_mem[pc + i]; 
                        $display("instr[i] = %b", instruction_mem[pc+i]);  
                        end 
                    end
                    if (pc_src_from_predictor) begin
                        pc <= predict_target;  // Branch taken, use predicted target
                    end else begin
                        pc <= pc + 1;  // No branch, increment normally
                    end
                end
                end
                if (if_id_write) begin
                    if_id_instr[0] <= instr[0];
                    if_id_pc <= (switch == 1)? pc + N: pc;
                     for(int i = 1; i < N; i = i +1) begin
                        if((mode == 0 && pc + i <= MEMLEN-1) || (switch == 1 && pc + i <= MEMLEN)) begin
                        if_id_instr[i] <= instr[i];    
                        end
                    end
                    if(switch == 0) begin
                        // if_id_pc    <= pc;
                        if_id_pred_taken <= predict_taken; 
                        if_id_pred_target <= predict_target;
                    end
                end
            end
            else begin
                instr[0] <= 0;
                pc <= pc;
                if_id_instr[0] <= instr[0];
                if_id_pc <= pc;
                if_id_pred_taken <= predict_taken; 
                if_id_pred_target <= predict_target;
            end
            if (pc >= MEMLEN) done <= 1;
            else done <= 0;
        end
        else if (mode == 1 && done == 0) begin
            for(int i = 0; i < N; i = i + 1)begin
                instr[i] <= instruction_mem[pc + i];
            end
            pc <= pc + N;
            for(int i = 0; i < N; i = i + 1)begin
                if_id_instr[i] <= instruction_mem[pc + i];
            end
            if_id_pc <= pc;
            
        end
    end

    always @(posedge clk) begin
        if (mode == 0 && switch == 0) begin
            if (flush == 0) begin
                $display("if_id_instr[0]=%b", if_id_instr[0]);
                opcode[0] <= if_id_instr[0][6:0];
                stall <= (id_ex_mem_read[0] && ((id_ex_rd[0] != 0) && ((id_ex_rd[0] == if_id_instr[0][19:15]) || (id_ex_rd[0] == if_id_instr[0][24:20])))) ? 1 : 0;
                if_id_write <= ~stall;
                pc_write <= ~stall;
                $display("stall=%b", stall);
                if (stall) begin
                    opcode[0] <= 7'b0000000;
                end

                case(opcode[0])
                        7'b0110111: begin
                            imm <= {if_id_instr[0][31:12], 12'b0};
                            rd[0] <= if_id_instr[0][11:7];
                            signed_imm[0] <= $signed(imm);
                            pc_src <= 0;
                            reg_write[0] <= 1;
                            alu_src[0] <= 1;
                            mem_read[0] <= 0;
                            mem_write[0] <= 0;
                            mem_to_reg[0] <= 0;
                            branch <= 0;
                            rs1[0] <= 0;
                            rs2[0] <= 0;
                            funct3[0] <= 0;
                            funct7[0] <= 0;
                            
                        end
                        7'b0010111: begin
                            imm <= {if_id_instr[0][31:12], 12'b0};
                            rd[0] <= if_id_instr[0][11:7];
                            signed_imm[0] <= $signed(imm);
                            pc_src <= 0;
                            reg_write[0] <= 1;
                            alu_src[0] <= 1;
                            mem_read[0] <= 0;
                            mem_write[0] <= 0;
                            mem_to_reg[0] <= 0;
                            branch <= 0;
                            rs1[0] <= 0;
                            rs2[0] <= 0;
                            funct3[0] <= 0;
                            funct7[0] <= 0;
                        end
                        7'b1101111: begin
                            imm[20] <= if_id_instr[0][31];
                            imm[10:1] <= if_id_instr[0][30:21];
                            imm[11] <= if_id_instr[0][20];
                            imm[19:12] <= if_id_instr[0][19:12];
                            imm[0] <= 1'b0;
                            signed_imm[0] <= $signed(imm);
                            rd[0] <= if_id_instr[0][11:7];
                            rs1[0] <= 0;
                            rs2[0] <= 0;
                            funct3[0] <= 0;
                            funct7[0] <= 0;
                            pc_src <= 1;
                            reg_write[0] <= 1;
                            alu_src[0] <= 0;
                            mem_read[0] <= 0;
                            mem_write[0] <= 0;
                            mem_to_reg[0] <= 0;
                            branch <= 0;
                        end
                        7'b1100111: begin
                            imm[11:0] <= if_id_instr[0][31:20];
                            signed_imm[0] <= $signed(imm);
                            rs1[0] <= if_id_instr[0][19:15];
                            funct3[0] <= if_id_instr[0][14:12];
                            rd[0] <= if_id_instr[0][11:7];
                            
                            // rs1[0] <= 0;
                            rs2[0] <= 0;
                            // funct3[0] <= 0;
                            funct7[0] <= 0;
                            pc_src <= 1;
                            reg_write[0] <= 1;
                            alu_src[0] <= 1;
                            mem_read[0] <= 0;
                            mem_write[0] <= 0;
                            mem_to_reg[0] <= 0;
                            branch <= 0;
                        end
                        7'b1100011: begin
                            funct3[0] <= if_id_instr[0][14:12];
                            imm[12] <= if_id_instr[0][31];
                            imm[10:5] <= if_id_instr[0][30:25];
                            imm[4:1] <= if_id_instr[0][11:8];
                            imm[11] <= if_id_instr[0][7];
                            signed_imm[0] <= $signed(imm);
                            rs2[0] <= if_id_instr[0][24:20];
                            rs1[0] <= if_id_instr[0][19:15];
                            
                            // rs1[0] <= 0;
                            // rs2[0] <= 0;
                            // funct3[0] <= 0;
                            
                            case(funct3[0])
                                3'b000: begin
                                    funct7[0] <= 0;
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 1;

                                end
                                3'b001: begin
                                    funct7[0] <= 0;
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 1;
                                end
                                3'b100: begin
                                    funct7[0] <= 0;
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 1;
                                end
                                3'b101: begin
                                    funct7[0] <= 0;
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 1;
                                end
                                3'b110: begin
                                    funct7[0] <= 0;
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 1;
                                end
                                3'b111: begin
                                    funct7[0] <= 0;
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 1;
                                end
                                default: begin
                                    funct7[0] <= 0;
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                            endcase
                        end
                        7'b0000011: begin
                            imm[11:0] <= if_id_instr[0][31:20];
                            signed_imm[0] <= $signed(imm);
                            rs1[0] <= if_id_instr[0][19:15];
                            funct3[0] <= if_id_instr[0][14:12];
                            rd[0] <= if_id_instr[0][11:7];
                            // rs1[0] <= 0;
                            rs2[0] <= 0;
                            // funct3[0] <= 0;
                            funct7[0] <= 0;
                            case(funct3[0])
                                3'b000: begin
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 1;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 1;
                                    branch <= 0;
                                end
                                3'b001: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 1;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 1;
                                    branch <= 0;
                                end
                                3'b010: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 1;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 1;
                                    branch <= 0;
                                end
                                3'b100: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 1;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 1;
                                    branch <= 0;
                                end
                                3'b101: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 1;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 1;
                                    branch <= 0;
                                end
                                default: begin
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                            endcase
                        end
                        7'b0100011: begin
                            imm[11:5] <= if_id_instr[0][31:25];
                            imm[4:0] <= if_id_instr[0][11:7];
                            rs2[0] <= if_id_instr[0][24:20];
                            rs1[0] <= if_id_instr[0][19:15];
                            funct3[0] <= if_id_instr[0][14:12];
                            // rs1[0] <= 0;
                            // rs2[0] <= 0;
                            // funct3[0] <= 0;
                            funct7[0] <= 0;
                            case(funct3[0])
                                3'b000: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 1;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b001: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 1;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b010: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 1;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                default: begin
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                            endcase
                        end
                        7'b0010011: begin
                            rs1[0] <= if_id_instr[0][19:15];
                            funct3[0] <= if_id_instr[0][14:12];
                            rd[0] <= if_id_instr[0][11:7];
                            // rs1[0] <= 0;
                            // rs2[0] <= 0;
                            // funct3[0] <= 0;
                            // funct7[0] <= 0;
                            // signed_imm[0] <= 0;
                            case(funct3[0])
                                3'b000: begin
                                    imm[11:0] <= if_id_instr[0][31:20];
                                    signed_imm[0] <= $signed(imm);
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b010: begin
                                    imm[11:0] <= if_id_instr[0][31:20];
                                    signed_imm[0] <= $signed(imm);
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b011: begin
                                    imm[11:0] <= if_id_instr[0][31:20];
                                    signed_imm[0] <= $signed(imm);
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b100: begin
                                    imm[11:0] <= if_id_instr[0][31:20];
                                    signed_imm[0] <= $signed(imm);
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b110: begin
                                    imm[11:0] <= if_id_instr[0][31:20];
                                    signed_imm[0] <= $signed(imm);
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b111: begin
                                    imm[11:0] <= if_id_instr[0][31:20];
                                    signed_imm[0] <= $signed(imm);
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b001: begin
                                    funct7[0] <= if_id_instr[0][31:25];
                                    shamt <= if_id_instr[0][24:20];
                                    // signed_imm[0] <= 0;
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 1;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b101: begin
                                    funct7[0] <= if_id_instr[0][31:25];
                                    shamt <= if_id_instr[0][24:20];
                                    case(funct7[0])
                                        7'b0000000: begin
                                            
                                            pc_src <= 0;
                                            reg_write[0] <= 1;
                                            alu_src[0] <= 1;
                                            mem_read[0] <= 0;
                                            mem_write[0] <= 0;
                                            mem_to_reg[0] <= 0;
                                            branch <= 0;
                                        end
                                        7'b0100000: begin
                                            
                                            pc_src <= 0;
                                            reg_write[0] <= 1;
                                            alu_src[0] <= 1;
                                            mem_read[0] <= 0;
                                            mem_write[0] <= 0;
                                            mem_to_reg[0] <= 0;
                                            branch <= 0;
                                        end
                                        default: begin
                                            
                                            pc_src <= 0;
                                            reg_write[0] <= 0;
                                            alu_src[0] <= 0;
                                            mem_read[0] <= 0;
                                            mem_write[0] <= 0;
                                            mem_to_reg[0] <= 0;
                                            branch <= 0;
                                        end
                                        
                                    endcase
                                end
                                default: begin
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                            endcase
                        end
                        7'b0110011: begin
                            funct7[0] <= if_id_instr[0][31:25];
                            funct3[0] <= if_id_instr[0][14:12];
                            rs2[0] <= if_id_instr[0][24:20];
                            rs1[0] <= if_id_instr[0][19:15];
                            rd[0] <= if_id_instr[0][11:7];
                            // signed_imm[0] <= 0;
                            case(funct3[0])
                                3'b000: begin
                                    case(funct7[0])
                                        7'b0000000: begin
                                            
                                            pc_src <= 0;
                                            reg_write[0] <= 1;
                                            alu_src[0] <= 0;
                                            mem_read[0] <= 0;
                                            mem_write[0] <= 0;
                                            mem_to_reg[0] <= 0;
                                            branch <= 0;
                                        end
                                        7'b0100000: begin
                                            
                                            pc_src <= 0;
                                            reg_write[0] <= 1;
                                            alu_src[0] <= 0;
                                            mem_read[0] <= 0;
                                            mem_write[0] <= 0;
                                            mem_to_reg[0] <= 0;
                                            branch <= 0;
                                        end
                                        default: begin
                                            pc_src <= 0;
                                            reg_write[0] <= 0;
                                            alu_src[0] <= 0;
                                            mem_read[0] <= 0;
                                            mem_write[0] <= 0;
                                            mem_to_reg[0] <= 0;
                                            branch <= 0;
                                        end
                                    endcase
                                end
                                3'b001: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b010: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b011: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b100: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b101: begin
                                    case(funct7[0])
                                        7'b0000000: begin
                                            
                                            pc_src <= 0;
                                            reg_write[0] <= 1;
                                            alu_src[0] <= 0;
                                            mem_read[0] <= 0;
                                            mem_write[0] <= 0;
                                            mem_to_reg[0] <= 0;
                                            branch <= 0;
                                        end
                                        7'b0100000: begin
                                            
                                            pc_src <= 0;
                                            reg_write[0] <= 1;
                                            alu_src[0] <= 0;
                                            mem_read[0] <= 0;
                                            mem_write[0] <= 0;
                                            mem_to_reg[0] <= 0;
                                            branch <= 0;
                                        end
                                        default: begin
                                            pc_src <= 0;
                                            reg_write[0] <= 0;
                                            alu_src[0] <= 0;
                                            mem_read[0] <= 0;
                                            mem_write[0] <= 0;
                                            mem_to_reg[0] <= 0;
                                            branch <= 0;
                                        end
                                    endcase
                                end
                                3'b110: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                3'b111: begin
                                    
                                    pc_src <= 0;
                                    reg_write[0] <= 1;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                                default: begin
                                    pc_src <= 0;
                                    reg_write[0] <= 0;
                                    alu_src[0] <= 0;
                                    mem_read[0] <= 0;
                                    mem_write[0] <= 0;
                                    mem_to_reg[0] <= 0;
                                    branch <= 0;
                                end
                            endcase
                        end
                        7'b0000000: begin
                            
                            pc_src <= 0;
                            reg_write[0] <= 0;
                            alu_src[0] <= 0;
                            mem_read[0] <= 0;
                            mem_write[0] <= 0;
                            mem_to_reg[0] <= 0;
                            branch <= 0;
                        end
                        default: begin
                            pc_src <= 0;
                            reg_write[0] <= 0;
                            alu_src[0] <= 0;
                            mem_read[0] <= 0;
                            mem_write[0] <= 0;
                            mem_to_reg[0] <= 0;
                            branch <= 0;
                        end
                    endcase
                    $display("opcode=%b, imm=%b, rd=%b", opcode[0], signed_imm[0], rd[0]);
                    id_ex_rs2_value[0] <= x[rs2[0]];
                    id_ex_rs1_value[0] <= x[rs1[0]];
                    id_ex_rd[0] <= rd[0];
                    id_ex_rs1[0] <= rs1[0];
                    id_ex_rs2[0] <= rs2[0];
                    id_ex_imm[0] <= signed_imm[0];
                    id_ex_opcode[0] <= opcode[0];
                    id_ex_pc <= if_id_pc;
                    id_ex_reg_write[0] <= reg_write[0];
                    id_ex_alu_src[0] <= alu_src[0];
                    id_ex_mem_read[0] <= mem_read[0];
                    id_ex_mem_write[0] <= mem_write[0];
                    id_ex_mem_to_reg[0] <= mem_to_reg[0];
                    id_ex_branch <= branch;

                for(int i = N-1; i >= 1; i = i - 1)begin
                    opcode[i] <= if_id_instr[i][6:0];
                    case(opcode[i])
                        7'b0110111: begin
                            imm <= {if_id_instr[i][31:12], 12'b0};
                            rd[i] <= if_id_instr[i][11:7];
                            signed_imm[i] <= $signed(imm);
                            // pc_src <= 0;
                            reg_write[i] <= 1;
                            alu_src[i] <= 1;
                            mem_read[i] <= 0;
                            mem_write[i] <= 0;
                            mem_to_reg[i] <= 0;
                            // branch <= 0;
                            
                        end
                        7'b0010111: begin
                            imm <= {if_id_instr[i][31:12], 12'b0};
                            rd[i] <= if_id_instr[i][11:7];
                            signed_imm[i] <= $signed(imm);
                            // pc_src <= 0;
                            reg_write[i] <= 1;
                            alu_src[i] <= 1;
                            mem_read[i] <= 0;
                            mem_write[i] <= 0;
                            mem_to_reg[i] <= 0;
                            // branch <= 0;
                        end
                        7'b1101111: begin
                            imm[20] <= if_id_instr[i][31];
                            imm[10:1] <= if_id_instr[i][30:21];
                            imm[11] <= if_id_instr[i][20];
                            imm[19:12] <= if_id_instr[i][19:12];
                            imm[0] <= 1'b0;
                            signed_imm[i] <= $signed(imm);
                            rd[i] <= if_id_instr[i][11:7];
                            // pc_src <= 1;
                            reg_write[i] <= 1;
                            alu_src[i] <= 0;
                            mem_read[i] <= 0;
                            mem_write[i] <= 0;
                            mem_to_reg[i] <= 0;
                            // branch <= 0;
                        end
                        7'b1100111: begin
                            imm[11:0] <= if_id_instr[i][31:20];
                            signed_imm[i] <= $signed(imm);
                            rs1[i] <= if_id_instr[i][19:15];
                            funct3[i] <= if_id_instr[i][14:12];
                            rd[i] <= if_id_instr[i][11:7];
                            // pc_src <= 1;
                            reg_write[i] <= 1;
                            alu_src[i] <= 1;
                            mem_read[i] <= 0;
                            mem_write[i] <= 0;
                            mem_to_reg[i] <= 0;
                            // branch <= 0;
                        end
                        7'b1100011: begin
                            funct3[i] <= if_id_instr[i][14:12];
                            imm[12] <= if_id_instr[i][31];
                            imm[10:5] <= if_id_instr[i][30:25];
                            imm[4:1] <= if_id_instr[i][11:8];
                            imm[11] <= if_id_instr[i][7];
                            signed_imm[i] <= $signed(imm);
                            rs2[i] <= if_id_instr[i][24:20];
                            rs1[i] <= if_id_instr[i][19:15];
                            case(funct3[i])
                                3'b000: begin
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 1;
                                end
                                3'b001: begin
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 1;
                                end
                                3'b100: begin
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 1;
                                end
                                3'b101: begin
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 1;
                                end
                                3'b110: begin
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 1;
                                end
                                3'b111: begin
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 1;
                                end
                                default: begin
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                            endcase
                        end
                        7'b0000011: begin
                            imm[11:0] <= if_id_instr[i][31:20];
                            signed_imm[i] <= $signed(imm);
                            rs1[i] <= if_id_instr[i][19:15];
                            funct3[i] <= if_id_instr[i][14:12];
                            rd[i] <= if_id_instr[i][11:7];
                            case(funct3[i])
                                3'b000: begin
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 1;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 1;
                                    // branch <= 0;
                                end
                                3'b001: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 1;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 1;
                                    // branch <= 0;
                                end
                                3'b010: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 1;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 1;
                                    // branch <= 0;
                                end
                                3'b100: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 1;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 1;
                                    // branch <= 0;
                                end
                                3'b101: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 1;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 1;
                                    // branch <= 0;
                                end
                                default: begin
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                            endcase
                        end
                        7'b0100011: begin
                            imm[11:5] <= if_id_instr[i][31:25];
                            imm[4:0] <= if_id_instr[i][11:7];
                            rs2[i] <= if_id_instr[i][24:20];
                            rs1[i] <= if_id_instr[i][19:15];
                            funct3[i] <= if_id_instr[i][14:12];
                            case(funct3[i])
                                3'b000: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 1;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b001: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 1;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b010: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 1;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                default: begin
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                            endcase
                        end
                        7'b0010011: begin
                            rs1[i] <= if_id_instr[i][19:15];
                            funct3[i] <= if_id_instr[i][14:12];
                            rd[i] <= if_id_instr[i][11:7];
                            case(funct3[i])
                                3'b000: begin
                                    imm[11:0] <= if_id_instr[i][31:20];
                                    signed_imm[i] <= $signed(imm);
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b010: begin
                                    imm[11:0] <= if_id_instr[i][31:20];
                                    signed_imm[i] <= $signed(imm);
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b011: begin
                                    imm[11:0] <= if_id_instr[i][31:20];
                                    signed_imm[i] <= $signed(imm);
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b100: begin
                                    imm[11:0] <= if_id_instr[i][31:20];
                                    signed_imm[i] <= $signed(imm);
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b110: begin
                                    imm[11:0] <= if_id_instr[i][31:20];
                                    signed_imm[i] <= $signed(imm);
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b111: begin
                                    imm[11:0] <= if_id_instr[i][31:20];
                                    signed_imm[i] <= $signed(imm);
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b001: begin
                                    funct7[i] <= if_id_instr[i][31:25];
                                    shamt <= if_id_instr[i][24:20];
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b101: begin
                                    funct7[i] <= if_id_instr[i][31:25];
                                    shamt <= if_id_instr[i][24:20];
                                    case(funct7[i])
                                        7'b0000000: begin
                                            
                                            // pc_src <= 0;
                                            reg_write[i] <= 1;
                                            alu_src[i] <= 1;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            // branch <= 0;
                                        end
                                        7'b0100000: begin
                                            
                                            // pc_src <= 0;
                                            reg_write[i] <= 1;
                                            alu_src[i] <= 1;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            // branch <= 0;
                                        end
                                        default: begin
                                            
                                            // pc_src <= 0;
                                            reg_write[i] <= 0;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            // branch <= 0;
                                        end
                                        
                                    endcase
                                end
                                default: begin
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                            endcase
                        end
                        7'b0110011: begin
                            funct7[i] <= if_id_instr[i][31:25];
                            funct3[i] <= if_id_instr[i][14:12];
                            rs2[i] <= if_id_instr[i][24:20];
                            rs1[i] <= if_id_instr[i][19:15];
                            rd[i] <= if_id_instr[i][11:7];
                            case(funct3[i])
                                3'b000: begin
                                    case(funct7[i])
                                        7'b0000000: begin
                                            
                                            // pc_src <= 0;
                                            reg_write[i] <= 1;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            // branch <= 0;
                                        end
                                        7'b0100000: begin
                                            
                                            // pc_src <= 0;
                                            reg_write[i] <= 1;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            // branch <= 0;
                                        end
                                        default: begin
                                            // pc_src <= 0;
                                            reg_write[i] <= 0;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            // branch <= 0;
                                        end
                                    endcase
                                end
                                3'b001: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b010: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b011: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b100: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b101: begin
                                    case(funct7[i])
                                        7'b0000000: begin
                                            
                                            // pc_src <= 0;
                                            reg_write[i] <= 1;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            // branch <= 0;
                                        end
                                        7'b0100000: begin
                                            
                                            // pc_src <= 0;
                                            reg_write[i] <= 1;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            // branch <= 0;
                                        end
                                        default: begin
                                            // pc_src <= 0;
                                            reg_write[i] <= 0;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            // branch <= 0;
                                        end
                                    endcase
                                end
                                3'b110: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                3'b111: begin
                                    
                                    // pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                                default: begin
                                    // pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    // branch <= 0;
                                end
                            endcase
                        end
                        7'b0000000: begin
                            
                            // pc_src <= 0;
                            reg_write[i] <= 0;
                            alu_src[i] <= 0;
                            mem_read[i] <= 0;
                            mem_write[i] <= 0;
                            mem_to_reg[i] <= 0;
                            // branch <= 0;
                        end
                        default: begin
                            // pc_src <= 0;
                            reg_write[i] <= 0;
                            alu_src[i] <= 0;
                            mem_read[i] <= 0;
                            mem_write[i] <= 0;
                            mem_to_reg[i] <= 0;
                            // branch <= 0;
                        end
                    endcase
                    $display("opcode=%b, imm=%b, rd=%b", opcode[i], signed_imm[i], rd[i]);
                    id_ex_rs2_value[i] <= x[rs2[i]];
                    id_ex_rs1_value[i] <= x[rs1[i]];
                    id_ex_rs1[i] <= rs1[i];
                    id_ex_rs2[i] <= rs2[i];
                    id_ex_imm[i] <= signed_imm[i];
                    id_ex_opcode[i] <= opcode[i];
                    // id_ex_pc <= if_id_pc;
                    id_ex_rd[i] <= rd[i];
                    id_ex_reg_write[i] <= reg_write[i];
                    id_ex_alu_src[i] <= alu_src[i];
                    id_ex_mem_read[i] <= mem_read[i];
                    id_ex_mem_write[i] <= mem_write[i];
                    id_ex_mem_to_reg[i] <= mem_to_reg[i];
                    // id_ex_branch <= branch;
                end
            end
            else if(flush == 1) begin
                id_ex_rs2_value[0] <= 0;
                id_ex_rs1_value[0] <= 0;
                id_ex_rs1[0] <= 0;
                id_ex_rs2[0] <= 0;
                id_ex_imm[0] <= 0;
                id_ex_opcode[0] <= 0;
                id_ex_pc <= 0;
                id_ex_rd[0] <= 0;
                id_ex_reg_write[0] <= 0;
                id_ex_alu_src[0] <= 0;
                id_ex_mem_read[0] <= 0;
                id_ex_mem_write[0] <= 0;
                id_ex_mem_to_reg[0] <= 0;
                id_ex_branch <= 0;
                end
        end
        else if (mode == 1 && done == 0) begin
            for(int i = 0; i < N; i = i + 1) begin
                opcode[i] <= if_id_instr[i][6:0];
            end
            for(int i = N-1; i >= 0; i = i - 1)begin
                    case(opcode[i])
                        7'b0110111: begin
                            imm <= {if_id_instr[i][31:12], 12'b0};
                            rd[i] <= if_id_instr[i][11:7];
                            signed_imm[i] <= $signed(imm);
                            pc_src <= 0;
                            reg_write[i] <= 1;
                            alu_src[i] <= 1;
                            mem_read[i] <= 0;
                            mem_write[i] <= 0;
                            mem_to_reg[i] <= 0;
                            branch <= 0;
                        end
                        7'b0010111: begin
                            imm <= {if_id_instr[i][31:12], 12'b0};
                            rd[i] <= if_id_instr[i][11:7];
                            signed_imm[i] <= $signed(imm);
                            pc_src <= 0;
                            reg_write[i] <= 1;
                            alu_src[i] <= 1;
                            mem_read[i] <= 0;
                            mem_write[i] <= 0;
                            mem_to_reg[i] <= 0;
                            branch <= 0;
                        end
                        7'b1101111: begin
                            imm[20] <= if_id_instr[i][31];
                            imm[10:1] <= if_id_instr[i][30:21];
                            imm[11] <= if_id_instr[i][20];
                            imm[19:12] <= if_id_instr[i][19:12];
                            imm[0] <= 1'b0;
                            signed_imm[i] <= $signed(imm);
                            rd[i] <= if_id_instr[i][11:7];
                            pc_src <= 1;
                            reg_write[i] <= 1;
                            alu_src[i] <= 0;
                            mem_read[i] <= 0;
                            mem_write[i] <= 0;
                            mem_to_reg[i] <= 0;
                            branch <= 0;
                        end
                        7'b1100111: begin
                            imm[11:0] <= if_id_instr[i][31:20];
                            signed_imm[i] <= $signed(imm);
                            rs1[i] <= if_id_instr[i][19:15];
                            funct3[i] <= if_id_instr[i][14:12];
                            rd[i] <= if_id_instr[i][11:7];
                            pc_src <= 1;
                            reg_write[i] <= 1;
                            alu_src[i] <= 1;
                            mem_read[i] <= 0;
                            mem_write[i] <= 0;
                            mem_to_reg[i] <= 0;
                            branch <= 0;
                        end
                        7'b1100011: begin
                            funct3[i] <= if_id_instr[i][14:12];
                            imm[12] <= if_id_instr[i][31];
                            imm[10:5] <= if_id_instr[i][30:25];
                            imm[4:1] <= if_id_instr[i][11:8];
                            imm[11] <= if_id_instr[i][7];
                            signed_imm[i] <= $signed(imm);
                            rs2[i] <= if_id_instr[i][24:20];
                            rs1[i] <= if_id_instr[i][19:15];
                            case(funct3[i])
                                3'b000: begin
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 1;
                                end
                                3'b001: begin
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 1;
                                end
                                3'b100: begin
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 1;
                                end
                                3'b101: begin
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 1;
                                end
                                3'b110: begin
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 1;
                                end
                                3'b111: begin
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 1;
                                end
                                default: begin
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                            endcase
                        end
                        7'b0000011: begin
                            imm[11:0] <= if_id_instr[i][31:20];
                            signed_imm[i] <= $signed(imm);
                            rs1[i] <= if_id_instr[i][19:15];
                            funct3[i] <= if_id_instr[i][14:12];
                            rd[i] <= if_id_instr[i][11:7];
                            case(funct3[i])
                                3'b000: begin
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 1;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 1;
                                    branch <= 0;
                                end
                                3'b001: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 1;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 1;
                                    branch <= 0;
                                end
                                3'b010: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 1;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 1;
                                    branch <= 0;
                                end
                                3'b100: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 1;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 1;
                                    branch <= 0;
                                end
                                3'b101: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 1;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 1;
                                    branch <= 0;
                                end
                                default: begin
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                            endcase
                        end
                        7'b0100011: begin
                            imm[11:5] <= if_id_instr[i][31:25];
                            imm[4:0] <= if_id_instr[i][11:7];
                            rs2[i] <= if_id_instr[i][24:20];
                            rs1[i] <= if_id_instr[i][19:15];
                            funct3[i] <= if_id_instr[i][14:12];
                            case(funct3[i])
                                3'b000: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 1;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b001: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 1;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b010: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 1;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                default: begin
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                            endcase
                        end
                        7'b0010011: begin
                            rs1[i] <= if_id_instr[i][19:15];
                            funct3[i] <= if_id_instr[i][14:12];
                            rd[i] <= if_id_instr[i][11:7];
                            case(funct3[i])
                                3'b000: begin
                                    imm[11:0] <= if_id_instr[i][31:20];
                                    signed_imm[i] <= $signed(imm);
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b010: begin
                                    imm[11:0] <= if_id_instr[i][31:20];
                                    signed_imm[i] <= $signed(imm);
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b011: begin
                                    imm[11:0] <= if_id_instr[i][31:20];
                                    signed_imm[i] <= $signed(imm);
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b100: begin
                                    imm[11:0] <= if_id_instr[i][31:20];
                                    signed_imm[i] <= $signed(imm);
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b110: begin
                                    imm[11:0] <= if_id_instr[i][31:20];
                                    signed_imm[i] <= $signed(imm);
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b111: begin
                                    imm[11:0] <= if_id_instr[i][31:20];
                                    signed_imm[i] <= $signed(imm);
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b001: begin
                                    funct7[i] <= if_id_instr[i][31:25];
                                    shamt <= if_id_instr[i][24:20];
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 1;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b101: begin
                                    funct7[i] <= if_id_instr[i][31:25];
                                    shamt <= if_id_instr[i][24:20];
                                    case(funct7[i])
                                        7'b0000000: begin
                                            
                                            pc_src <= 0;
                                            reg_write[i] <= 1;
                                            alu_src[i] <= 1;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            branch <= 0;
                                        end
                                        7'b0100000: begin
                                            
                                            pc_src <= 0;
                                            reg_write[i] <= 1;
                                            alu_src[i] <= 1;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            branch <= 0;
                                        end
                                        default: begin
                                            
                                            pc_src <= 0;
                                            reg_write[i] <= 0;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            branch <= 0;
                                        end
                                        
                                    endcase
                                end
                                default: begin
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                            endcase
                        end
                        7'b0110011: begin
                            funct7[i] <= if_id_instr[i][31:25];
                            funct3[i] <= if_id_instr[i][14:12];
                            rs2[i] <= if_id_instr[i][24:20];
                            rs1[i] <= if_id_instr[i][19:15];
                            case(funct3[i])
                                3'b000: begin
                                    case(funct7[i])
                                        7'b0000000: begin
                                            
                                            pc_src <= 0;
                                            reg_write[i] <= 1;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            branch <= 0;
                                        end
                                        7'b0100000: begin
                                            
                                            pc_src <= 0;
                                            reg_write[i] <= 1;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            branch <= 0;
                                        end
                                        default: begin
                                            pc_src <= 0;
                                            reg_write[i] <= 0;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            branch <= 0;
                                        end
                                    endcase
                                end
                                3'b001: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b010: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b011: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b100: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b101: begin
                                    case(funct7[i])
                                        7'b0000000: begin
                                            
                                            pc_src <= 0;
                                            reg_write[i] <= 1;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            branch <= 0;
                                        end
                                        7'b0100000: begin
                                            
                                            pc_src <= 0;
                                            reg_write[i] <= 1;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            branch <= 0;
                                        end
                                        default: begin
                                            pc_src <= 0;
                                            reg_write[i] <= 0;
                                            alu_src[i] <= 0;
                                            mem_read[i] <= 0;
                                            mem_write[i] <= 0;
                                            mem_to_reg[i] <= 0;
                                            branch <= 0;
                                        end
                                    endcase
                                end
                                3'b110: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                3'b111: begin
                                    
                                    pc_src <= 0;
                                    reg_write[i] <= 1;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                                default: begin
                                    pc_src <= 0;
                                    reg_write[i] <= 0;
                                    alu_src[i] <= 0;
                                    mem_read[i] <= 0;
                                    mem_write[i] <= 0;
                                    mem_to_reg[i] <= 0;
                                    branch <= 0;
                                end
                            endcase
                        end
                        7'b0000000: begin
                            
                            pc_src <= 0;
                            reg_write[i] <= 0;
                            alu_src[i] <= 0;
                            mem_read[i] <= 0;
                            mem_write[i] <= 0;
                            mem_to_reg[i] <= 0;
                            branch <= 0;
                        end
                        default: begin
                            pc_src <= 0;
                            reg_write[i] <= 0;
                            alu_src[i] <= 0;
                            mem_read[i] <= 0;
                            mem_write[i] <= 0;
                            mem_to_reg[i] <= 0;
                            branch <= 0;
                        end
                    endcase

                    id_ex_rs2_value[i] <= x[rs2[i]];
                    id_ex_rs1_value[i] <= x[rs1[i]];
                    id_ex_rs1[i] <= rs1[i];
                    id_ex_rs2[i] <= rs2[i];
                    id_ex_imm[i] <= signed_imm[i];
                    id_ex_opcode[i] <= opcode[i];
                    id_ex_pc <= if_id_pc;
                    id_ex_rd[i] <= rd[i];
                    id_ex_funct3[i] <= funct3[i];
                    id_ex_funct7[i] <= funct7[i];
                    id_ex_reg_write[i] <= reg_write[i];
                    id_ex_alu_src[i] <= alu_src[i];
                    id_ex_mem_read[i] <= mem_read[i];
                    id_ex_mem_write[i] <= mem_write[i];
                    id_ex_mem_to_reg[i] <= mem_to_reg[i];
                    id_ex_branch <= branch;
            end
        end
    end

    always @(id_ex_rs1[1], id_ex_rs1[2], id_ex_rs1[3], id_ex_rs2[1], id_ex_rs2[2], id_ex_rs2[3], id_ex_rd[0], id_ex_rd[1], id_ex_rd[2], id_ex_rd[3]) begin
        if (id_ex_opcode[0] != 7'b1100011 && id_ex_opcode[1] != 7'b1100011 && id_ex_opcode[2] != 7'b1100011 && id_ex_opcode[3] != 7'b1100011) begin
            if (id_ex_rs1[1] == id_ex_rd[0] || id_ex_rs2[1] == id_ex_rd[0]) switch = 0;
            // else if (id_ex_rs1[2] == id_ex_rd[0] || id_ex_rs2[2] == id_ex_rd[0]) switch = 0;
            // else if (id_ex_rs1[2] == id_ex_rd[1] || id_ex_rs2[2] == id_ex_rd[1]) switch = 0;
            // else if (id_ex_rs1[3] == id_ex_rd[0] || id_ex_rs2[3] == id_ex_rd[0]) switch = 0;
            // else if (id_ex_rs1[3] == id_ex_rd[1] || id_ex_rs2[3] == id_ex_rd[1]) switch = 0;
            // else if (id_ex_rs1[3] == id_ex_rd[2] || id_ex_rs2[3] == id_ex_rd[2]) switch = 0;
            else switch = 1;
        end
    end
    // ADD Unit
    always @(posedge clk) begin
        if (trigger_add[0] || transport_add[0]) begin 
            add_result[0] <= add_in1[0] + add_in2[0];
            if(dest[0] != 0)
            x[dest[0]] <= add_result[0];
        end
    end

    // SUB Unit
    always @(posedge clk) begin
        if (trigger_sub[0] || transport_sub[0]) begin
            sub_result[0] <= sub_in1[0] - sub_in2[0];
            if(dest[0] != 0)
            x[dest[0]] <= sub_result[0];
        end
    end

    // Logical Units
    always @(posedge clk) begin
        if (trigger_and[0] || transport_and[0]) begin 
            and_result[0] <= and_in1[0] & and_in2[0];
            if (dest[0] != 0) x[dest[0]] <= and_result[0];
        end 
        if (trigger_or[0] || transport_or[0]) begin 
            or_result[0]  <= or_in1[0]  | or_in2[0];
            if (dest[0] != 0) x[dest[0]] <= or_result[0];
        end
        if (trigger_xor[0] || transport_xor[0]) begin 
            xor_result[0] <= xor_in1[0] ^ xor_in2[0];
            if (dest[0] != 0) x[dest[0]] <= xor_result[0];
        end
    end

    // Shift Units
    always @(posedge clk) begin
        if (trigger_srl[0] || transport_srl[0]) begin 
            srl_result[0] <= srl_in1[0] >> srl_in2[0];
            if(dest[0] != 0) x[dest[0]] <= srl_result[0];
        end
        if (trigger_sra[0] || transport_sra[0]) begin
            sra_result[0] <= $signed(sra_in1[0]) >>> sra_in2[0];
            if(dest[0] != 0) x[dest[0]] <= sra_result[0];
        end
    end

    // Compare Units
    always @(posedge clk) begin
        if (trigger_slt[0] || transport_slt[0]) begin
            slt_result[0] <= ($signed(slt_in1[0]) < $signed(slt_in2[0])) ? 1 : 0;
            if(dest[0] != 0) x[dest[0]] <= slt_result[0];
        end
    end

    always @(posedge clk) begin
        if((switch == 1 || mode == 1)) begin
            case (opcode[0])
                7'b0000011: begin // LW
                    address[0] <= x[id_ex_rs1[0]] + id_ex_imm[0];
                    x[id_ex_rd[0]] <= data_mem[address[0]];
                end
                7'b0100011: begin // SW
                    address[0] <= x[id_ex_rs1[0]] + id_ex_imm[0];
                    data_mem[address[0]] <= x[id_ex_rs2[0]];
                end
                7'b0110011: begin // R-type (ADD, SUB, etc.)
                    case (id_ex_funct3[0])
                        3'b000: begin
                            if (id_ex_funct7[0] == 7'b0000000) begin // ADD
                                transport_add[0] <= 1;
                                add_in1[0] <= id_ex_rs1_value[0];
                                add_in2[0] <= id_ex_rs2_value[0];
                                dest[0] <= id_ex_rd[0];
                            end else if (id_ex_funct7[0] == 7'b0100000) begin // SUB
                                transport_sub[0] <= 1;
                                sub_in1[0] <= id_ex_rs1_value[0];
                                sub_in2[0] <= id_ex_rs2_value[0];
                                dest[0] <= id_ex_rd[0];
                            end
                        end
                        3'b111: begin transport_and[0] <= 1; and_in1[0] <= id_ex_rs1_value[0]; and_in2[0] <= id_ex_rs2_value[0]; dest[0] <= id_ex_rd[0]; end
                        3'b110: begin transport_or[0]  <= 1; or_in1[0] <= id_ex_rs1_value[0]; or_in2[0] <= id_ex_rs2_value[0]; dest[0] <= id_ex_rd[0]; end
                        3'b100: begin transport_xor[0] <= 1; xor_in1[0] <= id_ex_rs1_value[0]; xor_in2[0] <= id_ex_rs2_value[0]; dest[0] <= id_ex_rd[0]; end
                        3'b010: begin transport_slt[0] <= 1; slt_in1[0] <= id_ex_rs1_value[0]; slt_in2[0] <= id_ex_rs2_value[0]; dest[0] <= id_ex_rd[0]; end
                        3'b101: begin
                            if (id_ex_funct7[0] == 7'b0000000) begin transport_srl[0] <= 1; srl_in1[0] <= id_ex_rs1_value[0]; srl_in2[0] <= id_ex_rs2_value[0]; dest[0] <= id_ex_rd[0]; end
                            else if (id_ex_funct7[0] == 7'b0100000) begin transport_sra[0] <= 1; sra_in1[0] <= id_ex_rs1_value[0]; sra_in2[0] <= id_ex_rs2_value[0]; dest[0] <= id_ex_rd[0]; end
                        end
                    endcase
                end
                7'b0010011: begin // I-type (ADDI, ANDI, etc.)
                    case (id_ex_funct3[0])
                        3'b000: begin // ADDI
                            add_in1[0] <= x[id_ex_rs1[0]];
                            add_in2[0] <= id_ex_imm[0];
                            trigger_add[0] <= 1;
                            x[id_ex_rd[0]] <= add_result[0];
                        end
                        3'b111: begin x[id_ex_rd[0]] <= x[id_ex_rs1[0]] & id_ex_imm[0]; end // ANDI
                        3'b110: begin x[id_ex_rd[0]] <= x[id_ex_rs1[0]] | id_ex_imm[0]; end // ORI
                        3'b100: begin x[id_ex_rd[0]] <= x[id_ex_rs1[0]] ^ id_ex_imm[0]; end // XORI
                        3'b010: begin x[id_ex_rd[0]] <= ($signed(x[id_ex_rs1[0]]) < $signed(id_ex_imm[0])) ? 1 : 0; end // SLTI
                        3'b101: begin
                            if (id_ex_funct7[0] == 7'b0000000) x[id_ex_rd[0]] <= x[id_ex_rs1[0]] >> id_ex_imm[0]; // SRLI
                            else if (id_ex_funct7[0] == 7'b0100000) x[id_ex_rd[0]] <= $signed(x[id_ex_rs1[0]]) >>> id_ex_imm[0]; // SRAI
                        end
                    endcase
                end
            endcase
        end
    end
    // ADD Unit
    // always @(posedge clk) begin
    //     if (trigger_add[2] || transport_add[2]) begin 
    //         add_result[2] <= add_in1[2] + add_in2[2];
    //         if(dest[2] != 0)
    //         x[dest[2]] <= add_result[2];
    //     end
    // end

    // // SUB Unit
    // always @(posedge clk) begin
    //     if (trigger_sub[2] || transport_sub[2]) begin
    //         sub_result[2] <= sub_in1[2] - sub_in2[2];
    //         if(dest[2] != 0)
    //         x[dest[2]] <= sub_result[2];
    //     end
    // end
    // // Logical Units
    // always @(posedge clk) begin
    //     if (trigger_and[2] || transport_and[2]) begin 
    //         and_result[2] <= and_in1[2] & and_in2[2];
    //         if (dest[2] != 0) x[dest[2]] <= and_result[2];
    //     end 
    //     if (trigger_or[2] || transport_or[2]) begin 
    //         or_result[2]  <= or_in1[2]  | or_in2[2];
    //         if (dest[2] != 0) x[dest[2]] <= or_result[2];
    //     end
    //     if (trigger_xor[2] || transport_xor[2]) begin 
    //         xor_result[2] <= xor_in1[2] ^ xor_in2[2];
    //         if (dest[2] != 0) x[dest[2]] <= xor_result[2];
    //     end
    // end

    // // Shift Units
    // always @(posedge clk) begin
    //     if (trigger_srl[2] || transport_srl[2]) begin 
    //         srl_result[2] <= srl_in1[2] >> srl_in2[2];
    //         if(dest[2] != 0) x[dest[2]] <= srl_result[2];
    //     end
    //     if (trigger_sra[2] || transport_sra[2]) begin
    //         sra_result[2] <= $signed(sra_in1[2]) >>> sra_in2[2];
    //         if(dest[2] != 0) x[dest[2]] <= sra_result[2];
    //     end
    // end

    // // Compare Units
    // always @(posedge clk) begin
    //     if (trigger_slt[2] || transport_slt[2]) begin
    //         slt_result[2] <= ($signed(slt_in1[2]) < $signed(slt_in2[2])) ? 1 : 0;
    //         if(dest[2] != 0) x[dest[2]] <= slt_result[2];
    //     end
    // end

    // always @(posedge clk) begin
    //     if ((switch == 1 || mode == 1)) begin
    //         case (opcode[2])
    //             7'b0000011: begin // LW
    //                 address[2] <= x[id_ex_rs1[2]] + id_ex_imm[2];
    //                 x[id_ex_rd[2]] <= data_mem[address[2]];
    //             end
    //             7'b0100011: begin // SW
    //                 address[2] <= x[id_ex_rs1[2]] + id_ex_imm[2];
    //                 data_mem[address[2]] <= x[id_ex_rs2[2]];
    //             end
    //             7'b0110011: begin // R-type (ADD, SUB, etc.)
    //                 case (id_ex_funct3[2])
    //                     3'b000: begin
    //                         if (id_ex_funct7[2] == 7'b0000000) begin // ADD
    //                             transport_add[2] <= 1;
    //                             add_in1[2] <= id_ex_rs1_value[2];
    //                             add_in2[2] <= id_ex_rs2_value[2];
    //                             dest[2] <= id_ex_rd[2];
    //                         end else if (id_ex_funct7[2] == 7'b0100000) begin // SUB
    //                             transport_sub[2] <= 1;
    //                             sub_in1[2] <= id_ex_rs1_value[2];
    //                             sub_in2[2] <= id_ex_rs2_value[2];
    //                             dest[2] <= id_ex_rd[2];
    //                         end
    //                     end
    //                     3'b111: begin transport_and[2] <= 1; and_in1[2] <= id_ex_rs1_value[2]; and_in2[2] <= id_ex_rs2_value[2]; dest[2] <= id_ex_rd[2]; end
    //                     3'b110: begin transport_or[2]  <= 1; or_in1[2] <= id_ex_rs1_value[2]; or_in2[2] <= id_ex_rs2_value[2]; dest[2] <= id_ex_rd[2]; end
    //                     3'b100: begin transport_xor[2] <= 1; xor_in1[2] <= id_ex_rs1_value[2]; xor_in2[2] <= id_ex_rs2_value[2]; dest[2] <= id_ex_rd[2]; end
    //                     3'b010: begin transport_slt[2] <= 1; slt_in1[2] <= id_ex_rs1_value[2]; slt_in2[2] <= id_ex_rs2_value[2]; dest[2] <= id_ex_rd[2]; end
    //                     3'b101: begin
    //                         if (id_ex_funct7[2] == 7'b0000000) begin transport_srl[2] <= 1; srl_in1[2] <= id_ex_rs1_value[2]; srl_in2[2] <= id_ex_rs2_value[2]; dest[2] <= id_ex_rd[2]; end
    //                         else if (id_ex_funct7[2] == 7'b0100000) begin transport_sra[2] <= 1; sra_in1[2] <= id_ex_rs1_value[2]; sra_in2[2] <= id_ex_rs2_value[2]; dest[2] <= id_ex_rd[2]; end
    //                     end
    //                 endcase
    //             end
    //             7'b0010011: begin // I-type (ADDI, ANDI, etc.)
    //                 case (id_ex_funct3[2])
    //                     3'b000: begin // ADDI
    //                         add_in1[2] <= x[id_ex_rs1[2]];
    //                         add_in2[2] <= id_ex_imm[2];
    //                         trigger_add[2] <= 1;
    //                         x[id_ex_rd[2]] <= add_result[2];
    //                     end
    //                     3'b111: begin x[id_ex_rd[2]] <= x[id_ex_rs1[2]] & id_ex_imm[2]; end // ANDI
    //                     3'b110: begin x[id_ex_rd[2]] <= x[id_ex_rs1[2]] | id_ex_imm[2]; end // ORI
    //                     3'b100: begin x[id_ex_rd[2]] <= x[id_ex_rs1[2]] ^ id_ex_imm[2]; end // XORI
    //                     3'b010: begin x[id_ex_rd[2]] <= ($signed(x[id_ex_rs1[2]]) < $signed(id_ex_imm[2])) ? 1 : 0; end // SLTI
    //                     3'b101: begin
    //                         if (id_ex_funct7[2] == 7'b0000000) x[id_ex_rd[2]] <= x[id_ex_rs1[2]] >> id_ex_imm[2]; // SRLI
    //                         else if (id_ex_funct7[2] == 7'b0100000) x[id_ex_rd[2]] <= $signed(x[id_ex_rs1[2]]) >>> id_ex_imm[2]; // SRAI
    //                     end
    //                 endcase
    //             end
    //         endcase
    //     end
    // end// ADD Unit
    // always @(posedge clk) begin
    //     if (trigger_add[3] || transport_add[3]) begin 
    //         add_result[3] <= add_in1[3] + add_in2[3];
    //         if(dest[3] != 0)
    //         x[dest[3]] <= add_result[3];
    //     end
    // end

    // // SUB Unit
    // always @(posedge clk) begin
    //     if (trigger_sub[3] || transport_sub[3]) begin
    //         sub_result[3] <= sub_in1[3] - sub_in2[3];
    //         if(dest[3] != 0)
    //         x[dest[3]] <= sub_result[3];
    //     end
    // end

    // // Logical Units
    // always @(posedge clk) begin
    //     if (trigger_and[3] || transport_and[3]) begin 
    //         and_result[3] <= and_in1[3] & and_in2[3];
    //         if (dest[3] != 0) x[dest[3]] <= and_result[3];
    //     end 
    //     if (trigger_or[3] || transport_or[0]) begin 
    //         or_result[3]  <= or_in1[3]  | or_in2[3];
    //         if (dest[3] != 0) x[dest[3]] <= or_result[3];
    //     end
    //     if (trigger_xor[3] || transport_xor[3]) begin 
    //         xor_result[3] <= xor_in1[3] ^ xor_in2[3];
    //         if (dest[3] != 0) x[dest[3]] <= xor_result[3];
    //     end
    // end

    // // Shift Units
    // always @(posedge clk) begin
    //     if (trigger_srl[3] || transport_srl[3]) begin 
    //         srl_result[3] <= srl_in1[3] >> srl_in2[3];
    //         if(dest[3] != 0) x[dest[3]] <= srl_result[3];
    //     end
    //     if (trigger_sra[3] || transport_sra[3]) begin
    //         sra_result[3] <= $signed(sra_in1[3]) >>> sra_in2[3];
    //         if(dest[3] != 0) x[dest[3]] <= sra_result[3];
    //     end
    // end

    // // Compare Units
    // always @(posedge clk) begin
    //     if (trigger_slt[3] || transport_slt[3]) begin
    //         slt_result[3] <= ($signed(slt_in1[3]) < $signed(slt_in2[3])) ? 1 : 0;
    //         if(dest[3] != 0) x[dest[3]] <= slt_result[3];
    //     end
    // end

    // always @(posedge clk) begin
    //     if((switch == 1 || mode == 1)) begin
    //         case (opcode[3])
    //             7'b0000011: begin // LW
    //                 address[3] <= x[id_ex_rs1[3]] + id_ex_imm[3];
    //                 x[id_ex_rd[3]] <= data_mem[address[3]];
    //             end
    //             7'b0100011: begin // SW
    //                 address[3] <= x[id_ex_rs1[3]] + id_ex_imm[3];
    //                 data_mem[address[3]] <= x[id_ex_rs2[3]];
    //             end
    //             7'b0110011: begin // R-type (ADD, SUB, etc.)
    //                 case (id_ex_funct3[3])
    //                     3'b000: begin
    //                         if (id_ex_funct7[3] == 7'b0000000) begin // ADD
    //                             transport_add[3] <= 1;
    //                             add_in1[3] <= id_ex_rs1_value[3];
    //                             add_in2[3] <= id_ex_rs2_value[3];
    //                             dest[3] <= id_ex_rd[3];
    //                         end else if (id_ex_funct7[3] == 7'b0100000) begin // SUB
    //                             transport_sub[3] <= 1;
    //                             sub_in1[3] <= id_ex_rs1_value[3];
    //                             sub_in2[3] <= id_ex_rs2_value[3];
    //                             dest[3] <= id_ex_rd[3];
    //                         end
    //                     end
    //                     3'b111: begin transport_and[3] <= 1; and_in1[3] <= id_ex_rs1_value[3]; and_in2[3] <= id_ex_rs2_value[3]; dest[3] <= id_ex_rd[3]; end
    //                     3'b110: begin transport_or[3]  <= 1; or_in1[3] <= id_ex_rs1_value[3]; or_in2[3] <= id_ex_rs2_value[3]; dest[3] <= id_ex_rd[3]; end
    //                     3'b100: begin transport_xor[3] <= 1; xor_in1[3] <= id_ex_rs1_value[3]; xor_in2[3] <= id_ex_rs2_value[3]; dest[3] <= id_ex_rd[3]; end
    //                     3'b010: begin transport_slt[3] <= 1; slt_in1[3] <= id_ex_rs1_value[3]; slt_in2[3] <= id_ex_rs2_value[3]; dest[3] <= id_ex_rd[3]; end
    //                     3'b101: begin
    //                         if (id_ex_funct7[3] == 7'b0000000) begin transport_srl[3] <= 1; srl_in1[3] <= id_ex_rs1_value[3]; srl_in2[3] <= id_ex_rs2_value[3]; dest[3] <= id_ex_rd[3]; end
    //                         else if (id_ex_funct7[3] == 7'b0100000) begin transport_sra[3] <= 1; sra_in1[3] <= id_ex_rs1_value[3]; sra_in2[3] <= id_ex_rs2_value[3]; dest[3] <= id_ex_rd[3]; end
    //                     end
    //                 endcase
    //             end
    //             7'b0010011: begin // I-type (ADDI, ANDI, etc.)
    //                 case (id_ex_funct3[3])
    //                     3'b000: begin // ADDI
    //                         add_in1[3] <= x[id_ex_rs1[3]];
    //                         add_in2[3] <= id_ex_imm[3];
    //                         trigger_add[3] <= 1;
    //                         x[id_ex_rd[3]] <= add_result[3];
    //                     end
    //                     3'b111: begin x[id_ex_rd[3]] <= x[id_ex_rs1[3]] & id_ex_imm[3]; end // ANDI
    //                     3'b110: begin x[id_ex_rd[3]] <= x[id_ex_rs1[3]] | id_ex_imm[3]; end // ORI
    //                     3'b100: begin x[id_ex_rd[3]] <= x[id_ex_rs1[3]] ^ id_ex_imm[3]; end // XORI
    //                     3'b010: begin x[id_ex_rd[3]] <= ($signed(x[id_ex_rs1[3]]) < $signed(id_ex_imm[3])) ? 1 : 0; end // SLTI
    //                     3'b101: begin
    //                         if (id_ex_funct7[3] == 7'b0000000) x[id_ex_rd[3]] <= x[id_ex_rs1[3]] >> id_ex_imm[3]; // SRLI
    //                         else if (id_ex_funct7[3] == 7'b0100000) x[id_ex_rd[3]] <= $signed(x[id_ex_rs1[3]]) >>> id_ex_imm[3]; // SRAI
    //                     end
    //                 endcase
    //             end
    //         endcase
    //     end
    // end

// ADD Unit
    always @(posedge clk) begin
        if (trigger_add[1] || transport_add[1]) begin 
            add_result[1] <= add_in1[1] + add_in2[1];
            if(dest[1] != 0)
            x[dest[1]] <= add_result[1];
        end
    end

    // SUB Unit
    always @(posedge clk) begin
        if (trigger_sub[1] || transport_sub[1]) begin
            sub_result[1] <= sub_in1[1] - sub_in2[1];
            if(dest[1] != 0)
            x[dest[1]] <= sub_result[1];
        end
    end

    // Logical Units
    always @(posedge clk) begin
        if (trigger_and[1] || transport_and[1]) begin 
            and_result[1] <= and_in1[1] & and_in2[1];
            if (dest[1] != 0) x[dest[1]] <= and_result[1];
        end 
        if (trigger_or[1] || transport_or[1]) begin 
            or_result[1]  <= or_in1[1]  | or_in2[1];
            if (dest[1] != 0) x[dest[1]] <= or_result[1];
        end
        if (trigger_xor[1] || transport_xor[1]) begin 
            xor_result[1] <= xor_in1[1] ^ xor_in2[1];
            if (dest[1] != 0) x[dest[1]] <= xor_result[1];
        end
    end

    // Shift Units
    always @(posedge clk) begin
        if (trigger_srl[1] || transport_srl[1]) begin 
            srl_result[1] <= srl_in1[1] >> srl_in2[1];
            if(dest[1] != 0) x[dest[1]] <= srl_result[1];
        end
        if (trigger_sra[1] || transport_sra[1]) begin
            sra_result[1] <= $signed(sra_in1[1]) >>> sra_in2[1];
            if(dest[1] != 0) x[dest[1]] <= sra_result[1];
        end
    end

    // Compare Units
    always @(posedge clk) begin
        if (trigger_slt[1] || transport_slt[1]) begin
            slt_result[1] <= ($signed(slt_in1[1]) < $signed(slt_in2[1])) ? 1 : 0;
            if(dest[1] != 0) x[dest[1]] <= slt_result[1];
        end
    end

    always @(posedge clk) begin
        if((switch == 1 || mode == 1)) begin
            case (opcode[1])
                7'b0000011: begin // LW
                    address[1] <= x[id_ex_rs1[1]] + id_ex_imm[1];
                    x[id_ex_rd[1]] <= data_mem[address[1]];
                end
                7'b0100011: begin // SW
                    address[1] <= x[id_ex_rs1[1]] + id_ex_imm[1];
                    data_mem[address[1]] <= x[id_ex_rs2[1]];
                end
                7'b0110011: begin // R-type (ADD, SUB, etc.)
                    case (id_ex_funct3[1])
                        3'b000: begin
                            if (id_ex_funct7[1] == 7'b0000000) begin // ADD
                                transport_add[1] <= 1;
                                add_in1[1] <= id_ex_rs1_value[1];
                                add_in2[1] <= id_ex_rs2_value[1];
                                dest[1] <= id_ex_rd[1];
                            end else if (id_ex_funct7[1] == 7'b0100000) begin // SUB
                                transport_sub[1] <= 1;
                                sub_in1[1] <= id_ex_rs1_value[1];
                                sub_in2[1] <= id_ex_rs2_value[1];
                                dest[1] <= id_ex_rd[1];
                            end
                        end
                        3'b111: begin transport_and[1] <= 1; and_in1[1] <= id_ex_rs1_value[1]; and_in2[1] <= id_ex_rs2_value[1]; dest[1] <= id_ex_rd[1]; end
                        3'b110: begin transport_or[1]  <= 1; or_in1[1] <= id_ex_rs1_value[1]; or_in2[1] <= id_ex_rs2_value[1]; dest[1] <= id_ex_rd[1]; end
                        3'b100: begin transport_xor[1] <= 1; xor_in1[1] <= id_ex_rs1_value[1]; xor_in2[1] <= id_ex_rs2_value[1]; dest[1] <= id_ex_rd[1]; end
                        3'b010: begin transport_slt[1] <= 1; slt_in1[1] <= id_ex_rs1_value[1]; slt_in2[1] <= id_ex_rs2_value[1]; dest[1] <= id_ex_rd[1]; end
                        3'b101: begin
                            if (id_ex_funct7[1] == 7'b0000000) begin transport_srl[1] <= 1; srl_in1[1] <= id_ex_rs1_value[1]; srl_in2[1] <= id_ex_rs2_value[1]; dest[1] <= id_ex_rd[1]; end
                            else if (id_ex_funct7[1] == 7'b0100000) begin transport_sra[1] <= 1; sra_in1[1] <= id_ex_rs1_value[1]; sra_in2[1] <= id_ex_rs2_value[1]; dest[1] <= id_ex_rd[1]; end
                        end
                    endcase
                end
                7'b0010011: begin // I-type (ADDI, ANDI, etc.)
                    case (id_ex_funct3[1])
                        3'b000: begin // ADDI
                            add_in1[1] <= x[id_ex_rs1[1]];
                            add_in2[1] <= id_ex_imm[1];
                            trigger_add[1] <= 1;
                            x[id_ex_rd[1]] <= add_result[1];
                        end
                        3'b111: begin x[id_ex_rd[1]] <= x[id_ex_rs1[1]] & id_ex_imm[1]; end // ANDI
                        3'b110: begin x[id_ex_rd[1]] <= x[id_ex_rs1[1]] | id_ex_imm[1]; end // ORI
                        3'b100: begin x[id_ex_rd[1]] <= x[id_ex_rs1[1]] ^ id_ex_imm[1]; end // XORI
                        3'b010: begin x[id_ex_rd[1]] <= ($signed(x[id_ex_rs1[1]]) < $signed(id_ex_imm[1])) ? 1 : 0; end // SLTI
                        3'b101: begin
                            if (id_ex_funct7[1] == 7'b0000000) x[id_ex_rd[1]] <= x[id_ex_rs1[1]] >> id_ex_imm[1]; // SRLI
                            else if (id_ex_funct7[1] == 7'b0100000) x[id_ex_rd[1]] <= $signed(x[id_ex_rs1[1]]) >>> id_ex_imm[1]; // SRAI
                        end
                    endcase
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if ((switch == 0 && mode == 0)) begin
            if ((ex_mem_reg_write) && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1[0])) forwardA <= 2'b10;
            if ((ex_mem_reg_write) && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2[0])) forwardB <= 2'b10;
            if ((mem_wb_reg_write) && (mem_wb_rd != 0) && (~((ex_mem_reg_write) && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1[0]))) && (mem_wb_rd == id_ex_rs1[0])) forwardA <= 2'b01;
            if ((mem_wb_reg_write) && (mem_wb_rd != 0) && (~((ex_mem_reg_write) && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1[0]))) && (mem_wb_rd == id_ex_rs2[0])) forwardB <= 2'b01;

            case (forwardA)
                2'b00: forward_rs1 <= id_ex_rs1_value[0];
                2'b01: forward_rs1 <= mem_wb_data;
                2'b10: forward_rs1 <= ex_mem_result;
                default: forward_rs1 <= id_ex_rs1_value[0];
            endcase

            // Forwarding mux for alu_src2
            case (forwardB)
                2'b00: forward_rs2 <= id_ex_rs2_value[0];
                2'b01: forward_rs2 <= mem_wb_data;
                2'b10: forward_rs2 <= ex_mem_result;
                default: forward_rs2 <= id_ex_rs2_value[0];
            endcase

            // ALU input selection
            alu_src1 <= forward_rs1;
            alu_src2 <= (id_ex_alu_src[0] == 0) ? forward_rs2 : id_ex_imm[0];

            case(id_ex_opcode[0])
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
                    case(id_ex_funct3[0])
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
                    case(id_ex_funct3[0])
                        3'b000: alu_result <= alu_src1 + alu_src2; // ADDI
                        3'b010: alu_result <= ($signed(alu_src1) < $signed(alu_src2)) ? 1 : 0; // SLTI
                        3'b011: alu_result <= (alu_src1 < alu_src2) ? 1 : 0; // SLTIU
                        3'b100: alu_result <= alu_src1 ^ alu_src2; // XORI
                        3'b110: alu_result <= alu_src1 | alu_src2; // ORI
                        3'b111: alu_result <= alu_src1 & alu_src2; // ANDI
                        3'b001: alu_result <= alu_src1 << alu_src2[4:0]; // SLLI
                        3'b101: begin
                            case(id_ex_funct7[0])
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
                    case(id_ex_funct3[0])
                        3'b000: begin
                            case(id_ex_funct7[0])
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
                            case(id_ex_funct7[0])
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
                predict_target <= id_ex_pc + id_ex_imm[0]/4;
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
            ex_mem_pc <= id_ex_pc;
            ex_mem_rd <= id_ex_rd[0];
            ex_mem_rs1_value <= id_ex_rs1_value[0];
            ex_mem_pc_src <= branch_taken;
            ex_mem_reg_write <= id_ex_reg_write[0];
            ex_mem_mem_read <= id_ex_mem_read[0];
            ex_mem_mem_write <= id_ex_mem_write[0];
            ex_mem_mem_to_reg <= id_ex_mem_to_reg[0];
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
