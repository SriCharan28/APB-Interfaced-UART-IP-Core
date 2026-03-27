
module transmitter
(
pclk,presetn,pwdata,tx_fifo_push,enable,lcr,
tx_fifo_count,busy,tx_fifo_full,tx_fifo_empty,txd
);

input wire pclk;
input wire presetn;
input wire [7:0] pwdata;
input wire tx_fifo_push;
input wire enable;
input wire [7:0] lcr;

output wire [4:0] tx_fifo_count;
output reg busy;
output wire tx_fifo_full,tx_fifo_empty;
output wire txd;


wire [7:0] tx_fifo_out;
reg [7:0] tx_buffer;
reg [3:0] tx_state;
reg [3:0] bit_counter;
reg pop_tx_fifo;
reg txd_temp;


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
fifo tx(
		pclk,presetn,pwdata,tx_fifo_push,pop_tx_fifo,
		tx_fifo_out,tx_fifo_full,tx_fifo_empty,tx_fifo_count
		);


// buffer
always @(posedge pclk) 
begin
  if(presetn==1'b0) 
  begin
    pop_tx_fifo <= 1'b0;
    tx_buffer   <= 8'd0;
  end 
  else 
  begin
    // Default
    pop_tx_fifo <= 1'b0;
    if (tx_state == idle && tx_fifo_empty==1'b0 && enable==1'b1) 
	 begin
      // Only assert pop
      pop_tx_fifo <= 1'b1;
    end
    // Capture from FIFO *one cycle later* when state machine has moved
    if (tx_state == start) 
	 begin
      tx_buffer <= tx_fifo_out;
    end
  end
end
/*
//buffer
always @(posedge pclk) 
begin
	if(presetn==1'b0) 
	begin
     pop_tx_fifo <= 1'b0;
     tx_buffer   <= 8'd0;
   end 
	else 
	begin
		if (tx_state == idle && tx_fifo_empty!=1'b1 && enable==1'b1) 
		begin
			pop_tx_fifo <= 1'b1;
         tx_buffer   <= tx_fifo_out;
      end 
		else 
		begin
			pop_tx_fifo <= 1'b0;
      end
	end
end
*/
	
	
//bit_counter
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		bit_counter<=4'd0;
	end
	else
	begin
		if(tx_state==idle)
		begin 
			bit_counter<=4'd0;
		end
		else
		begin
			if(enable==1'd1)
			begin
				bit_counter<=bit_counter+4'd1;
			end
		end
	end
end


//state_transition
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		tx_state<=idle;
	end
	else
	begin
		case(tx_state)
			idle:
				  begin
						if(tx_fifo_empty==1'd0 && enable==1'd1)
						begin
							tx_state<=start;
						end
						else
						begin
							tx_state<=idle;
						end
				  end
			start:
					if(bit_counter==4'd15 && enable==1'd1)
					begin
						tx_state<=bit0;
					end
					else
					begin
						tx_state<=start;
					end
			bit0:
				  if(bit_counter==4'd15 && enable==1'd1)
				  begin
						tx_state<=bit1;
				  end
				  else
				  begin
						tx_state<=bit0;
				  end
			bit1:				  
				  if(bit_counter==4'd15 && enable==1'd1)
				  begin
						tx_state<=bit2;
				  end
				  else
				  begin
						tx_state<=bit1;
				  end
			bit2:				  
			     if(bit_counter==4'd15 && enable==1'd1)
				  begin
						tx_state<=bit3;
				  end
				  else
				  begin
						tx_state<=bit2;
				  end
			bit3:				  
			     if(bit_counter==4'd15 && enable==1'd1)
				  begin
						tx_state<=bit4;
				  end
				  else
				  begin
						tx_state<=bit3;
				  end
			bit4:				  
			     if(bit_counter==4'd15 && enable==1'd1)
				  begin
						if(lcr[1:0]==2'd0)
						begin
							case(lcr[3])
								1'b0:tx_state<=stop1;
								1'b1:tx_state<=parity;
								default:tx_state<=bit4;
							endcase
						end
						else
						begin
							tx_state<=bit5;
						end
				  end
				  else
				  begin
						tx_state<=bit4;
				  end
			bit5:				  
				  if(bit_counter==4'd15 && enable==1'd1)
				  begin
						if(lcr[1:0]<2'b01)
						begin
							case(lcr[3])
								1'b0:tx_state<=stop1;
								1'b1:tx_state<=parity;
								default:tx_state<=bit5;
							endcase
						end
						else
						begin
							if(lcr[1:0]>2'b01)
							begin
								tx_state<=bit6;
							end
							else
							begin
								tx_state<=bit5;
							end
						end
				  end
				  else
				  begin
						tx_state<=bit5;
				  end
			bit6:				  
				  if(bit_counter==4'd15 && enable==1'd1)
				  begin						
						if(lcr[1:0]==2'b11)
						begin
							tx_state<=bit7;
						end
						else if(lcr[3]==1'b1)
						begin
							tx_state<=parity;
						end
						else if(lcr[1:0]!=2'b11 && lcr[3]==1'b0)
						begin
								tx_state<=stop1;
						end
						else
						begin
							tx_state<=bit6;
						end
				  end
				  else
				  begin
						tx_state<=bit6;
				  end
			bit7:				 
				  if(bit_counter==4'd15 && enable==1'd1)
				  begin
						case(lcr[3])
							1'b0:tx_state<=stop1;
							1'b1:tx_state<=parity;
							default:tx_state<=bit7;
						endcase
				  end
				  else
				  begin
						tx_state<=bit7;
				  end
			parity:				  
					if(bit_counter==4'd15 && enable==1'd1)
				   begin
						tx_state<=stop1;
				   end
				   else
				   begin
						tx_state<=parity;
				   end
			stop1:
				  begin
						if(bit_counter==4'd15 && enable==1'd1)
						begin
							case(lcr[2])
								1'b0:tx_state<=idle;
								1'b1:tx_state<=stop2;
								default:tx_state<=stop1;
							endcase
						end
						else
						begin
							tx_state<=stop1;
						end
					end
			stop2:	
				  begin
						if(tx_fifo_empty==1'b0 && enable==1'b1)
						begin
							tx_state<=idle;
						end
						else
						begin
							tx_state<=stop2;
						end
					end
			default:tx_state<=idle;
		endcase
	end
end


//output_updation
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		busy<=1'b0;
		txd_temp<=1'b1;
	end
	else
	begin
		case(tx_state)
		idle:
			begin
				busy<=1'b0;
				txd_temp<=1'b1;
			end
		start:
			begin
				busy<=1'b1;
				txd_temp<=1'b0;
			end
		bit0:
			begin
				busy<=1'b1;
				txd_temp<=tx_buffer[0];
			end
		bit1:
			begin
				busy<=1'b1;
				txd_temp<=tx_buffer[1];
			end
		bit2:
			begin
				busy<=1'b1;
				txd_temp<=tx_buffer[2];
			end
		bit3:
			begin
				busy<=1'b1;
				txd_temp<=tx_buffer[3];
			end
		bit4:
			begin
				busy<=1'b1;
				txd_temp<=tx_buffer[4];
			end
		bit5:
			begin
				busy<=1'b1;
				txd_temp<=tx_buffer[5];
			end
		bit6:
			begin
				busy<=1'b1;
				txd_temp<=tx_buffer[6];
			end
		bit7:
			begin
				busy<=1'b1;
				txd_temp<=tx_buffer[7];
			end
		parity:
			begin
				busy<=1'b1;
				//txd_temp<=(lcr[3]==1'b1)?((lcr[4]==1'b1)?(~^tx_buffer):(^tx_buffer)):1'b1;
				case(lcr[3])
				1'b0:txd_temp<=1'b1;
				1'b1:
					begin
						case(lcr[5])
						1'b0:
							begin
								case(lcr[4])
								1'b0:txd_temp<=(~(^tx_buffer));
								1'b1:txd_temp<=(^tx_buffer);
								default:txd_temp<=1'b1;
								endcase
							end
						1'b1:txd_temp<=~lcr[4];
						default:txd_temp<=1'b1;
						endcase
					end
				default:txd_temp<=1'b1;
				endcase
				
			end
		stop1:
			begin
				busy<=1'b1;
				txd_temp<=1'b1;
			end
		stop2:
			begin
				busy<=1'b1;
				txd_temp<=1'b1;
			end
		default:			
			begin
				busy<=1'b0;
				txd_temp<=1'b1;
			end
		endcase
	end
end


assign txd = (lcr[6]==1'b1) ? 1'b0 : txd_temp;


endmodule