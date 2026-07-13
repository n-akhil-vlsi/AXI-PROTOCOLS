`timescale 1ns / 1ps
module axis_fifo_tb;
 
    // Inputs
    reg aclk;
    reg aresetn;
    reg s_axis_tvalid;
    reg [7:0] s_axis_tdata;
    reg s_axis_tkeep;
    reg s_axis_tlast;
    reg m_axis_tready;
 
    // Outputs
    wire m_axis_tvalid;
    wire [7:0] m_axis_tdata;
    wire m_axis_tkeep;
    wire m_axis_tlast;
 
    integer i;
 
    // Instantiate the DUT
    axis_fifo dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready)
    );
 
    // Clock generation
    always #10 aclk = ~aclk;
 
    initial begin
        // Initialize inputs
        aclk          = 0;
        aresetn       = 0;
        s_axis_tvalid = 0;
        s_axis_tdata  = 8'h00;
        s_axis_tkeep  = 1'b0;
        s_axis_tlast  = 0;
        m_axis_tready = 0;
 
        repeat (5) @(posedge aclk);
        aresetn = 1;
 
        // Write 20 bytes (FIFO depth is only 16) - this fills
        // it completely and also tests that writes #17-20 while
        // full are correctly dropped.

        for (i = 0; i < 20; i = i + 1) begin
            @(posedge aclk);
            m_axis_tready = 0;
            s_axis_tvalid = 1;
            s_axis_tdata  = i;              
            s_axis_tkeep  = 1'b1;
            s_axis_tlast  = (i == 15);
        end
 
        @(posedge aclk);
        s_axis_tvalid = 0;
 
        // Read 20 times (only 16 bytes were actually stored) -
        // this drains the FIFO fully and also tests that reads
        // #17-20 while empty correctly show m_axis_tvalid=0.
        // Expect data 0,1,2...15 in order, tlast high on the
        // 16th read.
    
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge aclk);
            s_axis_tvalid = 0;
            m_axis_tready = 1;
        end
 
        @(posedge aclk);
        m_axis_tready = 0;
 

      // when s_axis_tvalid and m_axis_tready are both high on the same cycle, 
      //only the write happens — the read is skipped that cycle.This is because of the else if chaining in the RTL

        for (i = 0; i < 5; i = i + 1) begin
            @(posedge aclk);
            s_axis_tvalid = 1;
            s_axis_tdata  = 8'hA0 + i;
            s_axis_tkeep  = 1'b1;
            s_axis_tlast  = (i == 4);
            m_axis_tready = 1;              // both asserted same cycle
        end
 
        @(posedge aclk);
        s_axis_tvalid = 0;
        m_axis_tready = 0;
 
        // Drain whatever is left over
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge aclk);
            m_axis_tready = 1;
        end
 
        #10 $finish;
    end
 
endmodule