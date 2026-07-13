module axis_arb(
    input aclk,
    input aresetn,
    
    input s_axis_tlast1,
    input [7:0]s_axis_tdata1,
    input s_axis_tvalid1,
    output s_axis_tready1,
    
    input s_axis_tlast2,
    input [7:0]s_axis_tdata2,
    input s_axis_tvalid2,
    output s_axis_tready2,
    
    input m_axis_tready,
    output m_axis_tlast,
    output [7:0]m_axis_tdata,
    output m_axis_tvalid
  
    );
    
    
    //declaring the states for the fsm.
    localparam idle=2'b00;
    localparam s1=2'b01;
    localparam s2=2'b10;
    
    reg [1:0]state=idle;
    reg [1:0]next_state=idle;
    
    reg [7:0]tdata;
    reg tlast;
    
    //assuming the tready1 and the tready2 are always high, so that the arbiter can always accept data from both streams.
    assign s_axis_tready1 = 1'b1;
    assign s_axis_tready2 = 1'b1;
    
    
    //state register,if reset is low then the state will be idle,otherwise it will take the next_state value.
    always@(posedge aclk)
      begin
        if(!aresetn)
          state<=idle;
        else 
          state<=next_state;
      end
      
    always@(*)
      begin
        case(state)
        idle:
          begin
            if(s_axis_tvalid1 && s_axis_tready1 &&m_axis_tready) //master1 data and last will be transferred to the output of the arbiter which is also a master.
              begin
                next_state=s1;
                tdata=s_axis_tdata1;
                tlast=s_axis_tlast1;
              end
            else if(s_axis_tvalid2 && s_axis_tready2 && m_axis_tready) //master2 data and last will be transferred to the output of the arbiter whcih is also a master.
              begin
                next_state=s2;
                tdata=s_axis_tdata2;
                tlast=s_axis_tlast2;
              end
            else
              begin
                next_state=idle;
              end
          end
        s1:
         begin
           if(s_axis_tlast1 && m_axis_tready)                   //for the last byte we send the data and the last and also check for if master 2 is ready.
             begin
               tdata=s_axis_tdata1;
               tlast=s_axis_tlast1;
               
               if(s_axis_tvalid2 && s_axis_tready2 && m_axis_tready)  //This is called back-to-back / gapless burst switching checking instantly without wating the clock.
                 begin
                   next_state=s2;
                   tdata=s_axis_tdata2;
                   tlast=s_axis_tlast2;
                 end
               else
                 begin
                   next_state=idle;
                 end
             end
           else                               //it will stay in the same state till the last beat is received from the master1.
             begin
               next_state=s1;
               tdata=s_axis_tdata1;
               tlast=s_axis_tlast1;
             end
         end
        s2:
         begin
           if(s_axis_tlast2 && m_axis_tready)                       //for the last byte we send the data and the last and also check for if master 1 is ready.
             begin
               tdata=s_axis_tdata2;
               tlast=s_axis_tlast2;
               
               if(s_axis_tvalid1 && s_axis_tready1 && m_axis_tready)   //This is called back-to-back / gapless burst switching checking instantly without wasting the clock cycle.
                 begin
                   next_state=s1;
                   tdata=s_axis_tdata1;
                   tlast=s_axis_tlast1;
                 end
               else
                 begin
                   next_state=idle;
                 end
             end
           else                            //it will stay in the same state till the last beat is received from the master2.
             begin
               next_state=s2;
               tdata=s_axis_tdata2;
               tlast=s_axis_tlast2;
             end
         end
       
        default:
          begin
            next_state=idle;
          end
        endcase
      end

   // blocking assingment,will be updated immediately      
  assign m_axis_tdata=((s_axis_tvalid1 && s_axis_tready1) || (s_axis_tvalid2 && s_axis_tready2))?tdata:0;
  assign m_axis_tlast=((s_axis_tvalid1 && s_axis_tready1) || (s_axis_tvalid2 && s_axis_tready2))?tlast:0;
  assign m_axis_tvalid=((s_axis_tvalid1 && s_axis_tready1) || (s_axis_tvalid2 && s_axis_tready2))?1'b1:0;    
               
endmodule