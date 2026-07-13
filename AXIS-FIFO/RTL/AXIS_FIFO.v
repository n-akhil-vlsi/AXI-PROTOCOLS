module axis_fifo(input s_axis_tlast,
                 input [7:0]s_axis_tdata,
                 input s_axis_tkeep,
                 input s_axis_tvalid,
                 input aclk,
                 input aresetn,
                 input m_axis_tready,
                 output m_axis_tlast,
                 output m_axis_tvalid,
                 output [7:0]m_axis_tdata,
                 output m_axis_tkeep);

  // memories for storing data,last and keep signals.          
    reg [7:0]memd[0:15];
    reg      meml[0:15];
    reg      memk[0:15];
    
    reg [3:0]wptr;
    reg [3:0]rptr;
    reg [3:0]cnt;
    
    wire full;
    wire empty;
    
  // it will be useful while writing the data to the fifo or reading the data from the fifo.
    assign full=(cnt==15)?1'b1:1'b0;
    assign empty=(cnt==0)?1'b1:1'b0;
    
    
    always@(posedge aclk)
      begin
        if(!aresetn)
          begin
            wptr<=0;
            rptr<=0;
            cnt<=0;
            
            for(integer i=0;i<16;i=i+1)
              begin
                memd[i]<=0;
                meml[i]<=0;
                memk[i]<=0;
              end
          end
        else if(!full && s_axis_tvalid)         //if s_axis_tvalid is high that means the master is read to send the data,keep and the last to the fifo. 
          begin
            memd[wptr]<=s_axis_tdata;
            meml[wptr]<=s_axis_tlast;
            memk[wptr]<=s_axis_tkeep;
            cnt<=cnt+1;
            wptr<=wptr+1;
          end
        else if(!empty && m_axis_tready)   //m_axis_tready is high then the slave is ready to accept the data,keep and last from the fifo.
          begin
            rptr<=rptr+1;
            cnt=cnt-1;
          end
      end
  // blocking assingment,will be updated immediately for every change.
  assign m_axis_tvalid=(cnt>0)?1'b1:1'b0;
  assign m_axis_tdata=(m_axis_tvalid)?memd[rptr]:0;
  assign m_axis_tlast=(m_axis_tvalid)?meml[rptr]:0;
  assign m_axis_tkeep=(m_axis_tvalid)?memk[rptr]:0;
        
endmodule