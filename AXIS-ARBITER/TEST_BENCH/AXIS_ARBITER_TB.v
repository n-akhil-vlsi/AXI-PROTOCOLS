`timescale 1ns / 1ps
 
module axis_arb_tb;
 
    reg  aclk = 0;
    reg  aresetn;
 
    wire s_axis_tready1;
    wire s_axis_tready2;
    reg  s_axis_tvalid1;
    reg  s_axis_tvalid2;
    reg  [7:0] s_axis_tdata1;
    reg  [7:0] s_axis_tdata2;
    reg  s_axis_tlast1;
    reg  s_axis_tlast2;
 
    reg  m_axis_tready;
    wire m_axis_tvalid;
    wire [7:0] m_axis_tdata;
    wire m_axis_tlast;
 
    integer i;
 
    // DUT instantiation
    axis_arb dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tready1(s_axis_tready1),
        .s_axis_tready2(s_axis_tready2),
        .s_axis_tvalid1(s_axis_tvalid1),
        .s_axis_tvalid2(s_axis_tvalid2),
        .s_axis_tdata1(s_axis_tdata1),
        .s_axis_tdata2(s_axis_tdata2),
        .s_axis_tlast1(s_axis_tlast1),
        .s_axis_tlast2(s_axis_tlast2),
        .m_axis_tready(m_axis_tready),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tlast(m_axis_tlast)
    );
 
    // Clock generation
    always #10 aclk = ~aclk;
 
    initial begin
        // Initialization
        aresetn        = 0;
        s_axis_tvalid1 = 0;
        s_axis_tvalid2 = 0;
        s_axis_tlast1  = 0;
        s_axis_tlast2  = 0;
        s_axis_tdata1  = 0;
        s_axis_tdata2  = 0;
        m_axis_tready  = 1;
 
        // Reset
        repeat (10) @(posedge aclk);
        aresetn = 1;
 
        // Scenario 1: Master 1 transfer only (stream 2 idle)

        for (i = 0; i < 5; i = i + 1) begin
            @(posedge aclk);
            s_axis_tvalid1 = 1;
            s_axis_tvalid2 = 0;
            s_axis_tlast1  = 0;
            s_axis_tlast2  = 0;
            s_axis_tdata1  = $random;
            s_axis_tdata2  = $random;
        end
        @(posedge aclk);
        s_axis_tdata1 = $random;
        s_axis_tlast1 = 1;
        @(posedge aclk);
        s_axis_tlast1  = 0;
        s_axis_tvalid1 = 0;
 
        // Scenario 2: Master 2 transfer only (stream 1 idle)
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge aclk);
            s_axis_tvalid1 = 0;
            s_axis_tvalid2 = 1;
            s_axis_tlast2  = 0;
            s_axis_tdata1  = $random;
            s_axis_tdata2  = $random;
        end
        @(posedge aclk);
        s_axis_tdata2 = $random;
        s_axis_tlast2 = 1;
        @(posedge aclk);
        s_axis_tlast2  = 0;
        s_axis_tvalid2 = 0;
 
        // before both requests arrive together.
        repeat (5) @(posedge aclk);

        // Scenario 3: Simultaneous valid - priority check
        // Both s_axis_tvalid1 and s_axis_tvalid2 asserted on the same clock edge.
        // should grant stream 1 and stream 2 should keep waiting.
        
        @(posedge aclk);
        s_axis_tvalid1 = 1;
        s_axis_tvalid2 = 1;          // both go high on the same edge
        s_axis_tlast1  = 0;
        s_axis_tlast2  = 0;
        s_axis_tdata1  = 8'hAA;      
        s_axis_tdata2  = 8'h55;     
 
        // Hold stream 2's request pending for a few cycles while
        // stream 1 is being serviced, to prove stream 2 truly waits
        for (i = 0; i < 3; i = i + 1) begin
            @(posedge aclk);
            s_axis_tdata1 = $random;
        end
 
        @(posedge aclk);
        s_axis_tdata1 = 8'hBB;
        s_axis_tlast1 = 1;           // end stream 1's burst
        @(posedge aclk);
        s_axis_tlast1  = 0;
        s_axis_tvalid1 = 0;          // stream 1 done, stream 2 should now be granted
 
        // Let stream 2 (still valid, still pending) run for a few beats
        for (i = 0; i < 3; i = i + 1) begin
            @(posedge aclk);
            s_axis_tdata2 = $random;
        end
 
        @(posedge aclk);
        s_axis_tdata2 = 8'hCC;
        s_axis_tlast2 = 1;
        @(posedge aclk);
        s_axis_tlast2  = 0;
        s_axis_tvalid2 = 0;
 
        repeat (5) @(posedge aclk);
 
        $stop;
    end
 
endmodule