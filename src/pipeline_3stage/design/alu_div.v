`include "define.vh"

module alu_div (
    input  wire        clk, rst,
    input  wire [5:0]  alucode,
    input  wire [31:0] op1, op2,
    output wire        valid,
    output wire [31:0] alu_result
);

    reg [1:0]     state;
    localparam S_IDLE = 2'd0;
    localparam S_EXEC = 2'd1;
    localparam S_FIN  = 2'd2;

    wire  start, div_inst, rem_inst, signed_inst;

    assign div_inst = (alucode == `ALU_DIV || alucode == `ALU_DIVU);
    assign rem_inst = (alucode == `ALU_REM || alucode == `ALU_REMU);
    assign signed_inst = (alucode == `ALU_DIV || alucode == `ALU_REM);
    assign start =  div_inst | rem_inst;

    reg [31:0]    dividend;
    reg [62:0]    divisor;
    reg [31:0]    quotient, quotient_mask;
    reg           outsign;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= S_IDLE;
            dividend <= 0;
            divisor <= 0;
            outsign <= 0;
            quotient <= 0;
            quotient_mask <= 0;
        end else begin
            case(state)
                S_IDLE: begin
                    if (start) begin
                        state <= S_EXEC;
                        dividend <= (signed_inst & op1[31]) ? -op1 : op1;
                        divisor[62:31] <= (signed_inst & op2[31]) ? -op2 : op2;
                        divisor[30:0] <= 31'd0;
                        outsign <= (((alucode == `ALU_DIV) & (op1[31] ^ op2[31])) & |op2) |
                                    ((alucode == `ALU_REM) & op1[31]);
                        quotient <= 32'd0;
                        quotient_mask <= 32'h8000_0000;
                    end
                end
                S_EXEC: begin
                    if (!quotient_mask) begin
                       state <= S_FIN;
                    end else begin
                        if (divisor <= dividend) begin
                           dividend <= dividend - divisor;
                           quotient <= quotient | quotient_mask;
                        end
                        divisor <= (divisor >> 1);
                        quotient_mask <= (quotient_mask >> 1);
                    end
                end
                S_FIN: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    assign valid = (state === S_FIN);
    assign alu_result = (div_inst) ? ((outsign) ? -quotient : quotient) :
                        (rem_inst) ? ((outsign) ? -dividend : dividend) : 32'd0;
endmodule
