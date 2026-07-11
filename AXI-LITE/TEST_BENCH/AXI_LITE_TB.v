`timescale 1ns/1ps

module axiltb;

  reg clk = 0;
  reg aresetn = 0;

  reg new_tx = 0;
  reg wr = 0;
  reg [31:0] waddr = 0;
  reg [31:0] raddr = 0;
  reg [31:0] din = 0;
  wire [31:0] dout;
  wire [1:0]  resp;
  wire wr_timeout, rd_timeout;

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
 
  initial begin
    $dumpfile("axiltb.vcd");
    $dumpvars(0, axiltb);

    // reset
    aresetn = 0;
    repeat (5) @(posedge clk);
    aresetn = 1;
    @(posedge clk);

    // ---- WRITE transaction ----
    waddr = 32'd3;
    din   = 32'hDEADBEEF;
    wr    = 1'b1;
    new_tx = 1'b1;
    @(posedge clk);
    new_tx = 1'b0;

    // wait for wr_timeout or completion (watch state via monitor)
    wait (dut.u_master.wstate == 0 && dut.u_master.wr_count == 0 && $time > 100);

    #20;
    if (wr_timeout)
      $display("WRITE RESULT: TIMEOUT at time %0t", $time);
    else
      $display("WRITE RESULT: completed OK (no timeout) at time %0t", $time);

    $display("Slave mem[3] = %h (expected DEADBEEF)", dut.u_slave.mem[3]);

    #40;

    // ---- READ transaction ----
    raddr = 32'd3;
    wr    = 1'b0;
    new_tx = 1'b1;
    @(posedge clk);
    new_tx = 1'b0;

    wait (dut.u_master.rstate == 0 && dut.u_master.rd_count == 0 && $time > 300);
    #20;

    if (rd_timeout)
      $display("READ RESULT: TIMEOUT at time %0t", $time);
    else
      $display("READ RESULT: dout = %h resp=%b (expected DEADBEEF)", dout, resp);

    #50;
    $finish;
  end

  // Safety timeout
  initial begin
    #5000;
    $display("SIMULATION TIMED OUT (hang) at time %0t", $time);
    $finish;
  end

  // Trace key handshake signals
  initial begin
    $monitor("t=%0t wstate=%0d awvalid=%b awready=%b wvalid=%b wready=%b bvalid=%b bready=%b | rstate=%0d arvalid=%b arready=%b rvalid=%b rready=%b",
      $time, dut.u_master.wstate, dut.m_axi_awvalid, dut.m_axi_awready,
      dut.m_axi_wvalid, dut.m_axi_wready, dut.m_axi_bvalid, dut.m_axi_bready,
      dut.u_master.rstate, dut.m_axi_arvalid, dut.m_axi_arready, dut.m_axi_rvalid, dut.m_axi_rready);
  end

endmodule
