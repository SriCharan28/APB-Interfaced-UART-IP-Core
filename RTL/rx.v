
module rx
(
pclk,presetn,rxd,pop_rx_fifo,enable,lcr,
rx_idle,rx_fifo_count,rx_fifo_out,push_rx_fifo,rx_fifo_full,rx_overrun,framing_error,parity_error,break_error,time_out,rx_fifo_empty
);
input wire pclk;
input wire presetn;
input wire rxd;
input wire pop_rx_fifo;
input wire enable;
input wire [7:0] lcr;

output reg framing_error,parity_error;
output reg push_rx_fifo;
output wire rx_overrun;
output wire rx_idle;
output wire rx_fifo_full;
output wire break_error,time_out;
output wire [4:0] rx_fifo_count;
output wire [7:0] rx_fifo_out;
output wire rx_fifo_empty;

wire framing_error_temp;
reg parity_error_temp;
reg [3:0] rx_state;
reg [3:0] bit_counter;
reg [7:0] rx_buffer;
reg [7:0] counter_b;
reg [9:0] counter_t;
reg [9:0] toc_value;
wire [7:0] brc_value;

reg [3:0] rx_state_temp;

parameter idle = 4'b0000,
			 start = 4'b0001,
			 bit0 = 4'b0010,
			 bit1 = 4'b0011,
			 bit2 = 4'b0100,
			 bit3 = 4'b0101,
			 bit4 = 4'b0110,
			 bit5 = 4'b0111,
			 bit6 = 4'b1000,
			 bit7 = 4'b1001,
			 parity = 4'b1010,
			 stop1 = 4'b1011,
			 stop2 = 4'b1100;
		
		
//fifo
fifo dut(
		 pclk,presetn,rx_buffer,push_rx_fifo,pop_rx_fifo,
		 rx_fifo_out,rx_fifo_full,rx_fifo_empty,rx_fifo_count
		 );
		 
		 
//rx_idle
assign rx_idle = (rx_state == idle) ? 1'b1 : 1'b0;

//rx_overrun
assign rx_overrun = (push_rx_fifo==1'b1 && rx_fifo_full==1'b1) ? 1'b1 : 1'b0;
		
//brc_value
assign brc_value=toc_value[9:2];

//break_error
assign break_error = (counter_b==8'd0) ? 1'b1 : 1'b0;

//time_out
assign time_out = (counter_t==10'd0) ? 1'b1 : 1'b0;
		
		
//*
//bit_counter
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		bit_counter<=4'd0;
	end
	else if(enable==1'b1)
	begin
		if(rx_state==idle)
		begin 
			bit_counter<=4'd0;
		end
		else if(bit_counter==4'd15 && rxd==1'd0 && rx_state==start)
		//else if(bit_counter==4'd15)
		begin
			bit_counter<=4'd0;
		end
		else if(bit_counter==4'd15 && rx_state==bit0)
		//else if(bit_counter==4'd15)
		begin
			bit_counter<=4'd0;
		end
		else
		begin
			bit_counter<=bit_counter+4'd1;
		end
	end
end
//*/
/*
//bit_counter
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		bit_counter<=4'd0;
		rx_state_temp<=idle;
	end
	else if(enable==1'b1)
	begin
		if(rx_state!=rx_state_temp)
		begin 
			bit_counter<=4'd0;
		end
		else if(rx_state==idle)
		//else if(bit_counter==4'd15)
		begin
			bit_counter<=4'd0;
		end
		else
		begin
			bit_counter<=bit_counter+4'd1;
		end
		rx_state_temp<=rx_state;
	end
end
*/

//counter_b
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		counter_b<=8'd159;
	end
	else
	begin
		case({rxd,(enable&(counter_b!=8'd0))})
			2'd0:counter_b<=counter_b;
			2'd1:counter_b<=counter_b-8'd1;
			2'd2:counter_b<=brc_value;
			2'd3:counter_b<=brc_value;
			default:counter_b<=counter_b;
		endcase
	end
end


//counter_t
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		counter_t<=10'd639;
	end
	else
	begin
		case({(push_rx_fifo|pop_rx_fifo|(|rx_fifo_count)),(enable&(counter_t!=10'd0))})
			2'd0:counter_t<=counter_t;
			2'd1:counter_t<=counter_t-10'd1;
			2'd2:counter_t<=toc_value;
			2'd3:counter_t<=toc_value;
			default:counter_t<=counter_t;
		endcase
	end
end

//push_rx_fifo
always @(posedge pclk) 
begin
    if(presetn==1'b0) 
	 begin
        push_rx_fifo <= 1'b0;
	 end
	 //else if((rx_state == stop1 && bit_counter == 4'd15 && enable==1'b1 && parity_error==1'b0)&&(rx_state==stop2 && framing_error==1'b0))
    else if (rx_state == stop1 && bit_counter == 4'd15 && enable==1'b1 && framing_error_temp==1'b0 && parity_error==1'b0)
	 begin
        push_rx_fifo <= 1'b1;
	 end
    else
	 begin
        push_rx_fifo <= 1'b0;
	 end
end


//loading_data
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		rx_buffer<=8'd0;
	end
	else
	begin
		if(bit_counter==4'd15 && enable==1'b1)
		//if(bit_counter==4'd8 && enable==1'b1)
		case(rx_state)
			bit0:rx_buffer[0]<=rxd;
			bit1:rx_buffer[1]<=rxd;
			bit2:rx_buffer[2]<=rxd;
			bit3:rx_buffer[3]<=rxd;
			bit4:rx_buffer[4]<=rxd;
			bit5:rx_buffer[5]<=rxd;
			bit6:rx_buffer[6]<=rxd;
			bit7:rx_buffer[7]<=rxd;
			//default:rx_buffer<=rx_buffer;
		endcase
	end
end


//toc_value	
always@*
begin
	case(lcr[3:0])
		4'd0:toc_value=10'd447;
		4'd1:toc_value=10'd511;
		4'd2:toc_value=10'd575;
		4'd3:toc_value=10'd639;
		4'd4:toc_value=10'd511;
		4'd5:toc_value=10'd575;
		4'd6:toc_value=10'd639;
		4'd7:toc_value=10'd703;
		4'd8:toc_value=10'd512;
		4'd9:toc_value=10'd575;
		4'd10:toc_value=10'd639;
		4'd11:toc_value=10'd703;
		4'd12:toc_value=10'd575;
		4'd13:toc_value=10'd639;
		4'd14:toc_value=10'd703;
		4'd15:toc_value=10'd767;
		default:toc_value=10'd0;
	endcase
end


//framing_error
always@(posedge pclk)
begin
	if(presetn==1'd0 || rx_state==idle)
	begin
		framing_error<=1'd0;
	end
	else
	begin
		if(rx_state==stop1 && bit_counter==4'd15 && enable==1'b1)
		begin
			framing_error<=~rxd;
		end
		else
		begin
			framing_error<=1'd0;
		end
	end
end
assign framing_error_temp = (rx_state==stop1 && bit_counter==4'd15 && enable==1'b1 && rxd==1'b0);



//parity_error
always@(posedge pclk)
begin
    if(presetn==1'b0 || rx_state==idle)
    begin
        parity_error <= 1'b0;
    end
    else
    begin
        if(rx_state == parity && bit_counter == 4'd15 && enable == 1'b1)
        begin
				if(lcr[5]==1'b1)
				begin
					parity_error_temp<=(rxd==~lcr[4])?1'b0:1'b1;
				end
				else
				begin
					case(lcr[4])
						1'd0: parity_error_temp <= ~^{rx_buffer, rxd}; 
						1'd1: parity_error_temp <= ^{rx_buffer, rxd}; 
						default: parity_error_temp <= 1'b0;
					endcase
				end
        end
        else if(rx_state == stop1)
        begin
            parity_error <= parity_error_temp;
        end
        else
        begin
            parity_error <= 1'b0;
        end
    end
end


//state_transition
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		rx_state<=idle;
	end
	else
	begin
		case(rx_state)
			idle:
				  begin
						if(rxd==1'd0)
						begin
							rx_state<=start;
						end
						else
						begin
							rx_state<=idle;
						end
				  end
			start:
					if(bit_counter==4'd15 && rxd==1'd0)
					begin
						rx_state<=bit0;
						bit_counter<=4'd0;
					end
					else if(rxd==1'd1)
					begin
						rx_state<=idle;
					end
					else
					begin
						rx_state<=start;
					end
			bit0:
				  if(bit_counter==4'd15 && enable==1'd1)
				  begin
						rx_state<=bit1;
				  end
				  else
				  begin
						rx_state<=bit0;
				  end
			bit1:				  
				  if(bit_counter==4'd15 && enable==1'd1)
				  begin
						rx_state<=bit2;
				  end
				  else
				  begin
						rx_state<=bit1;
				  end
			bit2:				  
			     if(bit_counter==4'd15 && enable==1'd1)
				  begin
						rx_state<=bit3;
				  end
				  else
				  begin
						rx_state<=bit2;
				  end
			bit3:				  
			     if(bit_counter==4'd15 && enable==1'd1)
				  begin
						rx_state<=bit4;
				  end
				  else
				  begin
						rx_state<=bit3;
				  end
			bit4:				  
			     if(bit_counter==4'd15 && enable==1'd1)
				  begin
						if(lcr[1:0]==2'd0)
						begin
							case(lcr[3])
								1'b0:rx_state<=stop1;
								1'b1:rx_state<=parity;
								default:rx_state<=bit4;
							endcase
						end
						else
						begin
							rx_state<=bit5;
						end
				  end
				  else
				  begin
						rx_state<=bit4;
				  end
			bit5:				  
				  if(bit_counter==4'd15 && enable==1'd1)
				  begin
						if(lcr[1:0]<2'b01)
						begin
							case(lcr[3])
								1'b0:rx_state<=stop1;
								1'b1:rx_state<=parity;
								default:rx_state<=bit5;
							endcase
						end
						else
						begin
							if(lcr[1:0]>2'b01)
							begin
								rx_state<=bit6;
							end
							else
							begin
								rx_state<=bit5;
							end
						end
				  end
				  else
				  begin
						rx_state<=bit5;
				  end
			bit6:				  
				  if(bit_counter==4'd15 && enable==1'd1)
				  begin						
						if(lcr[1:0]==2'b11)
						begin
							rx_state<=bit7;
						end
						else 
						begin
							case(lcr[3])
								1'd0:rx_state<=stop1;
								1'd1:rx_state<=parity;
								default:rx_state<=bit6;
							endcase
						end
				  end
				  else
				  begin
						rx_state<=bit6;
				  end
			bit7:				 
				  if(bit_counter==4'd15 && enable==1'd1)
				  begin
						case(lcr[3])
							1'b0:rx_state<=stop1;
							1'b1:rx_state<=parity;
							default:rx_state<=bit7;
						endcase
				  end
				  else
				  begin
						rx_state<=bit7;
				  end
			parity:				  
					if(bit_counter==4'd15 && enable==1'd1)
				   begin
						rx_state<=stop1;
				   end
				   else
				   begin
						rx_state<=parity;
				   end
			stop1:
				  begin
						if(bit_counter==4'd15 && enable==1'd1)
						begin
							case(lcr[2])
								1'b0:rx_state<=idle;
								1'b1:rx_state<=stop2;
								default:rx_state<=stop1;
							endcase
						end
						else
						begin
							rx_state<=stop1;
						end
					end
			stop2:rx_state<=idle;
			default:rx_state<=idle;
		endcase
	end
end


endmodule