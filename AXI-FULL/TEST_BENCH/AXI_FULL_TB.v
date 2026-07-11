module axif_tb;

    // Declare testbench signals
    reg         clk;
    reg         resetn;
    reg         wr;
    reg  [31:0] wr_addr;
    reg  [7:0]  wr_burst_len;
    reg  [1:0]  wr_burst_type;
    reg  [31:0] wr_din;
    reg  [3:0]  wr_strbin;
    reg  [31:0] rd_addr;
    reg  [7:0]  rd_burst_len;
    reg  [1:0]  rd_burst_type;
    wire [31:0] rout;
    wire [1:0]  resp;
    wire [159:0] pc_status;
    wire pc_asserted;

    // Instantiate the DUT (Device Under Test)
    top dut (
        .clk(clk),
        .resetn(resetn),
        .wr(wr),
        .wr_addr(wr_addr),
        .wr_burst_len(wr_burst_len),
        .wr_burst_type(wr_burst_type),
        .wr_din(wr_din),
        .wr_strbin(wr_strbin),
        .rd_addr(rd_addr),
        .rd_burst_len(rd_burst_len),
        .rd_burst_type(rd_burst_type),
        .rout(rout),
        .resp(resp),
        .pc_status(pc_status),
        .pc_asserted(pc_asserted)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Test sequence
    initial begin
        // Initial reset
        resetn = 0;
        #20 resetn = 1;

        @(posedge clk);
        wr = 1;
        
        wr_addr = 24'h000001;
        wr_burst_len = 8'h4;
        wr_burst_type = 2'b01;
        wr_din = 32'h5;
        wr_strbin = 4'b1111;
        
        rd_addr = 0;
        rd_burst_len  = 0;
        rd_burst_type = 0;
        
        @(posedge dut.uut.m_axi_bvalid);
        @(posedge clk);
        wr = 0;
        rd_addr = 1;
        rd_burst_len  = 4;
        rd_burst_type = 0;
        @(posedge dut.uut.m_axi_rlast);
        @(posedge clk);
        $stop;
    end


endmodule