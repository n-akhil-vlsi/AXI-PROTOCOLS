`timescale 1ns / 1ps
module axif_s (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,

    input  wire [2:0]  s_axi_awid,                                    //most of the signals are application specific so we dont use most of them.
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_awaddr,
    input  wire [7:0]  s_axi_awlen,
    input  wire [2:0]  s_axi_awsize,
    input  wire [1:0]  s_axi_awburst,
    input  wire [1:0]  s_axi_awlock,
    input  wire [3:0]  s_axi_awcache,
    input  wire [2:0]  s_axi_awprot,
    input  wire [3:0]  s_axi_awqos,
    input  wire [4:0]  s_axi_awuser,

    input  wire [2:0]  s_axi_wid,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wlast,

    output reg  [2:0]  s_axi_bid,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    output reg  [1:0]  s_axi_bresp,

    input  wire [2:0]  s_axi_arid,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    input  wire [31:0] s_axi_araddr,
    input  wire [7:0]  s_axi_arlen,
    input  wire [2:0]  s_axi_arsize,
    input  wire [1:0]  s_axi_arburst,
    input  wire [1:0]  s_axi_arlock,
    input  wire [3:0]  s_axi_arcache,
    input  wire [2:0]  s_axi_arprot,
    input  wire [3:0]  s_axi_arqos,
    input  wire [4:0]  s_axi_aruser,

    output reg  [2:0]  s_axi_rid,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    output reg  [31:0] s_axi_rdata,
    output reg         s_axi_rlast,
    output reg  [1:0]  s_axi_rresp
);

    localparam idle          = 0,
               predict_op    = 1,
               accept_wr     = 2,
               wait_wdata    = 3,
               accept_wdata  = 4,
               gen_data      = 5,
               update_mem    = 6,
               check_br_len  = 7,
               send_ack      = 8,
               accept_rd     = 9,
               fetch_rdata   = 10,
               send_rdata    = 11,
               rcheck_br_len = 12,
               fetch_ldata   = 13,
               send_rlast    = 14,
               write_err     = 15,
               comp_rd_tx    = 16;

    initial begin
        s_axi_awready = 0;                         //making the ouputs of the slave low.
        s_axi_wready  = 0;
        s_axi_bid     = 0;
        s_axi_bvalid  = 0;
        s_axi_bresp   = 0;
        s_axi_arready = 0;
        s_axi_rid     = 0;
        s_axi_rvalid  = 0;
        s_axi_rdata   = 0;
        s_axi_rlast   = 0;
        s_axi_rresp   = 0;
    end

    reg [7:0] mem [127:0];                     //memory is declared.

    reg [4:0]  state = 0;
    integer    i = 0;
    reg [7:0]  burst_len = 0, rburst_len = 0;
    reg [31:0] waddr = 0, wdata = 0, raddr = 0, rdata = 0;
    reg [3:0]  wstrb = 0;
    integer    timer = 0;
    reg [31:0] data_write = 0;
    reg [1:0]  count = 0;

    // FIXED-burst byte-lane write
    
    function [31:0] data_wr_fixed(input [3:0] wstrb, input [31:0] awaddrt);
        begin
            case (wstrb)                                           //fixed-mode ---writing or reading the data from the same position again and again.
                4'b0001: begin
                    mem[awaddrt] = wdata[7:0];
                end
                4'b0010: begin
                    mem[awaddrt] = wdata[15:8];
                end
                4'b0011: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[15:8];
                end
                4'b0100: begin
                    mem[awaddrt] = wdata[23:16];
                end
                4'b0101: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[23:16];
                end
                4'b0110: begin
                    mem[awaddrt]   = wdata[15:8];
                    mem[awaddrt+1] = wdata[23:16];
                end
                4'b0111: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[15:8];
                    mem[awaddrt+2] = wdata[23:16];
                end
                4'b1000: begin
                    mem[awaddrt] = wdata[31:24];
                end
                4'b1001: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[31:24];
                end
                4'b1010: begin
                    mem[awaddrt]   = wdata[15:8];
                    mem[awaddrt+1] = wdata[31:24];
                end
                4'b1011: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[15:8];
                    mem[awaddrt+2] = wdata[31:24];
                end
                4'b1100: begin
                    mem[awaddrt]   = wdata[23:16];
                    mem[awaddrt+1] = wdata[31:24];
                end
                4'b1101: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[23:16];
                    mem[awaddrt+2] = wdata[31:24];
                end
                4'b1110: begin
                    mem[awaddrt]   = wdata[15:8];
                    mem[awaddrt+1] = wdata[23:16];
                    mem[awaddrt+2] = wdata[31:24];
                end
                4'b1111: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[15:8];
                    mem[awaddrt+2] = wdata[23:16];
                    mem[awaddrt+3] = wdata[31:24];
                end
            endcase
            data_wr_fixed = awaddrt;                              //in fixed-mode we dont update the address it always write or read at the same position.
        end                                                      //so we are returning the same addres for the next beat. 
    endfunction

    // INCR-burst byte-lane write
    
    reg [31:0] addr = 0;
    function [31:0] data_wr_incr(input [3:0] wstrb, input [31:0] awaddrt);
        begin
            case (wstrb)                                      //for this mode we use the updated address for the next beat.
                4'b0001: begin
                    mem[awaddrt] = wdata[7:0];
                    addr = awaddrt + 1;
                end
                4'b0010: begin
                    mem[awaddrt] = wdata[15:8];
                    addr = awaddrt + 1;
                end
                4'b0011: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[15:8];
                    addr = awaddrt + 2;
                end
                4'b0100: begin
                    mem[awaddrt] = wdata[23:16];
                    addr = awaddrt + 1;
                end
                4'b0101: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[23:16];
                    addr = awaddrt + 2;
                end
                4'b0110: begin
                    mem[awaddrt]   = wdata[15:8];
                    mem[awaddrt+1] = wdata[23:16];
                    addr = awaddrt + 2;
                end
                4'b0111: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[15:8];
                    mem[awaddrt+2] = wdata[23:16];
                    addr = awaddrt + 3;
                end
                4'b1000: begin
                    mem[awaddrt] = wdata[31:24];
                    addr = awaddrt + 1;
                end
                4'b1001: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[31:24];
                    addr = awaddrt + 2;
                end
                4'b1010: begin
                    mem[awaddrt]   = wdata[15:8];
                    mem[awaddrt+1] = wdata[31:24];
                    addr = awaddrt + 2;
                end
                4'b1011: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[15:8];
                    mem[awaddrt+2] = wdata[31:24];
                    addr = awaddrt + 3;
                end
                4'b1100: begin
                    mem[awaddrt]   = wdata[23:16];
                    mem[awaddrt+1] = wdata[31:24];
                    addr = awaddrt + 2;
                end
                4'b1101: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[23:16];
                    mem[awaddrt+2] = wdata[31:24];
                    addr = awaddrt + 3;
                end
                4'b1110: begin
                    mem[awaddrt]   = wdata[15:8];
                    mem[awaddrt+1] = wdata[23:16];
                    mem[awaddrt+2] = wdata[31:24];
                    addr = awaddrt + 3;
                end
                4'b1111: begin
                    mem[awaddrt]   = wdata[7:0];
                    mem[awaddrt+1] = wdata[15:8];
                    mem[awaddrt+2] = wdata[23:16];
                    mem[awaddrt+3] = wdata[31:24];
                    addr = awaddrt + 4;
                end
            endcase
            data_wr_incr = addr;              //here we are returning the updated address for thte next beat.
        end
    endfunction

    // WRAP boundary calculator
   
    reg [7:0] boundary_wr;
    function [7:0] wrap_boundary(input [3:0] awlen, input [2:0] awsize);
        begin
            case (awlen)                 //awlen can only be 1,3,7,15 because the burst count should be power of 2(burst count=awlen+1).
                4'b0001: begin
                    case (awsize)
                        3'b000: boundary_wr = 2*1;           //awsize we are considering only 3 possibilities of 1 byte or 2 bytes or 4 bytes.
                        3'b001: boundary_wr = 2*2;
                        3'b010: boundary_wr = 2*4;
                    endcase
                end
                4'b0011: begin
                    case (awsize)
                        3'b000: boundary_wr = 4*1;
                        3'b001: boundary_wr = 4*2;
                        3'b010: boundary_wr = 4*4;
                    endcase
                end
                4'b0111: begin
                    case (awsize)
                        3'b000: boundary_wr = 8*1;
                        3'b001: boundary_wr = 8*2;
                        3'b010: boundary_wr = 8*4;
                    endcase
                end
                4'b1111: begin
                    case (awsize)
                        3'b000: boundary_wr = 16*1;
                        3'b001: boundary_wr = 16*2;
                        3'b010: boundary_wr = 16*4;
                    endcase
                end
            endcase
            wrap_boundary = boundary_wr;
        end
    endfunction

    // WRAP-burst byte-lane write

    reg [31:0] addr1, addr2, addr3, addr4;
    reg [31:0] nextaddr, nextaddr2;
    function [31:0] data_wr_wrap(input [3:0] wstrb, input [31:0] awaddrt, input [7:0] wboundary);
        begin
            case (wstrb)
                4'b0001: begin
                    mem[awaddrt] = wdata[7:0];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    data_wr_wrap = addr1;
                end
                4'b0010: begin
                    mem[awaddrt] = wdata[15:8];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    data_wr_wrap = addr1;
                end
                4'b0011: begin
                    mem[awaddrt] = wdata[7:0];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    mem[addr1] = wdata[15:8];
                    if ((addr1 + 1) % wboundary == 0)
                        addr2 = (addr1 + 1) - wboundary;
                    else
                        addr2 = addr1 + 1;
                    data_wr_wrap = addr2;
                end
                4'b0100: begin
                    mem[awaddrt] = wdata[23:16];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    data_wr_wrap = addr1;
                end
                4'b0101: begin
                    mem[awaddrt] = wdata[7:0];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    mem[addr1] = wdata[23:16];
                    if ((addr1 + 1) % wboundary == 0)
                        addr2 = (addr1 + 1) - wboundary;
                    else
                        addr2 = addr1 + 1;
                    data_wr_wrap = addr2;
                end
                4'b0110: begin
                    mem[awaddrt] = wdata[15:8];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    mem[addr1] = wdata[23:16];
                    if ((addr1 + 1) % wboundary == 0)
                        addr2 = (addr1 + 1) - wboundary;
                    else
                        addr2 = addr1 + 1;
                    data_wr_wrap = addr2;
                end
                4'b0111: begin
                    mem[awaddrt] = wdata[7:0];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    mem[addr1] = wdata[15:8];
                    if ((addr1 + 1) % wboundary == 0)
                        addr2 = (addr1 + 1) - wboundary;
                    else
                        addr2 = addr1 + 1;
                    mem[addr2] = wdata[23:16];
                    if ((addr2 + 1) % wboundary == 0)
                        addr3 = (addr2 + 1) - wboundary;
                    else
                        addr3 = addr2 + 1;
                    data_wr_wrap = addr3;
                end
                4'b1000: begin
                    mem[awaddrt] = wdata[31:24];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    data_wr_wrap = addr1;
                end
                4'b1001: begin
                    mem[awaddrt] = wdata[7:0];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    mem[addr1] = wdata[31:24];
                    if ((addr1 + 1) % wboundary == 0)
                        addr2 = (addr1 + 1) - wboundary;
                    else
                        addr2 = addr1 + 1;
                    data_wr_wrap = addr2;
                end
                4'b1010: begin
                    mem[awaddrt] = wdata[15:8];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    mem[addr1] = wdata[31:24];
                    if ((addr1 + 1) % wboundary == 0)
                        addr2 = (addr1 + 1) - wboundary;
                    else
                        addr2 = addr1 + 1;
                    data_wr_wrap = addr2;
                end
                4'b1011: begin
                    mem[awaddrt] = wdata[7:0];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    mem[addr1] = wdata[15:8];
                    if ((addr1 + 1) % wboundary == 0)
                        addr2 = (addr1 + 1) - wboundary;
                    else
                        addr2 = addr1 + 1;
                    mem[addr2] = wdata[31:24];
                    if ((addr2 + 1) % wboundary == 0)
                        addr3 = (addr2 + 1) - wboundary;
                    else
                        addr3 = addr2 + 1;
                    data_wr_wrap = addr3;
                end
                4'b1100: begin
                    mem[awaddrt] = wdata[23:16];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    mem[addr1] = wdata[31:24];
                    if ((addr1 + 1) % wboundary == 0)
                        addr2 = (addr1 + 1) - wboundary;
                    else
                        addr2 = addr1 + 1;
                    data_wr_wrap = addr2;
                end
                4'b1101: begin
                    mem[awaddrt] = wdata[7:0];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    mem[addr1] = wdata[23:16];
                    if ((addr1 + 1) % wboundary == 0)
                        addr2 = (addr1 + 1) - wboundary;
                    else
                        addr2 = addr1 + 1;
                    mem[addr2] = wdata[31:24];
                    if ((addr2 + 1) % wboundary == 0)
                        addr3 = (addr2 + 1) - wboundary;
                    else
                        addr3 = addr2 + 1;
                    data_wr_wrap = addr3;
                end
                4'b1110: begin
                    mem[awaddrt] = wdata[15:8];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    mem[addr1] = wdata[23:16];
                    if ((addr1 + 1) % wboundary == 0)
                        addr2 = (addr1 + 1) - wboundary;
                    else
                        addr2 = addr1 + 1;
                    mem[addr2] = wdata[31:24];
                    if ((addr2 + 1) % wboundary == 0)
                        addr3 = (addr2 + 1) - wboundary;
                    else
                        addr3 = addr2 + 1;
                    data_wr_wrap = addr3;
                end
                4'b1111: begin
                    mem[awaddrt] = wdata[7:0];
                    if ((awaddrt + 1) % wboundary == 0)
                        addr1 = (awaddrt + 1) - wboundary;
                    else
                        addr1 = awaddrt + 1;
                    mem[addr1] = wdata[15:8];
                    if ((addr1 + 1) % wboundary == 0)
                        addr2 = (addr1 + 1) - wboundary;
                    else
                        addr2 = addr1 + 1;
                    mem[addr2] = wdata[23:16];
                    if ((addr2 + 1) % wboundary == 0)
                        addr3 = (addr2 + 1) - wboundary;
                    else
                        addr3 = addr2 + 1;
                    mem[addr3] = wdata[31:24];
                    if ((addr3 + 1) % wboundary == 0)
                        addr4 = (addr3 + 1) - wboundary;
                    else
                        addr4 = addr3 + 1;
                    data_wr_wrap = addr4;
                end
            endcase
        end
    endfunction

    // FIXED-burst read
   
    function [31:0] read_data_fixed(input [31:0] addr, input [2:0] arsize);
        begin
            case (arsize)                                          //in write we use wstrb as refernce here we use arsize as the refernce.
                3'b000: begin                                      //the read address for all the beats will be the same address,all of them will be read from the same address.
                    rdata[7:0] = mem[addr];
                end
                3'b001: begin
                    rdata[7:0]  = mem[addr];
                    rdata[15:8] = mem[addr+1];
                end
                3'b010: begin
                    rdata[7:0]   = mem[addr];
                    rdata[15:8]  = mem[addr+1];
                    rdata[23:16] = mem[addr+2];
                    rdata[31:24] = mem[addr+3];
                end
            endcase
            read_data_fixed = addr;
        end
    endfunction

    // INCR-burst read
   
    reg [31:0] rnext_addr = 0;
    function [31:0] read_data_incr(input [31:0] addr, input [2:0] arsize);
        begin
            case (arsize)                                       //the next beat will read from the updated address.
                3'b000: begin
                    rdata[7:0] = mem[addr];
                    rnext_addr = addr + 1;
                end
                3'b001: begin
                    rdata[7:0]  = mem[addr];
                    rdata[15:8] = mem[addr+1];
                    rnext_addr  = addr + 2;
                end
                3'b010: begin
                    rdata[7:0]   = mem[addr];
                    rdata[15:8]  = mem[addr+1];
                    rdata[23:16] = mem[addr+2];
                    rdata[31:24] = mem[addr+3];
                    rnext_addr   = addr + 4;
                end
            endcase
            read_data_incr = rnext_addr;
        end
    endfunction

    // WRAP-burst read

    reg [31:0] raddr1 = 0, raddr2 = 0, raddr3 = 0, raddr4 = 0;
    function [31:0] read_data_wrap(input [31:0] addr, input [2:0] arsize, input [7:0] rboundary);
        begin
            case (arsize)
                3'b000: begin
                    rdata[7:0] = mem[addr];
                    if (((addr + 1) % rboundary) == 0)
                        raddr1 = (addr + 1) - rboundary;
                    else
                        raddr1 = (addr + 1);
                    read_data_wrap = raddr1;
                end
                3'b001: begin
                    rdata[7:0] = mem[addr];
                    if (((addr + 1) % rboundary) == 0)
                        raddr1 = (addr + 1) - rboundary;
                    else
                        raddr1 = (addr + 1);
                    rdata[15:8] = mem[raddr1];
                    if (((raddr1 + 1) % rboundary) == 0)
                        raddr2 = (raddr1 + 1) - rboundary;
                    else
                        raddr2 = (raddr1 + 1);
                    read_data_wrap = raddr2;
                end
                3'b010: begin
                    rdata[7:0] = mem[addr];
                    if (((addr + 1) % rboundary) == 0)
                        raddr1 = (addr + 1) - rboundary;
                    else
                        raddr1 = (addr + 1);
                    rdata[15:8] = mem[raddr1];
                    if (((raddr1 + 1) % rboundary) == 0)
                        raddr2 = (raddr1 + 1) - rboundary;
                    else
                        raddr2 = (raddr1 + 1);
                    rdata[23:16] = mem[raddr2];
                    if (((raddr2 + 1) % rboundary) == 0)
                        raddr3 = (raddr2 + 1) - rboundary;
                    else
                        raddr3 = (raddr2 + 1);
                    rdata[31:24] = mem[raddr3];
                    if (((raddr3 + 1) % rboundary) == 0)
                        raddr4 = (raddr3 + 1) - rboundary;
                    else
                        raddr4 = (raddr3 + 1);
                    read_data_wrap = raddr4;
                end
            endcase
        end
    endfunction

    reg [7:0] boundary = 0, rboundary = 0;
    reg [7:0] awlen = 0, arlen = 0;
    reg [2:0] awsize = 0, arsize = 0;
    reg [1:0] awburst = 0, arburst = 0;

    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 0) begin
            for (i = 0; i < 128; i = i + 1) begin
                mem[i] <= 0;
            end
            state <= idle;
        end else begin
            case (state)

                idle: begin
                    raddr         <= 0;          //making all the outputs of the slave low.
                    rdata         <= 0;
                    addr          <= 0;
                    rboundary     <= 0;
                    data_write    <= 0;
                    awlen         <= 0;
                    arlen         <= 0;
                    arsize        <= 0;
                    awsize        <= 0;
                    arburst       <= 0;
                    awburst       <= 0;
                    boundary_wr   <= 0;
                    addr1         <= 0;
                    addr2         <= 0;
                    addr3         <= 0;
                    addr4         <= 0;
                    s_axi_awready <= 1'b0;
                    s_axi_wready  <= 1'b0;
                    s_axi_bid     <= 3'b000;
                    s_axi_bvalid  <= 1'b0;
                    s_axi_bresp   <= 2'b00;
                    s_axi_arready <= 1'b0;
                    s_axi_rvalid  <= 1'b0;
                    s_axi_rresp   <= 2'b00;
                    s_axi_rid     <= 3'b000;
                    s_axi_rlast   <= 1'b0;
                    s_axi_rdata   <= 32'h0;
                    state         <= predict_op;
                end

                predict_op: begin                        //in master we use wr to detect read or write here we use valid as the refernce.
                    if (s_axi_awvalid)
                        state <= accept_wr;
                    else if (s_axi_arvalid)
                        state <= accept_rd;
                    else
                        state <= idle;
                end

                accept_wr: begin
                    if (s_axi_awaddr < 128 && (s_axi_awaddr + ((s_axi_awlen + 1) * 4) < 128)) begin      //checking the address is it in the limit of the memory.
                        burst_len     <= s_axi_awlen + 1;
                        waddr         <= s_axi_awaddr;
                        state         <= wait_wdata;
                        awlen         <= s_axi_awlen;
                        awsize        <= s_axi_awsize;
                        awburst       <= s_axi_awburst;
                        s_axi_awready <= 1'b1;
                    end else begin
                        s_axi_awready <= 1'b0;
                        state         <= idle;
                    end
                end

                wait_wdata: begin
                    s_axi_awready <= 1'b0;
                    if (s_axi_wvalid) begin
                        state <= accept_wdata;
                        wdata <= s_axi_wdata;
                        wstrb <= s_axi_wstrb;
                    end else if (timer == 15) begin
                        state <= write_err;                            //write_err we are using it as ack state.
                        timer <= 0;
                    end else begin
                        timer <= timer + 1;
                        state <= wait_wdata;
                    end
                end

                accept_wdata: begin
                    s_axi_wready <= 1'b1;
                    state        <= gen_data;
                end

                gen_data: begin
                    s_axi_wready <= 1'b0;
                    data_write   <= {(wdata[31:24] & {8{wstrb[3]}}), 24'h0} |
                                     {8'h0, (wdata[23:16] & {8{wstrb[2]}}), 16'h0} |
                                     {16'h0, (wdata[15:8] & {8{wstrb[1]}}), 8'h0} |
                                     {24'h0, (wdata[7:0] & {8{wstrb[0]}})};
                    state <= update_mem;
                end

                update_mem: begin
                    if (count < 2) begin                       //giving artificial delay of 2 clock cycles.
                        count <= count + 1;
                        state <= update_mem;
                    end else begin
                        count <= 0;
                        state <= check_br_len;
                    end
                end

                check_br_len: begin
                    case (awburst)
                        2'b00: begin
                            waddr <= data_wr_fixed(wstrb, waddr);                //here in the functions the data is write into the memory.
                        end                                                    //adn next address is also calculated.
                        2'b01: begin
                            waddr <= data_wr_incr(wstrb, waddr);
                        end
                        2'b10: begin
                            boundary <= wrap_boundary(awlen, awsize);
                            waddr    <= data_wr_wrap(wstrb, waddr, wrap_boundary(awlen, awsize));
                        end
                    endcase

                    $display("[%0t] WRITE addr=%0d burst_len=%0d", $time, waddr, burst_len);

                    if (burst_len == 1) begin
                        burst_len <= 0;
                        state     <= send_ack;
                    end else begin
                        burst_len <= burst_len - 1;
                        state     <= wait_wdata;
                    end
                end

                send_ack: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp  <= 2'b00;
                        state        <= idle;
                    end else if (timer == 15) begin
                        state <= idle;
                    end else begin
                        timer <= timer + 1;
                        state <= send_ack;
                    end
                end

                accept_rd: begin
                    timer <= 0;
                    if (s_axi_araddr < 128 && (s_axi_araddr + ((s_axi_arlen + 1) * 4) < 128)) begin       //checking whether the read address is within the limits of the memory.
                        rburst_len    <= s_axi_arlen + 1;
                        raddr         <= s_axi_araddr;
                        state         <= (s_axi_arlen == 0) ? fetch_ldata : fetch_rdata;
                        arsize        <= s_axi_arsize;
                        arlen         <= s_axi_arlen;
                        arburst       <= s_axi_arburst;
                        s_axi_arready <= 1'b1;
                    end else begin
                        s_axi_arready <= 1'b0;
                        state         <= idle;
                    end
                end

                fetch_rdata: begin
                    s_axi_arready <= 1'b0;

                    if (count < 2) begin
                        count <= count + 1;
                        state <= fetch_rdata;
                        case (arsize)
                            3'b000:  rdata = {24'h0, mem[raddr]};
                            3'b001:  rdata = {16'h0, mem[raddr+1], mem[raddr]};
                            3'b010:  rdata = {mem[raddr+3], mem[raddr+2], mem[raddr+1], mem[raddr]};
                            default: rdata = {24'h0, mem[raddr]};
                        endcase
                        $display("[%0t] READ addr=%0d rdata=%h", $time, raddr, rdata);
                    end else begin
                        count <= 0;
                        state <= send_rdata;
                    end
                end

                send_rdata: begin
                    s_axi_rvalid <= 1'b1;
                    s_axi_rdata  <= rdata;
                    s_axi_rresp  <= 2'b00;
                    $display("[%0t] SEND DATA addr=%0d data=%h rlast=%b", $time, raddr, rdata, s_axi_rlast);
                    if (s_axi_rready == 1) begin
                        state <= rcheck_br_len;
                    end else if (timer == 15) begin
                        state <= idle;
                        timer <= 0;
                    end else begin
                        state <= send_rdata;
                        timer <= timer + 1;
                    end
                end

                rcheck_br_len: begin
                    rburst_len   <= rburst_len - 1;
                    s_axi_rvalid <= 1'b0;

                    case (arburst)
                        2'b00: begin
                            raddr <= read_data_fixed(raddr, arsize);
                        end
                        2'b01: begin
                            raddr <= read_data_incr(raddr, arsize);
                        end
                        2'b10: begin
                            rboundary <= wrap_boundary(arlen, arsize);
                            raddr     <= read_data_wrap(raddr, arsize, wrap_boundary(arlen, arsize));
                        end
                    endcase

                    $display("[%0t] NEXT ADDR=%0d remaining=%0d", $time, raddr, rburst_len);

                    if (rburst_len == 1) begin
                        state <= fetch_ldata;
                    end else begin
                        state <= fetch_rdata;
                    end
                end

                fetch_ldata: begin
                    if (count < 2) begin
                        count <= count + 1;
                        state <= fetch_ldata;
                        case (arsize)
                            3'b000:  rdata = {24'h0, mem[raddr]};
                            3'b001:  rdata = {16'h0, mem[raddr+1], mem[raddr]};
                            3'b010:  rdata = {mem[raddr+3], mem[raddr+2], mem[raddr+1], mem[raddr]};
                            default: rdata = {24'h0, mem[raddr]};
                        endcase
                    end else begin
                        count        <= 0;
                        timer        <= 0;
                        state        <= send_rlast;
                        s_axi_rvalid <= 1'b1;
                        s_axi_rdata  <= rdata;
                        s_axi_rresp  <= 2'b00;
                        s_axi_rlast  <= 1'b1;
                    end
                end

                send_rlast: begin
                    if (s_axi_rready == 1) begin
                        state        <= idle;
                        s_axi_rvalid <= 1'b0;
                        s_axi_rdata  <= 0;
                        s_axi_rresp  <= 2'b00;
                        s_axi_rlast  <= 1'b0;
                        timer        <= 0;
                    end else if (timer == 15) begin
                        state <= idle;
                        timer <= 0;
                    end else begin
                        state <= send_rlast;
                        timer <= timer + 1;
                    end
                end

                default: state <= idle;
            endcase
        end
    end

endmodule