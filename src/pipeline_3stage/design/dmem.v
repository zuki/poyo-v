//
// dmem
//


`include "define.vh"

module dmem #(parameter byte_num = 2'b00) (
    input wire clk,
    input wire we,
    input wire [31:0] addr,
    input wire [7:0] wr_data,
    input wire valid,
    output wire [7:0] rd_data
);

    reg [7:0] mem [0:4095];  // 16KiB = 16 * 1024 >> 2
    reg [11:0] addr_sync;    // 16KiBを表現するための12bitアドレス(下位2bitはここでは考慮しない)

    initial begin
        case (byte_num)
            2'b00: $readmemh({`MEM_DATA_PATH, "data0.hex"}, mem);
            2'b01: $readmemh({`MEM_DATA_PATH, "data1.hex"}, mem);
            2'b10: $readmemh({`MEM_DATA_PATH, "data2.hex"}, mem);
            2'b11: $readmemh({`MEM_DATA_PATH, "data3.hex"}, mem);
        endcase
    end

    always @(posedge clk) begin
        if (valid) begin
            if (we) mem[addr[13:2]] <= wr_data;  // 書き込みタイミングをクロックと同期することでBRAM化
            addr_sync <= addr[13:2];             // 読み出しアドレス更新をクロックと同期することでBRAM化
        end
    end

    assign rd_data = mem[addr_sync];

endmodule
