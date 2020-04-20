module poyo_v (
    input wire CLK12M,
    input wire USER_BTN,
    input wire UART_RXD,
    input wire [3:0] D,
    output wire [7:0] LED,
    output wire UART_TXD
);

wire clk48;

assign LED[7:4] = 0;


pll pll_inst (
    .inclk0 ( CLK12M ),
    .c0 ( clk48 )
 );


cpu_top u0 (
    .clk     ( clk48     ),
    .rst     ( ~USER_BTN ),
    .uart_rx ( UART_RXD  ),
    .gpi_in  ( D         ),
    .gpo_out ( LED[3:0]  ),
    .uart_tx ( UART_TXD  )
);

endmodule
