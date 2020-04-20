#create input clock which is 12MHz
create_clock -name clk -period 83.333 [get_ports {CLK12M}]

#derive PLL clocks
derive_pll_clocks

#derive clock uncertainty

derive_clock_uncertainty
