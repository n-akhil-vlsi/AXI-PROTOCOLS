module top_tb();

    reg         clk;
    reg         rst;
    reg         newd;
    reg  [7:0]  din;
    wire [7:0]  dout;
    wire        last;

    integer     i;   // plain Verilog needs 'integer', not SystemVerilog 'int'

    axis dut (
        .clk  (clk),
        .rst  (rst),
        .newd (newd),
        .din  (din),
        .dout (dout),
        .last (last)
    );

    // Clock generation with pulse width of 10 time units (20 time units period).
    initial clk = 1'b0;
    always #10 clk = ~clk;

    initial begin
        // Initialize inputs
        rst  = 1'b0;
        newd = 1'b0;
        din  = 8'h00;

        repeat (10) @(posedge clk);
        rst = 1'b1;

        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            newd = 1'b1;
            din  = $random % 16;   // plain-Verilog-compatible random, 0-15 range

            @(posedge clk);
            newd = 1'b0;            // deassert after one cycle - proper single-cycle pulse

            @(negedge last);
        end

        $finish;
    end

endmodule