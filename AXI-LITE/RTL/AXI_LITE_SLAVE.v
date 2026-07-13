`timescale 1ns / 1ps

module axils
(
 input  wire        s_axi_aclk,
 input  wire        s_axi_aresetn,

 // Write address channel
 input  wire        s_axi_awvalid,
 output reg         s_axi_awready,
 input  wire [31:0] s_axi_awaddr,
 input  wire [2:0]  s_axi_awprot,

 // Write data channel
 input  wire        s_axi_wvalid,
 output reg         s_axi_wready,
 input  wire [31:0] s_axi_wdata,
 input  wire [3:0]  s_axi_wstrb,

 // Write response channel
 output reg         s_axi_bvalid,
 input  wire        s_axi_bready,
 output reg  [1:0]  s_axi_bresp,

 // Read address channel
 input  wire        s_axi_arvalid,
 output reg         s_axi_arready,
 input  wire [31:0] s_axi_araddr,
 input  wire [2:0]  s_axi_arprot,

 // Read data channel
 output reg         s_axi_rvalid,
 input  wire        s_axi_rready,
 output reg  [31:0] s_axi_rdata,
 output reg  [1:0]  s_axi_rresp
);

localparam idle          = 0,
           predict_op    = 1,
           accept_wr     = 2,
           wait_wdata    = 3,
           accept_wdata  = 4,
           gen_data      = 5,
           update_mem    = 6,
           send_ack      = 7,
           accept_rd     = 8,
           fetch_rdata   = 9,
           send_rdata    = 10;

initial begin
 s_axi_awready = 0;
 s_axi_wready  = 0;
 s_axi_bvalid  = 0;
 s_axi_bresp   = 0;
 s_axi_arready = 0;
 s_axi_rvalid  = 0;
 s_axi_rdata   = 0;
 s_axi_rresp   = 0;
end

reg [31:0] mem [15:0];   // 16 word-addressable locations (addr 0-15), same as original

reg [3:0]  state = 0;
integer    i = 0;
reg [31:0] waddr = 0, wdata = 0, raddr = 0, rdata = 0;
reg [3:0]  wstrb = 0;
integer    timer = 0;
reg [31:0] data_write = 0;
reg [1:0]  count = 0;

always @(posedge s_axi_aclk) begin
 if (s_axi_aresetn == 0) begin
   for (i = 0; i < 16; i = i + 1) begin
     mem[i] <= 0;
   end
   state         <= idle;
   s_axi_awready <= 1'b0;
   s_axi_wready  <= 1'b0;
   s_axi_bvalid  <= 1'b0;
   s_axi_bresp   <= 2'b00;
   s_axi_arready <= 1'b0;
   s_axi_rvalid  <= 1'b0;
   s_axi_rdata   <= 32'h0;
   s_axi_rresp   <= 2'b00;
   timer         <= 0;
   count         <= 0;
 end else begin
   case (state)

   idle: begin
     s_axi_awready <= 1'b0;
     s_axi_wready  <= 1'b0;
     s_axi_bvalid  <= 1'b0;
     s_axi_bresp   <= 2'b00;
     s_axi_arready <= 1'b0;
     s_axi_rvalid  <= 1'b0;
     s_axi_rresp   <= 2'b00;
     s_axi_rdata   <= 32'h0;
     state <= predict_op;
   end

   predict_op: begin                         //path will be decided by the which valid is high.
     if (s_axi_awvalid)
       state <= accept_wr;
     else if (s_axi_arvalid)
       state <= accept_rd;
   end

   // ---------------- WRITE PATH ----------------
   accept_wr: begin
     if (s_axi_awaddr < 16) begin
       waddr         <= s_axi_awaddr;       //storing the address for accessing the memory location.
       s_axi_awready <= 1'b1;
       state         <= wait_wdata;
     end else begin
       s_axi_awready <= 1'b0;
       state         <= idle;
     end
   end

   wait_wdata: begin
     s_axi_awready <= 1'b0;
     if (s_axi_wvalid) begin                    //making the awready low as it will be high for only one clock cycle.
       wdata <= s_axi_wdata;
       wstrb <= s_axi_wstrb;
       state <= accept_wdata;
       timer <= 0;
     end else if (timer == 15) begin
       state <= idle;
       timer <= 0;
     end else begin
       timer <= timer + 1;
       state <= wait_wdata;
     end
   end

   accept_wdata: begin
     s_axi_wready <= 1'b1;                   //making the wready high for one clock cycle to accept the data from the master.
     state        <= gen_data;
   end

   gen_data: begin
     s_axi_wready <= 1'b0;                                   //generating the data by multiplying the data bytes with the strb.
     data_write   <= {(wdata[31:24] & {8{wstrb[3]}}),
                       (wdata[23:16] & {8{wstrb[2]}}),
                       (wdata[15:8]  & {8{wstrb[1]}}),
                       (wdata[7:0]   & {8{wstrb[0]}})};
     state <= update_mem;
   end

   update_mem: begin
     if (count < 2) begin                           //here artifical delay of 2 clock cycles are added.
       count      <= count + 1;
       mem[waddr] <= data_write;
       state      <= update_mem;
     end else begin
       count <= 0;
       state <= send_ack;
     end
   end

   send_ack: begin
     s_axi_bvalid <= 1'b1;
     s_axi_bresp  <= 2'b00;
     if (s_axi_bready) begin
       state <= idle;
       timer <= 0;
     end else if (timer == 15) begin
       state <= idle;
       timer <= 0;
     end else begin
       timer <= timer + 1;
       state <= send_ack;
     end
   end

   // ---------------- READ PATH ----------------
   accept_rd: begin
     if (s_axi_araddr < 16) begin                           //valid only for address less than 16 as the memory locations are only 16.
       raddr         <= s_axi_araddr;
       s_axi_arready <= 1'b1;
       state         <= fetch_rdata;
     end else begin
       s_axi_arready <= 1'b0;
       state         <= idle;
     end
   end

   fetch_rdata: begin
     s_axi_arready <= 1'b0;
     if (count < 2) begin                               //artifical delay of 2 clock cycles are added to fetch the data from the memory location.
       count <= count + 1;
       rdata <= mem[raddr];
       state <= fetch_rdata;
     end else begin
       count <= 0;
       state <= send_rdata;
     end
   end

   send_rdata: begin
     s_axi_rvalid <= 1'b1;
     s_axi_rdata  <= rdata;
     s_axi_rresp  <= 2'b00;
     if (s_axi_rready) begin
       state <= idle;
       timer <= 0;
     end else if (timer == 15) begin
       state <= idle;
       timer <= 0;
     end else begin
       timer <= timer + 1;
       state <= send_rdata;
     end
   end

   default: state <= idle;
   endcase
 end
end

endmodule
