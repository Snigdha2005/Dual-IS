`include 'param.sv'
module risc_v_processor(
    input clk,
    input rst,
    input [31*N:0] instr_mem[31:0],
    input [31:0] data_mem[31:0]
);

    // Program Counter
    reg [31:0] pc;

    // Pipeline Registers
    reg [31:0] IF_ID_instr, IF_ID_pc;
    reg [31:0] ID_EX_pc, ID_EX_rs1_value, ID_EX_rs2_value, ID_EX_imm;
    reg [4:0] ID_EX_rd, ID_EX_rs1, ID_EX_rs2;
    reg [3:0] ID_EX_funct;
    reg [6:0] ID_EX_opcode;
    reg [2:0] ID_EX_funct3;
    reg ID_EX_reg_write, ID_EX_mem_read, ID_EX_mem_write, ID_EX_mem_to_reg;

    reg [31:0] EX_MEM_aluout, EX_MEM_rs2_value;
    reg [4:0] EX_MEM_rd;
    reg EX_MEM_reg_write, EX_MEM_mem_read, EX_MEM_mem_write, EX_MEM_mem_to_reg;

    reg [31:0] MEM_WB_aluout, MEM_WB_read_data;
    reg [4:0] MEM_WB_rd;
    reg MEM_WB_reg_write, MEM_WB_mem_to_reg;

    // Forwarding Unit Signals
    wire [1:0] forward_a, forward_b;
    wire stall;

    // Instruction Fetch
    wire [31:0] instr;
    instruction_fetch if_stage(clk, pc, instr_mem, instr);

    // Instruction Decode
    wire [31:0] rs1_value, rs2_value, imm;
    wire [4:0] rs1, rs2, rd;
    wire [6:0] opcode;
    wire [3:0] funct;
    wire [2:0] funct3;
    wire reg_write, mem_read, mem_write, mem_to_reg;

    instruction_decode id_stage(
        .instr(IF_ID_instr),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .imm(imm), .opcode(opcode), .funct3(funct3), .funct(funct),
        .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write), .mem_to_reg(mem_to_reg)
    );

    // Execute
    wire [31:0] aluout;
    wire [31:0] alu_a, alu_b;
    
    assign alu_a = (forward_a == 2'b00) ? ID_EX_rs1_value :
                   (forward_a == 2'b01) ? MEM_WB_aluout :
                   (forward_a == 2'b10) ? EX_MEM_aluout : ID_EX_rs1_value;

    assign alu_b = (forward_b == 2'b00) ? ID_EX_rs2_value :
                   (forward_b == 2'b01) ? MEM_WB_aluout :
                   (forward_b == 2'b10) ? EX_MEM_aluout : ID_EX_rs2_value;

    execute ex_stage(alu_a, alu_b, ID_EX_pc, ID_EX_imm, ID_EX_funct3, ID_EX_funct, ID_EX_opcode, aluout);

    // Memory
    wire [31:0] read_data;
    data_mem mem_stage(EX_MEM_aluout, EX_MEM_rs2_value, read_data, EX_MEM_mem_write, EX_MEM_mem_read, data_mem);

    // Write Back
    wire [31:0] wb_data;
    // assign wb_data = MEM_WB_mem_to_reg ? MEM_WB_read_data : MEM_WB_aluout;
    writeback wb_stage(clk, MEM_WB_aluout, MEM_WB_read_data, MEM_WB_mem_to_reg, wb_data);

    // Forwarding Unit
    forwarding_unit fwd_unit(
        .ID_EX_rs1(ID_EX_rs1), .ID_EX_rs2(ID_EX_rs2),
        .EX_MEM_rd(EX_MEM_rd), .MEM_WB_rd(MEM_WB_rd),
        .EX_MEM_reg_write(EX_MEM_reg_write), .MEM_WB_reg_write(MEM_WB_reg_write),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    // Hazard Detection Unit
    hazard_detection_unit hzd_unit(
        .IF_ID_rs1(IF_ID_instr[19:15]), .IF_ID_rs2(IF_ID_instr[24:20]),
        .ID_EX_rd(ID_EX_rd),
        .ID_EX_mem_read(ID_EX_mem_read),
        .stall(stall)
    );

    // Pipeline Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 0;
            IF_ID_instr <= 0; IF_ID_pc <= 0;
            ID_EX_pc <= 0; ID_EX_rs1_value <= 0; ID_EX_rs2_value <= 0; ID_EX_imm <= 0;
            ID_EX_rd <= 0; ID_EX_opcode <= 0; ID_EX_funct3 <= 0; ID_EX_funct <= 0;
            ID_EX_reg_write <= 0; ID_EX_mem_read <= 0; ID_EX_mem_write <= 0; ID_EX_mem_to_reg <= 0;
            EX_MEM_aluout <= 0; EX_MEM_rs2_value <= 0; EX_MEM_rd <= 0;
            EX_MEM_reg_write <= 0; EX_MEM_mem_read <= 0; EX_MEM_mem_write <= 0; EX_MEM_mem_to_reg <= 0;
            MEM_WB_aluout <= 0; MEM_WB_read_data <= 0; MEM_WB_rd <= 0;
            MEM_WB_reg_write <= 0; MEM_WB_mem_to_reg <= 0;
        end else begin
            if (!stall) begin
                // Update PC
                pc <= (pcsrc == 0) ? pc + 4 : pc_adder;

                // IF/ID Pipeline Register
                IF_ID_instr <= instr;
                IF_ID_pc <= pc;

                // ID/EX Pipeline Register
                ID_EX_pc <= IF_ID_pc;
                ID_EX_rs1_value <= rs1_value;
                ID_EX_rs2_value <= rs2_value;
                ID_EX_rs1 <= rs1;
                ID_EX_rs2 <= rs2;
                ID_EX_imm <= imm;
                ID_EX_rd <= rd;
                ID_EX_opcode <= opcode;
                ID_EX_funct3 <= funct3;
                ID_EX_funct <= funct;
                ID_EX_reg_write <= reg_write;
                ID_EX_mem_read <= mem_read;
                ID_EX_mem_write <= mem_write;
                ID_EX_mem_to_reg <= mem_to_reg;

                // EX/MEM Pipeline Register
                EX_MEM_aluout <= aluout;
                EX_MEM_rs2_value <= ID_EX_rs2_value;
                EX_MEM_rd <= ID_EX_rd;
                EX_MEM_reg_write <= ID_EX_reg_write;
                EX_MEM_mem_read <= ID_EX_mem_read;
                EX_MEM_mem_write <= ID_EX_mem_write;
                EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;

                // MEM/WB Pipeline Register
                MEM_WB_aluout <= EX_MEM_aluout;
                MEM_WB_read_data <= read_data;
                MEM_WB_rd <= EX_MEM_rd;
                MEM_WB_reg_write <= EX_MEM_reg_write;
                MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
            end
        end
    end

endmodule
