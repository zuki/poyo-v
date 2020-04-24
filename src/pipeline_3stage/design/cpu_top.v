//
// cpu_top
//


`include "define.vh"

module cpu_top (
    input wire clk,
    input wire rst,
    input wire uart_rx,
    input wire [3:0] gpi_in,
    output wire [3:0] gpo_out,
    output wire uart_tx
);

    // reset
    wire rst_n;
    assign rst_n = ~rst;

    // valid
    wire valid;

    // PC
    wire [31:0] next_PC;
    wire [31:0] ex_br_addr;
    wire        ex_br_taken;
    reg [31:0] PC;

    // fetch stage関連の定義
    wire [31:0] imem_addr, imem_rd_data;

    // execution stage関連の定義
    reg [31:0] ex_PC;

    // decoder
    wire [31:0] decoder_insn;
    wire [4:0] decoder_srcreg1_num, decoder_srcreg2_num, ex_dstreg_num;
    wire [31:0] decoder_imm;
    wire [5:0] ex_alucode;
    wire [1:0] ex_aluop1_type, ex_aluop2_type;
    wire ex_reg_we, ex_is_load, ex_is_store;

    // register file
    wire regfile_we;
    wire [4:0] regfile_srcreg1_num, regfile_srcreg2_num, regfile_dstreg_num;
    wire [31:0] regfile_srcreg1_value, regfile_srcreg2_value, regfile_dstreg_value;

    // ALU
    wire [5:0] alu_alucode;
    wire [31:0] alu_op1, alu_op2, ex_alu_result;
    wire [31:0] ex_alu_result_i, ex_alu_result_m, ex_alu_result_d;

    wire [31:0] ex_srcreg1_value, ex_srcreg2_value, ex_store_value;
    wire        ex_br_taken_i;
    wire        ex_div_valid;

    // dmem
    wire dmem_we;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wr_data;
    wire [31:0] dmem_rd_data;
    wire [3:0]  dmem_byteenable;

    // UART TX
    wire uart_we;
    wire [7:0] uart_data_in;
    wire uart_data_out;

    // UART RX
    wire uart_rd_en;
    wire [7:0] uart_rd_data;
    wire [31:0] uart_value;

    // GPIO
    wire [7:0] gpi_data_in;
    wire [7:0] gpi_data_out;
    wire [31:0] gpi_value;
    wire gpo_we;
    wire [7:0] gpo_data_in;
    wire [7:0] gpo_data_out;
    wire [31:0] gpo_value;

    // ハードウェアカウンタ
    wire [31:0] hc_value;

    // write-back stage関連の定義
    reg wb_reg_we;
    reg [4:0] wb_dstreg_num;
    reg wb_is_load;
    reg [5:0] wb_alucode;
    reg [31:0] wb_alu_result;
    wire [31:0] wb_load_value, wb_dstreg_value;

    //====================================================================
    // program counter
    //====================================================================

    // ex stageの結果をフォワーディング
    assign next_PC = (rst_n == 1'b0) ? PC + 32'd4 : ex_br_taken ? ex_br_addr + 32'd4 : PC + 32'd4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 32'd0;
        end else if (valid) begin
            PC <= next_PC;
        end
    end

    //====================================================================
    // fetch stage
    //====================================================================

    // ex stageの結果をフォワーディング
    assign imem_addr = (rst_n == 1'b0) ? 32'd0 : ex_br_taken ? ex_br_addr : PC;

    rom rom_inst (
        .clock   (clk),
        .address (imem_addr[13:2]),
        .rden    (valid),
        .q       (imem_rd_data)
    );

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ex_PC <= 32'd0;
        end else if (valid) begin
            ex_PC <= imem_addr;
        end
    end

    //====================================================================
    // execution stage
    //====================================================================

    assign decoder_insn = imem_rd_data;

    decoder decoder_0 (
        .insn(decoder_insn),
        .srcreg1_num(decoder_srcreg1_num),
        .srcreg2_num(decoder_srcreg2_num),
        .dstreg_num(ex_dstreg_num),
        .imm(decoder_imm),
        .alucode(ex_alucode),
        .aluop1_type(ex_aluop1_type),
        .aluop2_type(ex_aluop2_type),
        .reg_we(ex_reg_we),
        .is_load(ex_is_load),
        .is_store(ex_is_store)
    );


    assign regfile_srcreg1_num = decoder_srcreg1_num;
    assign regfile_srcreg2_num = decoder_srcreg2_num;

    regfile regfile_0 (
        .clk(clk),
        .we(regfile_we),
        .valid(valid),
        .srcreg1_num(regfile_srcreg1_num),
        .srcreg2_num(regfile_srcreg2_num),
        .dstreg_num(regfile_dstreg_num),
        .dstreg_value(regfile_dstreg_value),
        .srcreg1_value(regfile_srcreg1_value),
        .srcreg2_value(regfile_srcreg2_value)
    );


    // alu
    assign alu_alucode = ex_alucode;

    // wb stageの結果をフォワーディング
    assign ex_srcreg1_value = (regfile_srcreg1_num==5'd0) ? 32'd0 :
                              (wb_reg_we && (decoder_srcreg1_num == wb_dstreg_num)) ? wb_dstreg_value : regfile_srcreg1_value;
    assign ex_srcreg2_value = (regfile_srcreg2_num==5'd0) ? 32'd0 :
                              (wb_reg_we && (decoder_srcreg2_num == wb_dstreg_num)) ? wb_dstreg_value : regfile_srcreg2_value;

    assign alu_op1 = (ex_aluop1_type == `OP_TYPE_REG) ? ex_srcreg1_value :
                     (ex_aluop1_type == `OP_TYPE_IMM) ? decoder_imm :
                     (ex_aluop1_type == `OP_TYPE_PC) ? ex_PC: 32'd0;
    assign alu_op2 = (ex_aluop2_type == `OP_TYPE_REG) ? ex_srcreg2_value :
                     (ex_aluop2_type == `OP_TYPE_IMM) ? decoder_imm :
                     (ex_aluop2_type == `OP_TYPE_PC) ? ex_PC : 32'd0;

    alu alu_0 (
        .alucode(alu_alucode),
        .op1(alu_op1),
        .op2(alu_op2),
        .alu_result(ex_alu_result_i),
        .br_taken(ex_br_taken_i)
    );

    alu_mul alu_mul0 (
        .alucode(alu_alucode),
        .op1(alu_op1),
        .op2(alu_op2),
        .alu_result(ex_alu_result_m)
    );

    alu_div alu_div0(
        .clk(clk), .rst(rst_n), .alucode(alu_alucode),
        .op1(alu_op1), .op2(alu_op2), .valid(ex_div_valid),
        .alu_result(ex_alu_result_d)
    );

    assign ex_alu_result =
        ((alu_alucode >= `ALU_MUL) && (alu_alucode <= `ALU_MULHU)) ? ex_alu_result_m :
        ((alu_alucode >= `ALU_DIV) && (alu_alucode <= `ALU_REMU))  ? ex_alu_result_d : ex_alu_result_i;
    assign ex_br_taken = ((alu_alucode >= `ALU_MUL) && (alu_alucode <= `ALU_REMU)) ? `DISABLE : ex_br_taken_i;
    assign valid = ((alu_alucode !== 6'bx) && (alu_alucode >= `ALU_DIV) && (alu_alucode <= `ALU_REMU)) ? ex_div_valid : 1'b1;

    assign ex_store_value = ((ex_alucode == `ALU_SW) || (ex_alucode == `ALU_SH) || (ex_alucode == `ALU_SB)) ? ex_srcreg2_value : 32'd0;

    assign ex_br_addr = (ex_alucode==`ALU_JAL) ? ex_PC + decoder_imm :
                        (ex_alucode==`ALU_JALR) ? alu_op1 + decoder_imm :
                        ((ex_alucode==`ALU_BEQ) || (ex_alucode==`ALU_BNE) || (ex_alucode==`ALU_BLT) ||
                         (ex_alucode==`ALU_BGE) || (ex_alucode==`ALU_BLTU) || (ex_alucode==`ALU_BGEU)) ? ex_PC + decoder_imm : 32'd0;


    // store
    assign dmem_addr = ex_alu_result - `DMEM_START_ADDR;  // データメモリの読出しアドレスを変換;

    function [31:0] dmem_wr_data_sel(
        input is_store,
        input [5:0] alucode,
        input [1:0] byte_offset,
        input [31:0] store_value
    );
        begin
            if (is_store) begin
                case (alucode)
                    `ALU_SW: dmem_wr_data_sel = store_value;
                    `ALU_SH: dmem_wr_data_sel = ({16'd0, store_value[15:0]} << (byte_offset * 8));
                    `ALU_SB: dmem_wr_data_sel = ({24'd0, store_value[7:0]} << (byte_offset * 8));
                    default: dmem_wr_data_sel = store_value;
                endcase
            end else begin
                dmem_wr_data_sel = 32'd0;
            end
        end
    endfunction

    assign dmem_wr_data = dmem_wr_data_sel(ex_is_store, ex_alucode, ex_alu_result[1:0], ex_store_value);

    function [3:0] dmem_we_sel(
        input is_store,
        input [5:0] alucode,
        input [1:0] byte_offset
    );
        begin
            if (is_store) begin
                case (alucode)
                    `ALU_SW: dmem_we_sel = 4'b1111;
                    `ALU_SH: dmem_we_sel = (4'b0011 << byte_offset);
                    `ALU_SB: dmem_we_sel = (4'b0001 << byte_offset);
                    default: dmem_we_sel = 4'b0000;
                endcase
            end else begin
                dmem_we_sel = 4'b0000;
            end
        end
    endfunction

    assign dmem_byteenable = dmem_we_sel(ex_is_store, ex_alucode, ex_alu_result[1:0]) ;

    // メモリマップのデータメモリにあたるアドレスが指定されていれば書き込み有効化
    assign dmem_we = (dmem_addr <= `DMEM_SIZE) && |dmem_byteenable && valid;

    ram ram_inst (
        .clock   ( clk ),
        .address ( dmem_addr[13:2] ),
        .byteena ( dmem_byteenable ),
        .data    ( dmem_wr_data ),
        .wren    ( dmem_we ),
        .q       ( dmem_rd_data )
    );

    // UART
    assign uart_data_in = ex_store_value[7:0];
    assign uart_we = ((ex_alu_result == `UART_TX_ADDR) && ex_is_store) ? `ENABLE : `DISABLE;
    assign uart_tx = uart_data_out;

    uart uart_0 (
        .clk(clk),
        .rst_n(rst_n),
        .wr_data(uart_data_in),
        .wr_en(uart_we),
        .uart_tx(uart_data_out)
    );

    uart_rx uart_rx_0 (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_rx),
        .rd_data(uart_rd_data),
        .rd_en(uart_rd_en)
    );


    // GPIO
    assign gpi_data_in = {4'd0, gpi_in};  // デフォルトでは汎用入力は4bit
    assign gpo_data_in = ex_store_value[7:0];
    assign gpo_we = ((ex_alu_result == `GPO_ADDR) && ex_is_store) ? `ENABLE : `DISABLE;
    assign gpo_out = gpo_data_out[3:0];  // デフォルトでは汎用出力は4bit

    gpi gpi_0 (
		.clk(clk),
		.rst_n(rst_n),
		.wr_data(gpi_data_in),
		.gpi_out(gpi_data_out)
    );

    gpo gpo_0 (
		.clk(clk),
		.rst_n(rst_n),
		.we(gpo_we),
		.wr_data(gpo_data_in),
		.gpo_out(gpo_data_out)
    );


    // hardware counter
    hardware_counter hardware_counter_0 (
        .clk(clk),
        .rst_n(rst_n),
        .hc_out(hc_value)
    );


    // パイプラインレジスタ
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_reg_we <= `DISABLE;
            wb_dstreg_num <= 5'd0;
            wb_is_load <= `DISABLE;
            wb_alucode <= 6'd0;
            wb_alu_result <= 32'd0;
        end else begin
            wb_reg_we <= ex_reg_we;
            wb_dstreg_num <= ex_dstreg_num;
            wb_is_load <= ex_is_load;
            wb_alucode <= ex_alucode;
            wb_alu_result <= ex_alu_result;
        end
    end

    //====================================================================
    // write-back stage
    //====================================================================

    // 各種I/Oからのロード値
    assign gpi_value = {28'd0, gpi_data_out[3:0]};
    assign gpo_value = {28'd0, gpo_data_out[3:0]};
    assign uart_value = {24'd0, uart_rd_data};

    function [31:0] load_value_sel(
        input is_load,
        input [5:0] alucode,
        input [31:0] alu_result,
        input [7:0] dmem_rd_data_0, dmem_rd_data_1, dmem_rd_data_2, dmem_rd_data_3,
        input [31:0] uart_value,
        input [31:0] hc_value,
        input [31:0] gpi_value,
        input [31:0] gpo_value
    );

        begin
            if (is_load) begin
                case (alucode)
                    `ALU_LW: begin
                        if (alu_result == `HARDWARE_COUNTER_ADDR) begin
                            load_value_sel = hc_value;
                        end else if (alu_result == `UART_RX_ADDR) begin
                            load_value_sel = uart_value;
                        end else if (alu_result == `GPI_ADDR) begin
                            load_value_sel = gpi_value;
                        end else if (alu_result == `GPO_ADDR) begin
                            load_value_sel = gpo_value;
                        end else begin
                            load_value_sel = {dmem_rd_data_3, dmem_rd_data_2, dmem_rd_data_1, dmem_rd_data_0};
                        end
                    end
                    `ALU_LH: begin
                        case (alu_result[1:0])
                            2'b00: load_value_sel = {{16{dmem_rd_data_1[7]}}, dmem_rd_data_1, dmem_rd_data_0};
                            2'b01: load_value_sel = {{16{dmem_rd_data_2[7]}}, dmem_rd_data_2, dmem_rd_data_1};
                            2'b10: load_value_sel = {{16{dmem_rd_data_3[7]}}, dmem_rd_data_3, dmem_rd_data_2};
                            default: load_value_sel = {{16{dmem_rd_data_1[7]}}, dmem_rd_data_1, dmem_rd_data_0};
                        endcase
                    end
                    `ALU_LB: begin
                        case (alu_result[1:0])
                            2'b00: load_value_sel = {{24{dmem_rd_data_0[7]}}, dmem_rd_data_0};
                            2'b01: load_value_sel = {{24{dmem_rd_data_1[7]}}, dmem_rd_data_1};
                            2'b10: load_value_sel = {{24{dmem_rd_data_2[7]}}, dmem_rd_data_2};
                            2'b11: load_value_sel = {{24{dmem_rd_data_3[7]}}, dmem_rd_data_3};
                        endcase
                    end
                    `ALU_LHU: begin
                        case (alu_result[1:0])
                            2'b00: load_value_sel = {16'd0, dmem_rd_data_1, dmem_rd_data_0};
                            2'b01: load_value_sel = {16'd0, dmem_rd_data_2, dmem_rd_data_1};
                            2'b10: load_value_sel = {16'd0, dmem_rd_data_3, dmem_rd_data_2};
                            default: load_value_sel = {16'd0, dmem_rd_data_1, dmem_rd_data_0};
                        endcase
                    end
                    `ALU_LBU: begin
                        case (alu_result[1:0])
                            2'b00: load_value_sel = {24'd0, dmem_rd_data_0};
                            2'b01: load_value_sel = {24'd0, dmem_rd_data_1};
                            2'b10: load_value_sel = {24'd0, dmem_rd_data_2};
                            2'b11: load_value_sel = {24'd0, dmem_rd_data_3};
                        endcase
                    end
                    default: load_value_sel = {dmem_rd_data_3, dmem_rd_data_2, dmem_rd_data_1, dmem_rd_data_0};
                endcase
            end else begin
                load_value_sel = 32'd0;
            end
        end

    endfunction

    assign wb_load_value = load_value_sel(wb_is_load, wb_alucode, wb_alu_result, dmem_rd_data[7:0],
                                          dmem_rd_data[15:8], dmem_rd_data[23:16], dmem_rd_data[31:24], uart_value, hc_value, gpi_value, gpo_value);

    assign wb_dstreg_value = wb_is_load ? wb_load_value : wb_alu_result;

    // wb stageの結果に応じてレジスタへ書き込み
    assign regfile_we = wb_reg_we;
    assign regfile_dstreg_num = wb_dstreg_num;
    assign regfile_dstreg_value = wb_dstreg_value;


endmodule
