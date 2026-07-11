`timescale 1ns / 1ps

module axis_fifo_tb;


 // Inputs
 reg aclk;
 reg aresetn;
 reg s_axis_tvalid;
 reg [7:0] s_axis_tdata;
 reg s_axis_tkeep;
 reg s_axis_tlast;

 // Outputs
 wire m_axis_tvalid;
 wire [7:0] m_axis_tdata;
 wire m_axis_tkeep;
 wire m_axis_tlast;
 reg m_axis_tready;

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

 // Initial stimulus
 initial begin
 // Initialize inputs
 aclk = 0;
 aresetn = 0;
 s_axis_tvalid = 0;
 s_axis_tdata = 8'h00;
 s_axis_tkeep = 1'b0;
 s_axis_tlast = 0;
 
 repeat(5) @(posedge aclk);
 aresetn = 1;
 for(integer i = 0; i < 20 ; i=i+1)
 begin
 @(posedge aclk);
 m_axis_tready = 0;
 s_axis_tvalid = 1;
 s_axis_tdata = $random();
 s_axis_tkeep = 1'b1;
 s_axis_tlast = 0;
 end
 
 for(integer i = 0; i < 20 ; i=i+1)
 begin
 @(posedge aclk);
 s_axis_tvalid = 0;
 m_axis_tready = 1;
 s_axis_tdata = 0;
 s_axis_tkeep = 0;
 s_axis_tlast = 0;
 end
 
 
 #10 $finish;
 end

endmodule
