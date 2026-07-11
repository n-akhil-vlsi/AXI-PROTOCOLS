module axilite_s
(
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,

    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0]  s_axi_awaddr,

    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,

    output reg [2:0]   s_axi_bid,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    output reg [1:0]   s_axi_bresp,

    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    input  wire [31:0]  s_axi_araddr,

    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,

    output reg [31:0]  led,
    input  wire [31:0]  sw
);

    localparam idle         = 0,
               predict_op   = 1,
               accept_wr    = 2,
               wait_wdata   = 3,
               accept_wdata = 4,
               gen_data     = 5,
               update_reg   = 6,
               send_ack     = 7,
               accept_rd    = 8,
               fetch_rdata  = 9,
               send_rdata   = 10;

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

    reg [3:0]  state = 0;
    reg [31:0] waddr = 0, wdata = 0, data_write = 0, raddr = 0,
               sw_reg = 0, rdata = 0, sw_reg_deb = 0;
    reg [3:0]  wstrb = 0;
    reg [1:0]  count = 0;

    parameter offset_led = 6'h004;
    parameter offset_sw  = 6'h008;

    integer dcount = 0;

    //-----------------------------------------------------------------
    // Debounce logic for switches
    //-----------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 0) begin
            sw_reg     <= 32'h0;
            sw_reg_deb <= 32'h0;
            dcount     <= 0;
        end
        else if (dcount == 0) begin
            sw_reg_deb <= sw;
            dcount     <= dcount + 1;
        end
        else if (dcount == 5) begin
            if (sw_reg_deb == sw) begin
                sw_reg <= sw_reg_deb;
                dcount <= 0;
            end
            else begin
                dcount <= 0;
            end
        end
        else begin
            dcount <= dcount + 1;
        end
    end

    //-----------------------------------------------------------------
    // Main FSM: handles AXI-Lite write and read transactions
    //-----------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 0) begin
            state <= idle;
            led  <= 0;
            waddr<= 0;
            wdata<= 0;
            wstrb<= 0;
            rdata<=0;
            raddr<=0;
        end
        else begin
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
                    state         <= predict_op;
                end

                predict_op: begin
                    if (s_axi_awvalid && s_axi_awaddr == 4)
                        state <= accept_wr;
                    else if (s_axi_arvalid && (s_axi_araddr == 8 | s_axi_araddr == 4))
                        state <= accept_rd;
                    else
                        state <= idle;
                end

                accept_wr: begin
                    waddr         <= s_axi_awaddr;
                    s_axi_awready <= 1'b1;
                    state         <= wait_wdata;
                end

                wait_wdata: begin
                    s_axi_awready <= 1'b0;
                    if (s_axi_wvalid) begin
                        state <= accept_wdata;
                        wdata <= s_axi_wdata;
                        wstrb <= s_axi_wstrb;
                    end
                    else begin
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
                    state        <= update_reg;
                end

                update_reg: begin
                    led <= data_write;
                    if (count < 2) begin
                        count <= count + 1;
                        state <= update_reg;
                    end
                    else begin
                        count <= 0;
                        state <= send_ack;
                    end
                end

                send_ack: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp  <= 2'b00;
                        state        <= idle;
                    end
                    else begin
                        state <= send_ack;
                    end
                end

                accept_rd: begin
                    raddr         <= s_axi_araddr;
                    state         <= fetch_rdata;
                    s_axi_arready <= 1'b1;
                end

                fetch_rdata: begin
                    s_axi_arready <= 1'b0;

                    if (count < 2) begin
                        count <= count + 1;
                        state <= fetch_rdata;
                        rdata <= (raddr == 4) ? led :
                                 ((raddr == 8) ? sw_reg : 32'h0);
                    end
                    else begin
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
                    end
                    else begin
                        state <= send_rdata;
                    end
                end

                default: state <= idle;

            endcase
        end
    end

endmodule