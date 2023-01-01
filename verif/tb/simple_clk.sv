
int clk_period = `MY_CLK_PERIOD;
int d = int'(`MY_CLK_PERIOD/2);

initial begin
  clk     = 1'b0;
end
always begin
`ifdef INTEL_SIMONLY
   #1ns;
   forever #(d) clk = ~clk;
`endif
end
