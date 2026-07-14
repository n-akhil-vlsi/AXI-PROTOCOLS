`timescale 1ns / 1ps
// Simple TB for axilite_gpio: verifies LED write and SW debounced read
module axil_gpio_tb;
 
  reg         clk = 0;
  reg         aresetn = 0;
 
  reg         awvalid = 0;
  reg  [31:0] awaddr  = 0;
  reg         wvalid  = 0;
  reg  [31:0] wdata   = 0;
  reg  [3:0]  wstrb   = 0;
  reg         bready  = 0;
 
  reg         arvalid = 0;
  reg  [31:0] araddr  = 0;
  reg         rready  = 0;
 
  reg  [31:0] sw = 0;
 
  wire        awready, wready, bvalid, arready, rvalid;
  wire [1:0]  bresp, rresp;
  wire [2:0]  bid;
  wire [31:0] rdata, led;
 
  axil_gpio dut (
    .s_axi_aclk(clk),
    .s_axi_aresetn(aresetn),
    .s_axi_awvalid(awvalid),
    .s_axi_awready(awready),
    .s_axi_awaddr(awaddr),
    .s_axi_wvalid(wvalid),
    .s_axi_wready(wready),
    .s_axi_wdata(wdata),
    .s_axi_wstrb(wstrb),
    .s_axi_bid(bid),
    .s_axi_bvalid(bvalid),
    .s_axi_bready(bready),
    .s_axi_bresp(bresp),
    .s_axi_arvalid(arvalid),
    .s_axi_arready(arready),
    .s_axi_araddr(araddr),
    .s_axi_rvalid(rvalid),
    .s_axi_rready(rready),
    .s_axi_rdata(rdata),
    .s_axi_rresp(rresp),
    .led(led),
    .sw(sw)
  );
 
  always #5 clk = ~clk;
 
  initial begin
    $dumpfile("axil_gpio_tb.vcd");
    $dumpvars(0, axil_gpio_tb);
 
    //  Reset
    aresetn = 0;
    repeat (5) @(posedge clk);
    aresetn = 1;
    @(posedge clk);
 
    //  1. WRITE LED (addr=4, data=A5A5A5A5) 
    awvalid = 1; awaddr = 32'd4;
    wvalid  = 1; wdata  = 32'hA5A5A5A5; wstrb = 4'hF;
    bready  = 1;
    wait (bvalid == 1);
    @(posedge clk);
    awvalid = 0; wvalid = 0; bready = 0;
    #10;
    $display("[%0t] LED WRITE -> led=%h (expected a5a5a5a5)", $time, led);
 
    #20;
 
    //  2. Simulate switch bounce before it settles 
    sw = 32'h00000000;
    @(posedge clk); sw = 32'h00FF00FF;   // glitch 1
    @(posedge clk); sw = 32'h00000000;   // glitch 2
    @(posedge clk); sw = 32'h00FF00FF;   // glitch 3
    @(posedge clk); sw = 32'h00000000;   // glitch 4
    @(posedge clk);
    $display("[%0t] During bounce -> sw_reg=%h (expected 00000000, must NOT update)", $time, dut.sw_reg);
 
    // 3. Now let it settle to a stable value
    sw = 32'h00FF00FF;
    repeat (10) @(posedge clk);   // debounce needs ~6 stable cycles
    $display("[%0t] After settle -> sw_reg=%h (expected 00ff00ff)", $time, dut.sw_reg);
 
    // 4. READ SW (addr=8) 
    arvalid = 1; araddr = 32'd8;
    rready  = 1;
    wait (rvalid == 1);
    #1;   // let rdata settle in the same cycle rvalid asserts
    $display("[%0t] SW READ  -> rdata=%h (expected 00ff00ff)", $time, rdata);
    @(posedge clk);
    arvalid = 0; rready = 0;
  
    #50;
    $display("TB DONE");
    $finish;
  end
 
  // Safety timeout
  initial begin
    #5000;
    $display("SIMULATION HUNG at time %0t", $time);
    $finish;
  end
 
endmodule