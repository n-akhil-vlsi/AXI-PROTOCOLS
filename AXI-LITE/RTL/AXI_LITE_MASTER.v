`timescale 1ns / 1ps

module axilm
(   
  input wire     new_tx,
  input wire     wr,
  input wire  [31:0] waddr,
  input wire  [31:0] raddr,
  input wire  [31:0] din,
  output reg [31:0]  dout,
  output reg [1:0]  resp,
  output reg     wr_timeout, rd_timeout, 

  input wire    m_axi_aclk,
  input wire    m_axi_aresetn,
  output reg     m_axi_awvalid,
  input wire     m_axi_awready,
  output reg [31: 0] m_axi_awaddr,

  output reg     m_axi_wvalid,
  input wire     m_axi_wready,
  output reg [31: 0] m_axi_wdata,
  output reg [3: 0] m_axi_wstrb,

  input wire     m_axi_bvalid,
  output reg     m_axi_bready,
  input wire [1: 0] m_axi_bresp,

  output reg     m_axi_arvalid,
  input wire     m_axi_arready,
  output reg [31: 0] m_axi_araddr,

  input wire     m_axi_rvalid,
  output reg     m_axi_rready,
  input wire [31: 0] m_axi_rdata,
  input wire [1: 0] m_axi_rresp
);


/////////////write FSM   

localparam wr_idle      = 0, 
      wait_for_wr_op   = 1,
      waddr_write    = 2,
      wait_for_wdata_ack = 3,
      wait_for_wr_resp  = 4,
      no_ack_wdata    = 5,
      no_ack_waddr    = 6,
      no_slave_wr_resp  = 7,
      comp_wr_tx     = 8;
      
reg [3:0] wstate   = wr_idle;
reg [3:0] wnext_state = wr_idle;
reg [3:0] wr_count  = 0;
      
////////////////reset decoding
always @(posedge m_axi_aclk) begin
  if (m_axi_aresetn == 1'b0)
    wstate <= wr_idle;
  else
    wstate <= wnext_state;     
end

/////////////////next state decoder
always @(*) begin
  m_axi_awvalid = 0;
  m_axi_awaddr  = 0;
  m_axi_wvalid  = 0;
  m_axi_wdata   = 0;
  m_axi_wstrb   = 0;
  m_axi_bready  = 0;
  wr_timeout    = 1'b0;
  wnext_state   = wstate;

  case (wstate)
    wr_idle: begin
      if(new_tx == 1'b1)
      wnext_state  = wait_for_wr_op;
      else
      wnext_state  = wr_idle;
    end

    wait_for_wr_op: begin
      if (wr == 1)                        //if wr is high then the write operation will be performed.else read operation will be performed.
        wnext_state = waddr_write;
      else
        wnext_state = wr_idle;
    end

    waddr_write: begin                 // in this all the master ouputs related to the wirte are updated.
      m_axi_wstrb  = 4'b1111;
      m_axi_awvalid = 1;
      m_axi_wvalid = 1;
      m_axi_awaddr = waddr;
      m_axi_wdata  = din;
      m_axi_bready = 1;
       
      if (m_axi_awready == 1 && m_axi_wready == 1)
        wnext_state = wait_for_wr_resp;
      else if (m_axi_awready == 1)
        wnext_state = wait_for_wdata_ack;
      else if (wr_count == 15)
        wnext_state = no_ack_waddr;
      else
        wnext_state = waddr_write;
    end

    wait_for_wdata_ack: begin
      m_axi_awvalid = 0;
      m_axi_awaddr = 0;
      m_axi_bready = 1;               // now after awready is high then the signals relateed to the write address will be deasserted.
      m_axi_wvalid = 1;               
      m_axi_wdata  = din;             
      m_axi_wstrb  = 4'b1111;         
      if (m_axi_wready == 1)           
        wnext_state = wait_for_wr_resp;
      else if (wr_count == 14)              
        wnext_state = no_ack_wdata;
      else
        wnext_state = wait_for_wdata_ack;   
    end

    wait_for_wr_resp: begin
      m_axi_awvalid = 0;            //after the wready is high then the signals related to the write data will be deasserted.
      m_axi_wvalid  = 0;
      m_axi_wdata   = 0;
      m_axi_awaddr  = 0;
      m_axi_bready  = 1;             
      if (m_axi_bvalid == 1)
        wnext_state = comp_wr_tx;
      else if (wr_count == 14)
        wnext_state = no_slave_wr_resp;
      else
        wnext_state = wait_for_wr_resp; 
    end

    no_ack_wdata, no_ack_waddr: begin
      wr_timeout = 1'b1;                  //now also it is having the chance to complete the write operation again waiting fot the 15 cycles.
      m_axi_bready = 1;
      if (m_axi_bvalid == 1)
        wnext_state = comp_wr_tx;
      else if (wr_count == 14)
        wnext_state = no_slave_wr_resp;
      else
        wnext_state = wstate;          // fix: explicit hold (was latched before)
    end

    no_slave_wr_resp: begin
      wr_timeout = 1'b1;
      wnext_state = wr_idle;                 
    end

    comp_wr_tx: begin
      m_axi_bready = 0;
      wnext_state = wr_idle;
    end

    default: wnext_state = wr_idle;
  endcase
end

wire first;
reg first_d;
assign first = (wstate != wnext_state) ? 1'b1 : 0;             //logic for the same counter to count for all the states.

always@(posedge m_axi_aclk)
begin
first_d <= first;                           //non-blocking assingment when the firt is high then in the next cycle first_d is high.
end                                         //so we are  counting only for the 14 clock cycles.


///////write counter
always @(posedge m_axi_aclk) begin
  case (wstate)
    wr_idle:          wr_count <= 0;
     
    wait_for_wr_op:       wr_count <= 0;
     
    waddr_write  :       wr_count <= wr_count + 1;
     
    wait_for_wdata_ack:
    begin
    if(first_d)                            //if state change then first_d become high and countere is set to 0.
    wr_count <= 0;
    else
    wr_count <= wr_count + 1;
    end
     
    wait_for_wr_resp:
    begin
    if(first_d)
    wr_count <= 0;
    else
    wr_count <= wr_count + 1;
    end
     
    no_ack_wdata:
    begin
    if(first_d)
    wr_count <= 0;
    else
    wr_count <= wr_count + 1;
    end
     
    no_ack_waddr:
    begin
    if(first_d)
    wr_count <= 0;
    else
    wr_count <= wr_count + 1;
    end
          
    no_slave_wr_resp:      wr_count <= 0;
     
    comp_wr_tx:         wr_count <= 0;
      
    default:          wr_count <= 0;
  endcase
end



/////////////////read FSM

localparam rd_idle     = 0, 
      wait_for_rd_op = 1,
      raddr_write   = 2,
      wait_for_rdata = 3,
      no_resp_raddr  = 4,
      no_resp_rdata  = 5,
      no_slave_rd_resp = 6,    
      comp_rd_tx = 7; 

reg [2:0] rstate   = rd_idle, rnext_state = rd_idle;
reg [3:0] rd_count  = 0;

always @(posedge m_axi_aclk) begin
  if (m_axi_aresetn == 1'b0)
    rstate <= rd_idle;
  else
    rstate <= rnext_state;
end


always @(*) begin
  m_axi_arvalid = 0;
  m_axi_araddr  = 0;
  m_axi_rready  = 0;
  rd_timeout    = 1'b0;
  rnext_state   = rstate;

  case (rstate)
    rd_idle: begin
      if(new_tx == 1'b1)                           //new_tx should be high for both the read and write operations.
      rnext_state  = wait_for_rd_op;
      else
      rnext_state  = rd_idle;
       
    end

    wait_for_rd_op: begin
      if (wr == 0)                               //wr is low then it is read.
        rnext_state = raddr_write;
      else
        rnext_state = rd_idle;
    end

    raddr_write: begin
      m_axi_arvalid = 1;                        //all the master output related to the read are updated. 
      m_axi_araddr = raddr;
      m_axi_rready = 1'b1;
       
      if(m_axi_arready == 1 && m_axi_rvalid == 1)
        rnext_state = comp_rd_tx;
      else if (m_axi_arready == 1)
        rnext_state = wait_for_rdata;
      else if (rd_count == 15)
        rnext_state = no_resp_raddr;
      else
        rnext_state = raddr_write;
    end

    wait_for_rdata: begin
      m_axi_arvalid = 0;
      m_axi_araddr = 0;
      m_axi_rready = 1'b1;            //if arreadyis high then the signals related to the read address will be deasserted.
      if (m_axi_rvalid == 1)
        rnext_state = comp_rd_tx;
      else if (rd_count == 14)
        rnext_state = no_resp_rdata;
      else
        rnext_state = wait_for_rdata; 
    end

    no_resp_raddr, no_resp_rdata: begin
      rd_timeout = 1'b1;
      m_axi_rready = 1;                     //now also it has a chance to complete the read operation again waiting for the 15 cycles.
      if (m_axi_rvalid == 1) begin
        rnext_state = comp_rd_tx;          
      end else if (rd_count == 14) begin
        rnext_state = no_slave_rd_resp;     
      end else begin
        rnext_state = rstate;               
      end
    end
    
    no_slave_rd_resp: begin
      rd_timeout = 1'b1;
      rnext_state = rd_idle;                // final, unconditional give-up
    end

    comp_rd_tx: begin
      m_axi_rready = 1'b0;
      m_axi_arvalid = 1'b0;
      rnext_state  = rd_idle;
    end

    default: rnext_state = rd_idle;
  endcase
end


always @(posedge m_axi_aclk) begin                     //dout and the resp are the outputs of the master ,i.e they are m_axi_rdata and m_axi_rresp(but these are inputs to the master).
  if (m_axi_aresetn == 1'b0) begin
    dout <= 32'h0;
    resp <= 2'b00;
  end else if (rstate == raddr_write && m_axi_arready == 1'b1 && m_axi_rvalid == 1'b1) begin
    dout <= m_axi_rdata;
    resp <= m_axi_rresp;
  end else if (rstate == wait_for_rdata && m_axi_rvalid == 1'b1) begin
    dout <= m_axi_rdata;
    resp <= m_axi_rresp;
  end
end

wire first_r;
reg first_d_r;
assign first_r = (rstate != rnext_state) ? 1'b1 : 0;               //logic for the same counter to count for all the states of the read operation.

always@(posedge m_axi_aclk)
begin
first_d_r <= first_r;
end



//////////////read counter
always @(posedge m_axi_aclk) begin
  case (rstate)
    rd_idle,
    wait_for_rd_op,
    no_resp_raddr,
    no_resp_rdata,
    comp_rd_tx: rd_count <= 0;

    raddr_write : rd_count <= rd_count + 1;
    wait_for_rdata: 
    begin
    if(first_d_r)
    rd_count <= 0;
    else
    rd_count <= rd_count + 1;
    end

    default: rd_count <= 0;
  endcase
end

  


endmodule

