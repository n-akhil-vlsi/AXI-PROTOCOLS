module axilltop (
  input wire clk,
  input wire aresetn,

  input wire        new_tx,
  input wire        wr,
  input wire [31:0] waddr,
  input wire [31:0] raddr,
  input wire [31:0] din,
  output wire [31:0] dout,
  output wire [1:0]  resp,
  output wire        wr_timeout,
  output wire        rd_timeout
);

  wire        m_axi_awvalid, m_axi_awready;
  wire [31:0] m_axi_awaddr;
  wire        m_axi_wvalid, m_axi_wready;
  wire [31:0] m_axi_wdata;
  wire [3:0]  m_axi_wstrb;
  wire        m_axi_bvalid, m_axi_bready;
  wire [1:0]  m_axi_bresp;
  wire        m_axi_arvalid, m_axi_arready;
  wire [31:0] m_axi_araddr;
  wire        m_axi_rvalid, m_axi_rready;
  wire [31:0] m_axi_rdata;
  wire [1:0]  m_axi_rresp;

  axilm u_master (
    .new_tx(new_tx),
    .wr(wr),
    .waddr(waddr),
    .raddr(raddr),
    .din(din),
    .dout(dout),
    .resp(resp),
    .wr_timeout(wr_timeout),
    .rd_timeout(rd_timeout),

    .m_axi_aclk(clk),
    .m_axi_aresetn(aresetn),

    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_awready(m_axi_awready),
    .m_axi_awaddr(m_axi_awaddr),

    .m_axi_wvalid(m_axi_wvalid),
    .m_axi_wready(m_axi_wready),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wstrb(m_axi_wstrb),

    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_bready(m_axi_bready),
    .m_axi_bresp(m_axi_bresp),

    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_araddr(m_axi_araddr),

    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp)
  );

  axils u_slave (
    .s_axi_aclk(clk),
    .s_axi_aresetn(aresetn),

    .s_axi_awvalid(m_axi_awvalid),
    .s_axi_awready(m_axi_awready),
    .s_axi_awaddr(m_axi_awaddr),
    .s_axi_awprot(3'b000),

    .s_axi_wvalid(m_axi_wvalid),
    .s_axi_wready(m_axi_wready),
    .s_axi_wdata(m_axi_wdata),
    .s_axi_wstrb(m_axi_wstrb),

    .s_axi_bvalid(m_axi_bvalid),
    .s_axi_bready(m_axi_bready),
    .s_axi_bresp(m_axi_bresp),

    .s_axi_arvalid(m_axi_arvalid),
    .s_axi_arready(m_axi_arready),
    .s_axi_araddr(m_axi_araddr),
    .s_axi_arprot(3'b000),

    .s_axi_rvalid(m_axi_rvalid),
    .s_axi_rready(m_axi_rready),
    .s_axi_rdata(m_axi_rdata),
    .s_axi_rresp(m_axi_rresp)
  );

endmodule
