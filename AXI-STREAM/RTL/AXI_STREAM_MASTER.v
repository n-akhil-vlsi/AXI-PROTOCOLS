module axis_m(
    input  wire        m_axis_aclk,
    input  wire        m_axis_aresetn,
    input  wire        newd,
    input  wire [7:0]  din,
    input  wire        m_axis_tready,
    output wire        m_axis_tvalid,
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tlast
);

localparam IDLE = 1'b0;
localparam TX   = 1'b1;

reg state, next_state;
reg [2:0] count;

// State register
always @(posedge m_axis_aclk) begin
    if (!m_axis_aresetn)
        state <= IDLE;
    else
        state <= next_state;
end

// Counter
always @(posedge m_axis_aclk) begin
    if (!m_axis_aresetn)
        count <= 3'd0;
    else if (state == IDLE)
        count <= 3'd0;
    else if (state == TX && m_axis_tready)
        if (count != 3)
            count <= count + 1'b1;
end

// Next-state logic
always @(*) begin
    case (state)
        IDLE: begin
            if (newd)
                next_state = TX;
            else
                next_state = IDLE;
        end

        TX: begin
            if (m_axis_tready && count == 3)
                next_state = IDLE;
            else
                next_state = TX;
        end

        default: next_state = IDLE;
    endcase
end

// Outputs
assign m_axis_tvalid = (state == TX);
assign m_axis_tdata  = (state == TX) ? (din * count) : 8'd0;
assign m_axis_tlast  = (state == TX) && (count == 3) && m_axis_tready;

endmodule
