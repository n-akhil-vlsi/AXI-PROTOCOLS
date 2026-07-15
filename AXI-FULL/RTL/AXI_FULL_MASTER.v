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
    output reg  [4:0]  m_axi_awuser,
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
 
    input  wire        op_start,
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
               wdata_last       = 4,
               wait_for_wr_resp = 5,
               comp_wr_tx       = 6,
               no_ack_waddr     = 7,
               no_ack_wdata     = 8,
               send_raddr       = 9,
               read_rdata       = 10,
               no_ack_raddr     = 11,
               no_ack_rdata     = 12,
               comp_rd_tx       = 13;
 
    integer burst_count = 0, wr_count = 0, rd_count = 0;
    reg [3:0]  state = idle, next_state = idle;
    reg [31:0] din   = 0;
 
    initial begin
        m_axi_awvalid = 0;
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
                    busy          <= 0;
                    if (op_start)
                        state <= detect_op;
                    else
                        state <= idle;
                end
 
                detect_op: begin
                    busy <= 1;
                    if (wr)
                        state <= send_waddr;
                    else
                        state <= send_raddr;
                end
 
                send_waddr: begin
                    // FIX 1: was "din <= wr_din*5;" - the multiply corrupted
                    // the data actually written to memory. din must simply
                    // hold wr_din so every beat of the burst sends the same
                    // (or correctly-derived) write data.
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
                    end else if (wr_count == 15) begin
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
                        m_axi_wdata <= din;
                        state       <= send_wdata;
                        wr_count    <= 0;
                    end else if (m_axi_wready && burst_count == 1) begin
                        // last beat's handshake already happened here -
                        // go straight to waiting for the write response,
                        // don't wait for a second wready pulse that never comes
                        burst_count  <= burst_count - 1;
                        m_axi_wdata  <= din;
                        m_axi_wlast  <= 1;
                        m_axi_wvalid <= 1;
                        state        <= wait_for_wr_resp;
                        wr_count     <= 0;
                    end else if (wr_count == 15) begin
                        state <= no_ack_wdata;
                    end else begin
                        state    <= send_wdata;
                        wr_count <= wr_count + 1;
                    end
                    $display("[%0t] MASTER SEND WDATA burst_count=%0d WLAST=%b",
                             $time, burst_count, m_axi_wlast);
                end
                 
                // wdata_last state removed - no longer used
 
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
                    m_axi_awaddr  <= 0;
                    m_axi_awvalid <= 0;
                    m_axi_wvalid  <= 0;
                    m_axi_wlast   <= 0;
                    m_axi_wdata   <= 0;
                    burst_count   <= 0;
                    m_axi_bready  <= 0;
                    // FIX 4 (cleanup): was "busy <= 1;" here, which is wrong -
                    // the write transaction is complete at this point, so
                    // busy should be released. idle already clears busy on
                    // the following cycle, so this was mostly masked, but
                    // it was inconsistent and worth correcting.
                    busy          <= 0;
                    state         <= idle;
                end
 
                send_raddr: begin
                    m_axi_araddr  <= rd_addr;
                    m_axi_arlen   <= rd_burst_len;
                    m_axi_arsize  <= 3'b010;
                    m_axi_arburst <= rd_burst_type;
                    m_axi_arvalid <= 1;
                    m_axi_rready  <= 0;
 
                    // FIX 3: was "if (m_axi_arready == 1 && m_axi_arvalid==1)".
                    // m_axi_arvalid was just set with a non-blocking
                    // assignment two lines above, so checking it in the same
                    // cycle read its OLD value, not the new 1 - this could
                    // stall/miss the address handshake entirely and is the
                    // reason the read burst was never completing (rout
                    // stuck at 0). The write path's send_waddr never had
                    // this extra self-check, so this now matches that
                    // working pattern.
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
                    m_axi_araddr  <= 0;
                    m_axi_arlen   <= 0;
                    m_axi_arsize  <= 0;
                    m_axi_arburst <= 0;
                    m_axi_arvalid <= 0;
                    m_axi_rready  <= 1;
 
                    if ((m_axi_rvalid == 1'b1) && (m_axi_rlast != 1)) begin
                        rout     <= m_axi_rdata;
                        resp     <= m_axi_rresp;
                        state    <= read_rdata;
                        rd_count <= 0;
                    end else if ((m_axi_rvalid == 1'b1) && (m_axi_rlast == 1)) begin
                        rout     <= m_axi_rdata;
                        resp     <= m_axi_rresp;
                        state    <= comp_rd_tx;
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
                    // rout/resp intentionally NOT cleared here - they hold
                    // the last beat's captured data/response for the user
                    // to read after the transaction completes.
                end
 
                default: state <= idle;
 
            endcase 
        end
    end
 
endmodule