`timescale 1ns / 1ps
module axif_m (
    input  wire        m_axi_aclk,
    input  wire        m_axi_aresetn,
  
    output reg  [2:0]  m_axi_awid,
    output reg  [31:0] m_axi_awaddr,
    output reg  [2:0]  m_axi_awsize,
    output reg  [1:0]  m_axi_awburst,
    output reg  [7:0]  m_axi_awlen,
    output reg  [1:0]  m_axi_awlock,
    output reg  [3:0]  m_axi_awcache,
    output reg  [2:0]  m_axi_awprot,
    output reg  [3:0]  m_axi_awqos,
    output reg  [4:0]  m_axi_awuser,                 //most of these signnals are application specific.so we dont use all the signals.
    output reg         m_axi_awvalid,
    input  wire        m_axi_awready,
 
    output reg  [2:0]  m_axi_wid,
    output reg  [31:0] m_axi_wdata,
    output reg  [3:0]  m_axi_wstrb,
    output reg         m_axi_wlast,
    output reg         m_axi_wvalid,
    input  wire        m_axi_wready,
 
    input  wire        m_axi_bid,
    input  wire        m_axi_bresp,
    input  wire        m_axi_bvalid,
    output reg         m_axi_bready,
 
    output reg  [2:0]  m_axi_arid,
    output reg  [31:0] m_axi_araddr,
    output reg  [7:0]  m_axi_arlen,
    output reg  [2:0]  m_axi_arsize,
    output reg  [1:0]  m_axi_arburst,
    output reg  [1:0]  m_axi_arlock,
    output reg  [3:0]  m_axi_arcache,
    output reg  [2:0]  m_axi_arprot,
    output reg  [3:0]  m_axi_arqos,
    output reg  [4:0]  m_axi_aruser,
    output reg         m_axi_arvalid,
    input  wire        m_axi_arready,
 
    input  wire [2:0]  m_axi_rid,
    input  wire [31:0] m_axi_rdata,
    input  wire [1:0]  m_axi_rresp,
    input  wire        m_axi_rlast,
    input  wire        m_axi_rvalid,
    output reg         m_axi_rready,
 
    input  wire        op_start,                     //form here these signals are given by us external to the master.
    output reg         busy,
 
    input  wire        wr,
    input  wire [23:0] wr_addr,
    input  wire [7:0]  wr_burst_len,
    input  wire [1:0]  wr_burst_type,
    input  wire [31:0] wr_din,
    input  wire [3:0]  wr_strbin,
 
    input  wire [23:0] rd_addr,
    input  wire [7:0]  rd_burst_len,
    input  wire [1:0]  rd_burst_type,
    output reg  [31:0] rout,
    output reg  [1:0]  resp
);
 
    localparam idle             = 0,
               detect_op        = 1,
               send_waddr       = 2,
               send_wdata       = 3,
               wait_for_wr_resp = 4,
               comp_wr_tx       = 5,
               no_ack_waddr     = 6,
               no_ack_wdata     = 7,
               send_raddr       = 8,
               read_rdata       = 9,
               no_ack_raddr     = 10,
               no_ack_rdata     = 11,
               comp_rd_tx       = 12;
 
    integer burst_count = 0, wr_count = 0, rd_count = 0;
    reg [3:0]  state = idle, next_state = idle;
    reg [31:0] din   = 0;
 
    initial begin
        m_axi_awvalid = 0;             //making all the output signals to the masters low.
        m_axi_awid    = 0;
        m_axi_awaddr  = 0;
        m_axi_awprot  = 0;
        m_axi_wvalid  = 0;
        m_axi_awlen   = 0;
        m_axi_awsize  = 0;
        m_axi_awburst = 0;
        m_axi_awlock  = 0;
        m_axi_awcache = 0;
        m_axi_awqos   = 0;
        m_axi_awuser  = 0;
        m_axi_wid     = 0;
        m_axi_wstrb   = 0;
        m_axi_wlast   = 0;
        m_axi_bready  = 0;
        m_axi_arvalid = 0;
        m_axi_arid    = 0;
        m_axi_araddr  = 0;
        m_axi_arlen   = 0;
        m_axi_arsize  = 0;
        m_axi_arburst = 0;
        m_axi_arqos   = 0;
        m_axi_arprot  = 0;
        m_axi_arlock  = 0;
        m_axi_arcache = 0;
        m_axi_aruser  = 0;
        m_axi_rready  = 0;
        burst_count   = 0;
        din           = 0;
        m_axi_wdata   = 0;
        state         = idle;
        rout          = 0;
        resp          = 0;
        busy          = 0;
    end
 
    always @(posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            state <= idle;
        end else begin
            case (state)
 
                idle: begin
                    m_axi_awvalid <= 0;
                    m_axi_awid    <= 0;
                    m_axi_awaddr  <= 0;
                    m_axi_awprot  <= 0;
                    m_axi_wvalid  <= 0;
                    m_axi_awlen   <= 0;
                    m_axi_awsize  <= 0;
                    m_axi_awburst <= 0;
                    m_axi_awlock  <= 0;
                    m_axi_awcache <= 0;
                    m_axi_awqos   <= 0;
                    m_axi_awuser  <= 0;
                    m_axi_wid     <= 0;
                    m_axi_wstrb   <= 0;
                    m_axi_wlast   <= 0;
                    m_axi_wdata   <= 0;
                    m_axi_bready  <= 0;
                    m_axi_arvalid <= 0;
                    m_axi_arid    <= 0;
                    m_axi_araddr  <= 0;
                    m_axi_arlen   <= 0;
                    m_axi_arsize  <= 0;
                    m_axi_arburst <= 0;
                    m_axi_arqos   <= 0;
                    m_axi_arprot  <= 0;
                    m_axi_arlock  <= 0;
                    m_axi_arcache <= 0;
                    m_axi_aruser  <= 0;
                    m_axi_rready  <= 0;
                    burst_count   <= 0;
                    din           <= 0;
                    busy          <= 0;                           //busy is low when it is in the idle mode and high when it is in the other modes.
                    if (op_start)
                        state <= detect_op;
                    else
                        state <= idle;
                end
 
                detect_op: begin
                    busy <= 1;                                    //if wr is 1 then write ,if 0 then read.
                    if (wr)
                        state <= send_waddr;
                    else
                        state <= send_raddr;
                end
 
                send_waddr: begin
                    din           <= wr_din*5;
                    m_axi_awaddr  <= wr_addr;
                    m_axi_awvalid <= 1;
                    m_axi_wvalid  <= 1;
                    m_axi_awlen   <= wr_burst_len;
                    m_axi_awsize  <= 3'b010;
                    m_axi_awburst <= wr_burst_type;
                    m_axi_wdata   <= wr_din;
                    m_axi_wstrb   <= wr_strbin;
                    m_axi_wlast   <= 0;
                    burst_count   <= wr_burst_len+1;
                    m_axi_bready  <= 1;
 
                    if (m_axi_awready == 1) begin
                        state         <= send_wdata;
                        wr_count      <= 0;
                        m_axi_awvalid <= 0;
                        m_axi_awaddr  <= 0;
                        m_axi_awlen   <= 0;
                        m_axi_awsize  <= 0;
                        m_axi_awburst <= 0;
                    end else if (wr_count == 15) begin                //in real life we dont ack state ,just for simulation we are having it.
                        state    <= no_ack_waddr;
                        wr_count <= 0;
                    end else begin
                        state    <= send_waddr;
                        wr_count <= wr_count + 1;
                    end
                end
  
                send_wdata: begin
                    if (m_axi_wready && burst_count != 1) begin
                        burst_count <= burst_count - 1;
                        din=din*5;
                        m_axi_wdata <= din;                               //we ahve only 1 din from that we are producing other din by multiplying it by 5.
                        state       <= send_wdata;
                        wr_count    <= 0;
                    end else if (m_axi_wready && burst_count == 1) begin
                        burst_count  <= burst_count - 1;
                        m_axi_wdata  <= din;
                        m_axi_wvalid <= 1;
                        m_axi_wlast  <= 1;
                        state        <= wait_for_wr_resp;
                        wr_count     <= 0;
                    end else if (wr_count == 15) begin
                        state <= no_ack_wdata;
                    end else begin
                        state    <= send_wdata;
                        wr_count <= wr_count + 1;
                    end
                    $display("[%0t] MASTER SEND WDATA burst_count=%0d WLAST=%b",$time, burst_count, m_axi_wlast);
                end
                 
 
                no_ack_wdata, no_ack_waddr: begin
                    state <= wait_for_wr_resp;
                end
 
                wait_for_wr_resp: begin
                      m_axi_wlast <= 0;
                      m_axi_wvalid <= 0;
                    if (m_axi_bvalid == 1) begin
                        state        <= comp_wr_tx;
                        m_axi_bready <= 0;
                    end else if (wr_count == 15) begin
                        state    <= idle;
                        wr_count <= 0;
                    end else begin
                        state    <= wait_for_wr_resp;
                        wr_count <= wr_count + 1;
                    end
                end
 
                comp_wr_tx: begin
                    m_axi_awaddr  <= 0;                 //making all the signals low after the write transaction is completed.
                    m_axi_awvalid <= 0;
                    m_axi_wvalid  <= 0;
                    m_axi_wlast   <= 0;
                    m_axi_wdata   <= 0;
                    burst_count   <= 0;
                    m_axi_bready  <= 0;
                    busy          <= 0;                 //busy is low when it is in the idle mode and high when it is in the other modes.
                    state         <= idle;
                end
 
                send_raddr: begin
                    m_axi_araddr  <= rd_addr;               //all the output signals of master which are related to the read are made high nad updated.
                    m_axi_arlen   <= rd_burst_len;
                    m_axi_arsize  <= 3'b010;
                    m_axi_arburst <= rd_burst_type;
                    m_axi_arvalid <= 1;
                    m_axi_rready  <= 0;
                    if (m_axi_arready == 1) begin
                        state         <= read_rdata;
                        m_axi_arvalid <= 0;
                        rd_count      <= 0;
                    end else if (rd_count == 15) begin
                        state    <= no_ack_raddr;
                        rd_count <= 0;
                    end else begin
                        state    <= send_raddr;
                        rd_count <= rd_count + 1;
                    end
                end
 
                read_rdata: begin
                    m_axi_araddr  <= 0;              //signals related to the read read address are made low,as the read address is captured.
                    m_axi_arlen   <= 0;
                    m_axi_arsize  <= 0;
                    m_axi_arburst <= 0;
                    m_axi_arvalid <= 0;
                    m_axi_rready  <= 1;
 
                    if ((m_axi_rvalid == 1'b1) && (m_axi_rlast != 1)) begin  //in the write we use burst count,here we use the rlast to identify the last beat.
                        rout     <= m_axi_rdata;
                        resp     <= m_axi_rresp;
                        state    <= read_rdata;
                        rd_count <= 0;
                    end else if ((m_axi_rvalid == 1'b1) && (m_axi_rlast == 1)) begin
                        rout     <= m_axi_rdata;
                        resp     <= m_axi_rresp;
                        state    <= comp_rd_tx;                                // when the last beat is received we go to the comp_rd_tx state.
                        rd_count <= 0;
                    end else if (rd_count == 15) begin
                        state    <= no_ack_rdata;
                        rd_count <= 0;
                    end else begin
                        rd_count <= rd_count + 1;
                        state    <= read_rdata;
                    end
                end
 
                no_ack_raddr, no_ack_rdata: begin
                    m_axi_rready <= 0;
                    state        <= idle;
                    rout         <= 0;
                    resp         <= 0;
                end
 
                comp_rd_tx: begin
                    m_axi_rready <= 0;
                    state        <= idle;
                end
 
                default: state <= idle;
 
            endcase 
        end
    end
 
endmodule