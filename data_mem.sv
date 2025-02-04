module data_mem();
    input [31:0] aluout;
    input [31:0] store_data;
    output reg [31:0] read_data;
    input mem_write;
    input mem_read;
    input [31:0] data_mem[31:0];
    input branch;
    input zero;
    output reg pcsrc;
    always @(posedge clk) begin
        pcsrc = zero & branch;
        if (mem_write) begin
            data_mem[aluout] = store_data;
        end
        if (mem_read) begin
            read_data = data_mem[aluout];
        end
    end
endmodule