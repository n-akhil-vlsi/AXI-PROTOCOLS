`timescale 1ns / 1ps

module axif_tb;

    reg clk = 0;
    reg resetn = 0;

    reg op_start = 0;
    wire busy;

    reg wr = 0;

    reg [31:0] wr_addr = 0;
    reg [7:0]  wr_burst_len = 0;
    reg [1:0]  wr_burst_type = 0;
    reg [31:0] wr_din = 0;
    reg [3:0]  wr_strbin = 0;

    reg [31:0] rd_addr = 0;
    reg [7:0]  rd_burst_len = 0;
    reg [1:0]  rd_burst_type = 0;

    wire [31:0] rout;
    wire [1:0]  resp;

    integer k;

    //---------------- DUT ----------------//

    top DUT(
        .clk(clk),
        .resetn(resetn),
        .op_start(op_start),
        .busy(busy),

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
        .resp(resp)
    );

    //---------------- CLOCK ----------------//

    always #5 clk = ~clk;

    //---------------- READ MONITOR ----------------//

    always @(posedge clk)
    begin
        if(DUT.uut.m_axi_rvalid && DUT.uut.m_axi_rready)
        begin
            $display("[%0t] READ DATA = %h  RLAST = %b",$time,DUT.uut.m_axi_rdata,DUT.uut.m_axi_rlast);
        end
    end

    //---------------- WRITE MONITOR ----------------//

    always @(posedge clk)
    begin
        if(DUT.uut.m_axi_wvalid && DUT.uut.m_axi_wready)
        begin
            $display("[%0t] WRITE DATA = %h  WLAST = %b",$time,DUT.uut.m_axi_wdata,DUT.uut.m_axi_wlast);
        end
    end

    //---------------- TEST ----------------//

    initial begin
            //---------------- RESET ----------------//

    resetn = 0;
    wr = 0;
    op_start = 0;

    wr_addr = 0;
    wr_burst_len = 0;
    wr_burst_type = 0;
    wr_din = 0;
    wr_strbin = 0;

    rd_addr = 0;
    rd_burst_len = 0;
    rd_burst_type = 0;

    repeat(5) @(posedge clk);

    resetn = 1;

    repeat(2) @(posedge clk);

   //---------------- WRAP WRITE ----------------//
    
    wr             = 1;
    wr_addr        = 32'd24;      // Wrap boundary
    wr_burst_len   = 8'd3;        // 4 beats
    wr_burst_type  = 2'b10;       // WRAP
    wr_din         = 32'hAABBCCDD;
    wr_strbin      = 4'b1111;
    
    @(posedge clk);
    op_start = 1;
    
    @(posedge clk);
    op_start = 0;
    
    while(busy != 1)
        @(posedge clk);
    
    while(busy != 0)
        @(posedge clk);
    
    repeat(5)
        @(posedge clk);
    
    $display("\nWRAP WRITE COMPLETED");
    
    for(k=16;k<32;k=k+1)
        $display("mem[%0d] = %h",k,DUT.dut.mem[k]);

    repeat(5)
        @(posedge clk);
   //---------------- WRAP READ ----------------//
        
        wr = 0;
        
        rd_addr        = 32'd24;
        rd_burst_len   = 8'd3;
        rd_burst_type  = 2'b10;       // WRAP
        
        @(posedge clk);
        op_start = 1;
        
        @(posedge clk);
        op_start = 0;
        
        while(busy != 1)
            @(posedge clk);
        
        while(busy != 0)
            @(posedge clk);
        
        repeat(5)
            @(posedge clk);
        
        $display("\nWRAP READ COMPLETED");
        
        $display("ROUT = %h",rout);
        $display("RESP = %b",resp);
        
        $display("\nMemory Contents:");
        
        for(k=16;k<32;k=k+1)
            $display("mem[%0d] = %h",k,DUT.dut.mem[k]);
        
        $finish;

        repeat(10)
            @(posedge clk);

        $finish;

    end

endmodule