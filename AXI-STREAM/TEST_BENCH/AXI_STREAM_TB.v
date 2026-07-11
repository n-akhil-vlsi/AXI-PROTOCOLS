module axis_s_tb;

    // Signals
    reg s_axis_aclk;
    reg s_axis_aresetn;
    reg s_axis_tvalid;
    reg [7:0] s_axis_tdata;
    reg s_axis_tlast;
    wire s_axis_tready;
    wire [7:0] dout;

    integer i;

    // Instantiate the DUT
    axis_s uut (
        .s_axis_aclk(s_axis_aclk),
        .s_axis_aresetn(s_axis_aresetn),
        .s_axis_tready(s_axis_tready),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tlast(s_axis_tlast),
        .dout(dout)
    );

    // Clock generation
    initial begin
        s_axis_aclk = 1'b0;
        forever #10 s_axis_aclk = ~s_axis_aclk;
    end

    // Stimulus generation
    initial begin
        // Initialize inputs
        s_axis_tvalid   = 1'b0;
        s_axis_tdata    = 8'h00;
        s_axis_tlast    = 1'b0;
        s_axis_aresetn  = 1'b0;

        // Apply reset
        repeat (5) @(posedge s_axis_aclk);
        s_axis_aresetn = 1'b1;

        // Send 10 bytes
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge s_axis_aclk);
            s_axis_tvalid = 1'b1;
            s_axis_tdata  = $random;
        end

        // Assert TLAST on last transfer
        @(posedge s_axis_aclk);
        s_axis_tlast = 1'b1;

        @(posedge s_axis_aclk);
        s_axis_tlast  = 1'b0;
        s_axis_tvalid = 1'b0;

        #20;
        $finish;
    end

endmodule