module axis_s(
    input  wire       s_axis_aclk,
    input  wire       s_axis_aresetn,
    output wire       s_axis_tready,
    input  wire       s_axis_tvalid,
    input  wire [7:0] s_axis_tdata,
    input  wire       s_axis_tlast,
    output wire [7:0] dout
);

    // State encoding for fsm,everything happens in the STORE state.
    parameter IDLE  = 2'b00;
    parameter STORE = 2'b01;

    reg [1:0] state, next_state;

    // State register
    always @(posedge s_axis_aclk) begin
        if (!s_axis_aresetn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next-state logic is combinational,so it uses blocking  assignments.
    always @(*) begin
        case (state)

            IDLE: begin
                if (s_axis_tvalid)
                    next_state = STORE;
                else
                    next_state = IDLE;
            end

            STORE: begin
                if (s_axis_tvalid) begin
                    if (s_axis_tlast)
                        next_state = IDLE;
                    else
                        next_state = STORE;
                end
                else
                    next_state = IDLE;
            end

            default: next_state = IDLE;

        endcase
    end

    // Output logic is checked for every clock cycle, and we need to store the data when the state is STORE.
    assign s_axis_tready = (state == STORE);

    assign dout = (state == STORE) ? s_axis_tdata : 8'h00;

endmodule
  