//
// alu_mul
//


`include "define.vh"

module alu_mul (
    input wire [5:0] alucode,
    input wire [31:0] op1,
    input wire [31:0] op2,
    output reg [31:0] alu_result
);

    wire signed [31:0] signed_op1, signed_op2;
    reg         [63:0] mul_result;
    reg  signed [63:0] signed_mul_result;

    // 符号付き計算用
    assign signed_op1 = op1;
    assign signed_op2 = op2;

    always @* begin
        case (alucode)
            `ALU_MUL: begin
                signed_mul_result = signed_op1 * signed_op2;
                alu_result = signed_mul_result[31:0];
            end
            `ALU_MULH: begin
                signed_mul_result = signed_op1 * signed_op2;
                alu_result = signed_mul_result[63:32];
            end
            `ALU_MULHSU: begin
                mul_result = signed_op1 * op2;
                alu_result = mul_result[63:32];
            end
            `ALU_MULHU: begin
                mul_result = op1 * op2;
                alu_result = mul_result[63:32];
              end
            default: begin
                alu_result = 32'd0;
            end
        endcase
    end

endmodule
