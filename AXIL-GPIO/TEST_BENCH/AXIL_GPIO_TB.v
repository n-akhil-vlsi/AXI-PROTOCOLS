module tb_axi_gpio_slave;

    reg s_axi_aclk;
    reg s_axi_aresetn;

    // Write Address Channel
    reg         s_axi_awvalid;
    wire        s_axi_awready;
    reg [31:0]  s_axi_awaddr;

    // Write Data Channel
    reg         s_axi_wvalid;
    wire        s_axi_wready;
    reg [31:0]  s_axi_wdata;
    reg [3:0]   s_axi_wstrb;

    // Write Response Channel
    wire        s_axi_bvalid;
    reg         s_axi_bready;
    wire [1:0]  s_axi_bresp;

    // Read Address Channel
    reg [31:0]  s_axi_araddr;
    reg         s_axi_arvalid;
    wire        s_axi_arready;

    // Read Data Channel
    wire [31:0] s_axi_rdata;
    wire [1:0]  s_axi_rresp;
    wire        s_axi_rvalid;
    reg         s_axi_rready;

    // Output LEDs
    wire [31:0] led;
    reg  [31:0] sw = 15;

    // Instantiate the DUT (Device Under Test)
    axilite_s uut (
        .s_axi_aclk    (s_axi_aclk),
        .s_axi_aresetn (s_axi_aresetn),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (s_axi_awready),
        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (s_axi_wready),
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bready  (s_axi_bready),
        .s_axi_bresp   (s_axi_bresp),
        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (s_axi_arready),
        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rready  (s_axi_rready),
        .led           (led),
        .sw            (sw)
    );

    // Clock generation
    always #5 s_axi_aclk = ~s_axi_aclk;

    initial begin
        // Initialize signals
        s_axi_aclk    = 0;
        s_axi_aresetn = 0;
        s_axi_awvalid = 0;
        s_axi_awaddr  = 32'h0;
        s_axi_wvalid  = 0;
        s_axi_wdata   = 32'h0;
        s_axi_wstrb   = 4'b0000;
        s_axi_bready  = 0;
        s_axi_araddr  = 32'h0;
        s_axi_arvalid = 0;
        s_axi_rready  = 0;

        // Apply reset
        #10;
        s_axi_aresetn = 1;

        // Write operation
        s_axi_awaddr  = 32'h00000004;
        s_axi_awvalid = 1;
        s_axi_wdata   = 32'h0000ABCD;
        s_axi_wvalid  = 1;
        s_axi_wstrb   = 4'b1111;
        s_axi_bready  = 1;
        @(posedge s_axi_aclk);
        s_axi_awvalid = 1;
        @(posedge s_axi_awready);
        @(posedge s_axi_aclk);
        s_axi_awvalid = 0;
        s_axi_awaddr  = 0;
        @(posedge s_axi_wready);
        @(posedge s_axi_aclk);
        s_axi_wvalid  = 0;
        s_axi_wdata   = 32'h0;
        s_axi_wstrb   = 4'b0;
        @(posedge s_axi_bvalid);
        @(posedge s_axi_aclk);
        s_axi_bready  = 0;
        @(posedge s_axi_aclk);

        @(posedge s_axi_aclk)
        // Read operation
        s_axi_araddr  = 32'h00000004;
        s_axi_arvalid = 1;
        @(posedge s_axi_arready);
        @(posedge s_axi_aclk);
        s_axi_arvalid = 0;
        s_axi_rready  = 1;
        @(posedge s_axi_rvalid);
        @(posedge s_axi_aclk);
        s_axi_rready  = 0;
        @(posedge s_axi_aclk);
        @(posedge s_axi_aclk);

        s_axi_araddr  = 32'h00000008;
        s_axi_arvalid = 1;
        @(posedge s_axi_arready);
        @(posedge s_axi_aclk);
        s_axi_arvalid = 0;
        s_axi_rready  = 1;
        @(posedge s_axi_rvalid);
        @(posedge s_axi_aclk);
        s_axi_rready  = 0;
        @(posedge s_axi_aclk);
        @(posedge s_axi_aclk);

        $finish;
    end

endmodule