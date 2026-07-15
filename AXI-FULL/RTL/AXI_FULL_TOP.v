`timescale 1ns / 1ps
module top (
    input  clk, resetn,
    input  op_start,
    output busy,
    input  wr,
    input  [31:0] wr_addr,
    input  [7:0]  wr_burst_len,
    input  [1:0]  wr_burst_type,
    input  [31:0] wr_din,
    input  [3:0]  wr_strbin,
    input  [31:0] rd_addr,
    input  [7:0]  rd_burst_len,
    input  [1:0]  rd_burst_type,
    output [31:0] rout,
    output [1:0]  resp
);
 
    wire [2:0]  m_axi_awid;
    wire [31:0] m_axi_awaddr;
    wire [2:0]  m_axi_awsize;
    wire [1:0]  m_axi_awburst;
    wire [7:0]  m_axi_awlen;
    wire [1:0]  m_axi_awlock;
    wire [3:0]  m_axi_awcache;
    wire [2:0]  m_axi_awprot;
    wire [3:0]  m_axi_awqos;
    wire [4:0]  m_axi_awuser;
    wire        m_axi_awvalid;
    wire        m_axi_awready;
 
    wire [2:0]  m_axi_wid;
    wire [31:0] m_axi_wdata;
    wire [3:0]  m_axi_wstrb;
    wire        m_axi_wlast;
    wire        m_axi_wvalid;
    wire        m_axi_wready;
 
    wire [2:0]  m_axi_bid;
    wire [1:0]  m_axi_bresp;
    wire        m_axi_bvalid;
    wire        m_axi_bready;
 
    wire [2:0]  m_axi_arid;
    wire [31:0] m_axi_araddr;
    wire [7:0]  m_axi_arlen;
    wire [2:0]  m_axi_arsize;
    wire [1:0]  m_axi_arburst;
    wire [1:0]  m_axi_arlock;
    wire [3:0]  m_axi_arcache;
    wire [2:0]  m_axi_arprot;
    wire [3:0]  m_axi_arqos;
    wire [4:0]  m_axi_aruser;
    wire        m_axi_arvalid;
    wire        m_axi_arready;
 
    wire [2:0]  m_axi_rid;
    wire [31:0] m_axi_rdata;
    wire [1:0]  m_axi_rresp;
    wire        m_axi_rlast;
    wire        m_axi_rvalid;
    wire        m_axi_rready;
 
    axif_m uut (
        .m_axi_aclk    (clk),
        .m_axi_aresetn (resetn),
 
        .m_axi_awid    (m_axi_awid),
        .m_axi_awaddr  (m_axi_awaddr),
        .m_axi_awsize  (m_axi_awsize),
        .m_axi_awburst (m_axi_awburst),
        .m_axi_awlen   (m_axi_awlen),
        .m_axi_awlock  (m_axi_awlock),
        .m_axi_awcache (m_axi_awcache),
        .m_axi_awprot  (m_axi_awprot),
        .m_axi_awqos   (m_axi_awqos),
        .m_axi_awuser  (m_axi_awuser),
        .m_axi_awvalid (m_axi_awvalid),
        .m_axi_awready (m_axi_awready),
 
        .m_axi_wid     (m_axi_wid),
        .m_axi_wdata   (m_axi_wdata),
        .m_axi_wstrb   (m_axi_wstrb),
        .m_axi_wlast   (m_axi_wlast),
        .m_axi_wvalid  (m_axi_wvalid),
        .m_axi_wready  (m_axi_wready),
 
        .m_axi_bid     (m_axi_bid),
        .m_axi_bresp   (m_axi_bresp),
        .m_axi_bvalid  (m_axi_bvalid),
        .m_axi_bready  (m_axi_bready),
 
        .m_axi_arid    (m_axi_arid),
        .m_axi_araddr  (m_axi_araddr),
        .m_axi_arlen   (m_axi_arlen),
        .m_axi_arsize  (m_axi_arsize),
        .m_axi_arburst (m_axi_arburst),
        .m_axi_arlock  (m_axi_arlock),
        .m_axi_arcache (m_axi_arcache),
        .m_axi_arprot  (m_axi_arprot),
        .m_axi_arqos   (m_axi_arqos),
        .m_axi_aruser  (m_axi_aruser),
        .m_axi_arvalid (m_axi_arvalid),
        .m_axi_arready (m_axi_arready),
 
        .m_axi_rid     (m_axi_rid),
        .m_axi_rdata   (m_axi_rdata),
        .m_axi_rresp   (m_axi_rresp),
        .m_axi_rlast   (m_axi_rlast),
        .m_axi_rvalid  (m_axi_rvalid),
        .m_axi_rready  (m_axi_rready),
 
        .op_start       (op_start),
        .busy           (busy),
 
        .wr             (wr),
        .wr_addr        (wr_addr),
        .wr_burst_len   (wr_burst_len),
        .wr_burst_type  (wr_burst_type),
        .wr_din         (wr_din),
        .wr_strbin      (wr_strbin),
  
        .rd_addr        (rd_addr),
        .rd_burst_len   (rd_burst_len),
        .rd_burst_type  (rd_burst_type),
 
        .rout (rout),
        .resp (resp)
    );
 
 
    axif_s dut (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (resetn),
 
        .s_axi_awid    (m_axi_awid),
        .s_axi_awvalid (m_axi_awvalid),
        .s_axi_awready (m_axi_awready),
        .s_axi_awaddr  (m_axi_awaddr),
        .s_axi_awlen   (m_axi_awlen),
        .s_axi_awsize  (m_axi_awsize),
        .s_axi_awburst (m_axi_awburst),
        .s_axi_awlock  (m_axi_awlock),
        .s_axi_awcache (m_axi_awcache),
        .s_axi_awprot  (m_axi_awprot),
        .s_axi_awqos   (m_axi_awqos),
        .s_axi_awuser  (m_axi_awuser),
 
        .s_axi_wid     (m_axi_wid),
        .s_axi_wvalid  (m_axi_wvalid),
        .s_axi_wready  (m_axi_wready),
        .s_axi_wdata   (m_axi_wdata),
        .s_axi_wstrb   (m_axi_wstrb),
        .s_axi_wlast   (m_axi_wlast),
 
        .s_axi_bid     (m_axi_bid),
        .s_axi_bvalid  (m_axi_bvalid),
        .s_axi_bready  (m_axi_bready),
        .s_axi_bresp   (m_axi_bresp),
 
        .s_axi_arid    (m_axi_arid),
        .s_axi_arvalid (m_axi_arvalid),
        .s_axi_arready (m_axi_arready),
        .s_axi_araddr  (m_axi_araddr),
        .s_axi_arlen   (m_axi_arlen),
        .s_axi_arsize  (m_axi_arsize),
        .s_axi_arburst (m_axi_arburst),
        .s_axi_arlock  (m_axi_arlock),
        .s_axi_arcache (m_axi_arcache),
        .s_axi_arprot  (m_axi_arprot),
        .s_axi_arqos   (m_axi_arqos),
        .s_axi_aruser  (m_axi_aruser),
  
        .s_axi_rid     (m_axi_rid),
        .s_axi_rvalid  (m_axi_rvalid),
        .s_axi_rready  (m_axi_rready),
        .s_axi_rdata   (m_axi_rdata),
        .s_axi_rlast   (m_axi_rlast),
        .s_axi_rresp   (m_axi_rresp)
    );
 
endmodule