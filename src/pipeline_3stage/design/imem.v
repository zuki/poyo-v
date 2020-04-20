//
// imem
//


`include "define.vh"

module imem (
    input wire clk,
    input wire [31:0] addr,
    output wire [31:0] rd_data
);

    reg [31:0] mem [0:4095];  // 16KiB(16bitアドレス空間)
    reg [11:0] addr_sync;     // 16KiBを表現するための12bitアドレス(下位2bitはここでは考慮しない)

    initial $readmemh({`MEM_DATA_PATH, "code.hex"}, mem);

    always @(posedge clk) begin
        addr_sync <= addr[12:2];  // 読み出しアドレス更新をクロックと同期することでBRAM化
    end

    assign rd_data = mem[addr_sync];

endmodule
