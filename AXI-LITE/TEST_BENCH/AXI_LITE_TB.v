`timescale 1ns / 1ps

module axil_simple_tb;

  reg         clk = 0;
  reg         aresetn = 0;
  reg         new_tx = 0;
  reg         wr = 0;
  reg  [31:0] waddr = 0;
  reg  [31:0] raddr = 0;
  reg  [31:0] din = 0;
  wire [31:0] dout;
  wire [1:0]  resp;
  wire        wr_timeout, rd_timeout;

  axilltop dut (
    .clk(clk),
    .aresetn(aresetn),
    .new_tx(new_tx),
    .wr(wr),
    .waddr(waddr),
    .raddr(raddr),
    .din(din),
    .dout(dout),
    .resp(resp),
    .wr_timeout(wr_timeout),
    .rd_timeout(rd_timeout)
  );

 
  always #5 clk = ~clk;

  // Display every new_tx pulse
  always @(posedge new_tx)
    $display("[%0t] new_tx pulse", $time);

  initial begin
    $dumpfile("axil_simple_tb.vcd");
    $dumpvars(0, axil_simple_tb);

    aresetn = 0;
    repeat (5) @(posedge clk);
    aresetn = 1;
    @(posedge clk);

    // 1) WRITE : addr=3
    waddr = 32'd3;
    din   = 32'hAAAABBBB;
    wr    = 1'b1;

    @(negedge clk);
    new_tx = 1'b1;
    @(posedge clk);
    new_tx = 1'b0;

    wait(dut.u_master.wstate != 0);
    wait(dut.u_master.wstate == 0 && dut.u_master.wr_count == 0);

    #20;
    if(wr_timeout)
      $display("[%0t] WRITE addr=3 TIMEOUT",$time);
    else
      $display("[%0t] WRITE addr=3 OK  mem=%h",$time,dut.u_slave.mem[3]);

    #20;

    // 2) READ : addr=3
    raddr = 32'd3;
    wr    = 1'b0;

    @(negedge clk);
    new_tx = 1'b1;
    @(posedge clk);
    new_tx = 1'b0;

    wait(dut.u_master.rstate != 0);
    wait(dut.u_master.rstate == 0 && dut.u_master.rd_count == 0);

    #20;
    if(rd_timeout)
      $display("[%0t] READ addr=3 TIMEOUT",$time);
    else
      $display("[%0t] READ addr=3 dout=%h resp=%b",$time,dout,resp);

    #20;

    // 3) WRITE : addr=7
    waddr = 32'd7;
    din   = 32'hCAFEF00D;
    wr    = 1'b1;

    @(negedge clk);
    new_tx = 1'b1;
    @(posedge clk);
    new_tx = 1'b0;

    wait(dut.u_master.wstate != 0);
    wait(dut.u_master.wstate == 0 && dut.u_master.wr_count == 0);

    // 4) READ : addr=7
    raddr = 32'd7;
    wr    = 1'b0;

    @(negedge clk);
    new_tx = 1'b1;
    @(posedge clk);
    new_tx = 1'b0;

    wait(dut.u_master.rstate != 0);
    wait(dut.u_master.rstate == 0 && dut.u_master.rd_count == 0);

    #20;
    if(rd_timeout)
      $display("[%0t] READ addr=7 TIMEOUT",$time);
    else
      $display("[%0t] READ addr=7 dout=%h resp=%b (expected CAFEF00D)",
               $time,dout,resp);

    #50;
    $display("TB DONE");
    $finish;
  end

  // Safety timeout
  initial begin
    #5000;
    $display("SIMULATION HUNG at time %0t",$time);
    $finish;
  end

endmodule