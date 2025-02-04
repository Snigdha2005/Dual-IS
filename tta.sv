module tta(
    input clk, 
    input rst,
    input [32*N - 1:0] instr_mem[31:0];
    input [31:0] data_mem[31:0];
);
    reg [31:0] pc;
    wire [32*N-1:0] instr;
    instruction_fetch if_stage(clk, pc, instr_mem, instr);
    
    wire [32*N-1:0] rs1_value, rs2_value, imm;
    wire [5*N-1:0] rs1, rs2, rd;
    wire [7*N-1:0] opcode;
    wire [4*N-1:0] funct;
    wire [3*N-1:0] funct3;
    wire [N-1:0] reg_write, mem_read, mem_write, mem_to_reg;

    genvar i;
    generate 
        for (i = 0; i < N; i = i + 1) begin
            instruction_decode id_stage(
                .instr(instr[32*(i+1)-1:32*i]),
                .rs1(rs1[5*(i+1)-1:5*i]), .rs2(rs2[5*(i+1)-1:5*i]), .rd(rd[5*(i+1)-1:5*i]),
                .imm(imm[32*(i+1)-1:32*i]), .opcode(opcode[7*(i+1)-1:7*i]), .funct3(funct3[3*(i+1)-1:3*i]), .funct(funct[4*(i+1)-1:4*i]),
                .reg_write(reg_write[(i+1)-1:i]), .mem_read(mem_read[(i+1)-1:i]), .mem_write(mem_write[(i+1)-1:i]), .mem_to_reg(mem_to_reg[(i+1)-1:i])
    );
        end
	endgenerate

    risc_to_tta conversion();
    interconnect_network interconnect();
    fu1 add_unit(
        .clk(clk),
        .rst(rst),
        .src1(rs1_value[31:0]),   // Example connection for src1
        .src2(rs2_value[31:0]),   // Example connection for src2
        .result(add_result)       // Output result
    );

    fu2 sub_unit(
        .clk(clk),
        .rst(rst),
        .src1(rs1_value[31:0]),   // Example connection for src1
        .src2(rs2_value[31:0]),   // Example connection for src2
        .result(sub_result)       // Output result
    );

    fu3 load_store_unit(
        .clk(clk),
        .rst(rst),
        .address(alu_result),         // Address from ALU or calculated result
        .write_data(rs2_value[31:0]), // Data to write
        .mem_read(mem_read[0]),       // Read enable
        .mem_write(mem_write[0]),     // Write enable
        .data_mem(data_mem),          // Shared memory
        .read_data(mem_data)          // Data read from memory
    );
    register_file rf(
        .read_reg1(),
        .read_reg2(),
        .write_reg(),
        .write_data(),
        .read_reg1_value(),
        .read_reg2_value(),
        .reg_write()
    );

endmodule