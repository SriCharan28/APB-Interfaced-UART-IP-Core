
module register
(
pclk,presetn,psel,pwrite,pwdata,penable,paddr,
tx_fifo_count,tx_fifo_empty,tx_fifo_full,tx_busy,
rx_data_out,rx_idle,rx_overrun,
rx_fifo_count,rx_fifo_empty,rx_fifo_full,push_rx_fifo,
parity_error,framing_error,break_error,time_out,
prdata,pready,pslverr,lcr,tx_fifo_we,tx_enable,
rx_enable,rx_fifo_re,loopback,irq,baud_o
);
input wire pclk,presetn,psel,pwrite,penable;
input wire tx_fifo_empty,tx_fifo_full,tx_busy;
input wire rx_idle,rx_overrun,rx_fifo_empty,rx_fifo_full,push_rx_fifo;
input wire parity_error,framing_error,break_error,time_out;
input wire [4:0] tx_fifo_count;
input wire [4:0] rx_fifo_count;
input wire [4:0] paddr;
input wire [7:0] rx_data_out;
input wire [31:0] pwdata;

output reg pready,pslverr,loopback,irq,baud_o;
output reg tx_fifo_we,tx_enable,rx_enable,rx_fifo_re;
output reg [7:0] lcr;
output reg [31:0] prdata;

//reg [7:0] divisor;
reg [15:0] divisor;
reg [7:0] fcr;
reg [7:0] lsr;
reg [7:0] mcr;
reg [7:0] ier;
reg [7:0] iir;
reg[1:0] state;
reg rx_fifo_over_threshold,last_tx_fifo_empty;
reg rx_int,tx_int,ls_int;
reg start_dlc,dlc;
reg enable;
reg re,we;

parameter idle = 2'b00,
			 setup = 2'b01,
			 access = 2'b10;
			 
//lcr
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		lcr<=8'd3;
	end
	else
	begin
		//case(we&&(paddr==5'h3))
		case(we&&(paddr==5'hc))
			1'b0:lcr<=lcr;
			1'b1:lcr<=pwdata[7:0];
			default:lcr<=lcr;
		endcase
	end
end

//fcr
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		fcr<=8'd192;
	end
	else
	begin
		//case(we&&(paddr==5'h2))
		case(we&&(paddr==5'h8))
			1'b0:fcr<=fcr;
			1'b1:fcr<=pwdata[7:0];
			default:fcr<=fcr;
		endcase
	end
end

//mcr
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		mcr<=8'd0;
	end
	else
	begin
		case(we&&(paddr==5'h4))
			1'b0:mcr<=mcr;
			1'b1:mcr<=pwdata[4:0];
			default:mcr<=mcr;
		endcase
	end
end

//ier
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		ier<=8'd0;
	end
	else
	begin
		//case(we&&(paddr==5'h1))
		case(we&&(paddr==5'h4))
			1'b0:ier<=ier;
			1'b1:ier<=pwdata[3:0];
			default:ier<=ier;
		endcase
	end
end

//rx_fifo_re
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		rx_fifo_re<=1'b0;
	end
	else
	begin
		case({rx_fifo_re,(re&&(paddr==5'h0))})
			2'd0:rx_fifo_re<=rx_fifo_re;
			2'd1:rx_fifo_re<=1'b1;
			2'd2:rx_fifo_re<=1'b0;
			2'd3:rx_fifo_re<=1'b0;
			default:rx_fifo_re<=rx_fifo_re;
		endcase
	end
end

//tx_fifo_we
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		tx_fifo_we<=1'b0;
	end
	else
	begin
		case(we&&(paddr==5'h0))
			1'b0:tx_fifo_we<=1'b0;
			1'b1:tx_fifo_we<=1'b1;
			default:tx_fifo_we<=tx_fifo_we;
		endcase
	end
end

//ls_int
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		ls_int<=1'b0;
	end
	else
	begin
		case({(re&&(paddr==5'h5)),re})
			2'd0:ls_int<=(|lsr[4:0]);
			2'd1:ls_int<=(~{break_error,framing_error,parity_error,rx_overrun});
			2'd2:ls_int<=1'b0;
			2'd3:ls_int<=1'b0;
			default:ls_int<=ls_int;
		endcase
	end
end

//irq
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		irq<=1'b0;
	end
	else
	begin
		case({re&&(paddr==5'h2)})
			1'd0:irq<=(time_out|(ier[0]&rx_int)|(ier[1]&tx_int)|(ier[2]&ls_int));
			1'd1:irq<=1'b0;
			default:irq<=irq;
		endcase
	end
end

/*
//divisor
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		divisor<=8'd0;
	end
	else
	begin
		case(we)
			1'd0:divisor<=divisor;
			1'd1:divisor<=(paddr==5'd8)?pwdata[7:0]:divisor;
			//1'd1:divisor<=(we&(pwdata&(paddr==5'd7))&(pwdata&(paddr==5'd8)));
			default:divisor<=divisor;
		endcase
	end
end
*/
//divisor
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		divisor<=16'd0;
	end
	else
	begin
		case(we)
			1'd0:divisor<=divisor;
			1'd1:
				begin
					case(paddr)
						//5'd7:divisor<={divisor[15:8],pwdata[7:0]};
						5'h1c:divisor<={divisor[15:8],pwdata[7:0]};
						5'h20:divisor<={pwdata[7:0],divisor[7:0]};
						//5'd8:divisor<={pwdata[7:0],divisor[7:0]};
						default:divisor<=divisor;
					endcase
				end
			//1'd1:divisor<=(we&(pwdata&(paddr==5'd7))&(pwdata&(paddr==5'd8)));
			default:divisor<=divisor;
		endcase
	end
end

//start_dlc
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		start_dlc<=1'b0;
	end
	else
	begin
		case(we)
			1'd0:start_dlc<=start_dlc;
			1'd1:start_dlc<=(we&(1'b1&(paddr==5'd7)));
			default:start_dlc<=start_dlc;
		endcase
	end
end

//rx_int
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		rx_int<=1'b0;
	end
	else
	begin
		case(we)
			1'd0:rx_int<=1'b0;
			1'd1:rx_int<=rx_fifo_over_threshold;
			default:rx_int<=rx_int;
		endcase
	end
end

//last_tx_fifo_empty
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		last_tx_fifo_empty<=1'b0;
	end
	else
	begin
		case(we)
			1'd0:last_tx_fifo_empty<=1'b0;
			1'd1:last_tx_fifo_empty<=tx_fifo_empty;
			default:last_tx_fifo_empty<=last_tx_fifo_empty;
		endcase
	end
end

//lsr
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		lsr<=8'd96;
	end
	else
	begin
		//case({(re&(paddr==5'h5)),re})
		case({(re&(paddr==5'h14)),re})
			2'd0:lsr<=lsr;
			2'd1:lsr<={break_error,framing_error,parity_error,rx_overrun};
			2'd2:lsr<=8'd0;
			2'd3:lsr<=8'd0;
			default:lsr<=8'd96;
		endcase
	end
end

//iir
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		iir<=8'd193;
	end
	else
	begin
		case({(ls_int&ier[2]),(rx_int&ier[0]),time_out,(tx_int&ier[1])})
			4'd0:iir<=8'h1;
			4'd1:iir<=8'h4;
			4'd2:iir<=8'hc;
			4'd4:iir<=8'h4;
			4'd8:iir<=8'h6;
			default:iir<=iir;
		endcase
	end
end

//tx_int
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		tx_int<=1'd0;
	end
	else
	begin
		case(re&(paddr==5'h2)&(prdata[3:0]==4'd2))
			1'd0:tx_int<=(tx_int|(tx_fifo_empty&(~last_tx_fifo_empty)));
			1'd1:tx_int<=1'd0;
			default:tx_int<=tx_int;
		endcase
	end
end

//rx_fifo_over_threshold
always@*
begin
	case(fcr[7:5])
		3'd0:rx_fifo_over_threshold=(rx_fifo_count>=4'd1)?1'd1:1'd0;
		3'd1:rx_fifo_over_threshold=(rx_fifo_count>=4'd4)?1'd1:1'd0;
		3'd2:rx_fifo_over_threshold=(rx_fifo_count>=4'd8)?1'd1:1'd0;
		3'd3:rx_fifo_over_threshold=(rx_fifo_count>=4'd14)?1'd1:1'd0;
		3'd4,3'd5,3'd6,3'd7:rx_fifo_over_threshold=1'd0;
		default:rx_fifo_over_threshold=rx_fifo_over_threshold;
	endcase
end

//enable
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		enable<=1'd0;
	end
	else
	begin
		case((~|dlc)&(|divisor))
			1'd0:enable<=1'd0;
			1'd1:enable<=1'd1;
			default:enable<=enable;
		endcase
	end
end

//dlc
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		dlc<=1'd0;
	end
	else
	begin
		case((~|dlc)&start_dlc)
			1'd0:dlc<=dlc-1'd1;
			1'd1:dlc<=divisor-1'd1;
			default:dlc<=dlc;
		endcase
	end
end

//APB_FSM
always@(posedge pclk)
begin
	if(presetn==1'b0)
	begin
		state<=idle;						
		we<=1'b0;
		re<=1'b0;
		pready<=1'b0;
	end
	else
	begin
		case(state)
			idle:
					begin
						we<=1'b0;
						re<=1'b0;
						pready<=1'b0;
						if(psel==1'b1)
						begin
							state<=setup;
						end
						else
						begin
							state<=idle;
						end
					end 
			setup:					
					begin
						re<=1'b0;
						if(pwrite==1'b1)
						begin
							we<=1'b1;
						end
						if(psel==1'b1 && penable==1'b1)
						begin
							state<=access;
						end
						else
						begin
							state<=idle;
						end
					end 
			access:					
					begin
						we<=1'b0;
						pready<=1'b1;
						if(pwrite==1'b0)
						begin
							re<=1'b1;
						end
						state<=idle;					
					end 
			default:
					begin
						we<=1'b0;
						re<=1'b0;
						pready<=1'b0;
						state<=idle;
					end
		endcase
	end
end

//prdata
always @(posedge pclk) 
begin
    if(presetn==1'b0) 
	 begin
        prdata <= 32'd0;
    end 
	 else if(re) 
	 begin
        case(paddr)
            5'h0: prdata <= {24'd0, rx_data_out}; 
            5'h4: prdata <= {24'd0, ier};         
            5'h8: prdata <= {24'd0, fcr};  
            //5'h1: prdata <= {24'd0, ier};         
            //5'h2: prdata <= {24'd0, fcr}; 				
            //5'h3: prdata <= {24'd0, lcr}; 
				5'hc: prdata <= {24'd0, lcr}; 				
            //5'h4: prdata <= {24'd0, mcr};
            5'h14: prdata <= {24'd0, lsr};
				//5'h5: prdata <= {24'd0, lsr};
				5'h1c: prdata <= {16'd0, divisor};
				//5'h7,5'h8: prdata <= {16'd0, divisor};
				//5'h8: prdata <= {24'd0, divisor};
            default: prdata <= prdata;
        endcase
    end 
	 else 
	 begin
        prdata <= prdata;
    end
end

//rx_enable
always @(posedge pclk) 
begin
    if(presetn==1'b0)
	 begin
        rx_enable <= 1'b0;
	 end
    else
	 begin
        rx_enable <= enable;
    end
end

//tx_enable
always @(posedge pclk) 
begin
    if(presetn==1'b0)
	 begin
        tx_enable <= 1'b0;
	 end
    else
	 begin
        tx_enable <= enable;
    end
end

endmodule



/*
module register
(
pclk,presetn,psel,pwrite,penable,paddr,pwdata,
tx_fifo_count,tx_fifo_empty,tx_fifo_full,tx_busy,
rx_data_out,rx_busy_out,rx_idle,rx_overrun,
r_in,dcdn,dsrn,ctsn,
parity_error,framing_error,break_error,time_out,
rx_fifo_count,rx_fifo_empty,rx_fifo_full,push_rx_fifo,
prdata,pready,pslverr,lcr,tx_fifo_we,tx_enable,
rx_enable,rx_fifo_re,loopback,irq,baud_o,
rstn,dtrn,out1n,out2n
);
input wire r_in,dcdn,dsrn,ctsn;
input wire pclk,presetn,psel,pwrite,penable;
input wire tx_fifo_empty,tx_fifo_full,tx_busy;
input wire rx_idle,rx_overrun,rx_fifo_empty,rx_fifo_full,push_rx_fifo,rx_busy_out;
input wire parity_error,framing_error,break_error,time_out;
input wire [4:0] tx_fifo_count;
input wire [5:0] rx_fifo_count;
input wire [7:0] rx_data_out;
input wire [31:0] pwdata,paddr;

output reg rstn,dtrn,out1n,out2n;
output reg pready,pslverr,loopback,irq,baud_o;
output reg tx_fifo_we,tx_enable,rx_enable,rx_fifo_re;
output reg [7:0] lcr;
output reg [31:0] prdata;
*/
