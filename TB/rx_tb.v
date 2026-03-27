
module rx_tb;

reg pclk;
reg presetn;
reg rxd;
reg pop_rx_fifo;
reg enable;
reg [7:0] lcr;

wire framing_error,parity_error;
wire rx_overrun;
wire rx_idle;
wire push_rx_fifo;
wire rx_fifo_full;
wire break_error,time_out;
wire [4:0] rx_fifo_count;
wire [7:0] rx_fifo_out;
wire rx_fifo_empty;

rx dut(
		pclk,presetn,rxd,pop_rx_fifo,enable,lcr,
		rx_idle,rx_fifo_count,rx_fifo_out,push_rx_fifo,rx_fifo_full,rx_overrun,framing_error,parity_error,break_error,time_out,rx_fifo_empty
		);

parameter period = 2;
parameter delay = 4;

integer i;

wire [3:0] state = dut.rx_state;
wire [7:0] rx_buffer = dut.rx_buffer;

task clock;
begin
	pclk=1'b0;
	#(period/2);
	pclk=1'b1;
	#(period/2);
end
endtask

task reset;
begin
	@(negedge pclk)
	begin
		presetn=1'b0;
	end	
	@(negedge pclk)
	begin
		presetn=1'b1;
	end
	@(negedge pclk)
	begin
		rxd=1'b1;
	end
end
endtask

task read(input re);
begin
	@(negedge pclk)
	begin
		pop_rx_fifo=re;
	end
	@(negedge pclk)
	begin
		pop_rx_fifo=1'b0;
	end
end
endtask

task serial_receive(input data);
begin
	for(i=0;i<16;i=i+1)
	begin
		@(negedge pclk)
		begin
			rxd=data;
		end
	end
end
endtask

always
begin
	clock;
end

initial
begin	
		pop_rx_fifo=1'b0;
		enable=1'b0;
		lcr=8'd0;
		reset;
		#delay;	
		///*
		enable=1'b1;		
		lcr=8'b0_0_0_0_1_1_11; //odd_parity
		serial_receive(1'b0); //idle
		serial_receive(1'b0); //start
		serial_receive(1'b0); //bit0		
		serial_receive(1'b0); //bit1
		serial_receive(1'b1); //bit2		
		serial_receive(1'b0); //bit3
		serial_receive(1'b1); //bit4		
		serial_receive(1'b0); //bit5
		serial_receive(1'b1); //bit6		
		serial_receive(1'b0); //bit7
		serial_receive(1'b0); //parity		
		serial_receive(1'b1); //stop1
		serial_receive(1'b1); //stop2
		read(1'b1);
		#delay;	
		//*/
		/*		
		//Break Error
		enable=1'b1;		
		lcr=8'b0_0_0_1_1_1_11; //even_parity
		serial_receive(1'b0); //idle
		serial_receive(1'b0); //start
		serial_receive(1'b0); //bit0		
		serial_receive(1'b0); //bit1
		serial_receive(1'b0); //bit2		
		serial_receive(1'b0); //bit3
		serial_receive(1'b0); //bit4		
		serial_receive(1'b0); //bit5
		serial_receive(1'b0); //bit6		
		serial_receive(1'b0); //bit7
		serial_receive(1'b0); //parity		
		serial_receive(1'b0); //stop1
		serial_receive(1'b0); //stop2
		read(1'b1);
		#delay;
		*/
		/*
		//Framing Error
		enable=1'b1;		
		lcr=8'b0_0_0_1_1_1_11; //even_parity
		serial_receive(1'b0); //idle
		serial_receive(1'b0); //start
		serial_receive(1'b0); //bit0		
		serial_receive(1'b0); //bit1
		serial_receive(1'b1); //bit2		
		serial_receive(1'b1); //bit3
		serial_receive(1'b1); //bit4		
		serial_receive(1'b1); //bit5
		serial_receive(1'b0); //bit6		
		serial_receive(1'b0); //bit7
		serial_receive(1'b0); //parity		
		serial_receive(1'b0); //stop1
		serial_receive(1'b1); //stop2
		read(1'b1);
		#delay;
		*/
		//Parity Error
		/*
		//Data Odd Parity, LCR Odd Parity, No Parity Error
		enable=1'b1;		
		lcr=8'b0_0_0_0_1_1_11; //odd_parity
		serial_receive(1'b0); //idle
		serial_receive(1'b0); //start
		serial_receive(1'b0); //bit0		
		serial_receive(1'b0); //bit1
		serial_receive(1'b0); //bit2		
		serial_receive(1'b1); //bit3
		serial_receive(1'b1); //bit4		
		serial_receive(1'b1); //bit5
		serial_receive(1'b0); //bit6		
		serial_receive(1'b0); //bit7
		serial_receive(1'b0); //parity		
		serial_receive(1'b1); //stop1
		serial_receive(1'b1); //stop2
		read(1'b1);
		#delay;	
		*/	
		/*
		//Data Odd Parity, Odd Parity, Parity Error
		enable=1'b1;		
		lcr=8'b0_0_0_0_1_1_11; //odd_parity
		serial_receive(1'b0); //idle
		serial_receive(1'b0); //start
		serial_receive(1'b0); //bit0		
		serial_receive(1'b0); //bit1
		serial_receive(1'b0); //bit2		
		serial_receive(1'b1); //bit3
		serial_receive(1'b1); //bit4		
		serial_receive(1'b1); //bit5
		serial_receive(1'b0); //bit6		
		serial_receive(1'b0); //bit7
		serial_receive(1'b1); //parity		
		serial_receive(1'b1); //stop1
		serial_receive(1'b1); //stop2
		read(1'b1);
		#delay;	
		*/			
		/*
		//Data Odd Parity, LCR Even Parity, No Parity Error
		enable=1'b1;		
		lcr=8'b0_0_0_1_1_1_11; //even_parity
		serial_receive(1'b0); //idle
		serial_receive(1'b0); //start
		serial_receive(1'b0); //bit0		
		serial_receive(1'b0); //bit1
		serial_receive(1'b0); //bit2		
		serial_receive(1'b1); //bit3
		serial_receive(1'b1); //bit4		
		serial_receive(1'b1); //bit5
		serial_receive(1'b0); //bit6		
		serial_receive(1'b0); //bit7
		serial_receive(1'b1); //parity		
		serial_receive(1'b1); //stop1
		serial_receive(1'b1); //stop2
		read(1'b1);
		#delay;	
		*/		
		/*
		//Data Odd Parity, LCR Even Parity, Parity Error
		enable=1'b1;		
		lcr=8'b0_0_0_1_1_1_11; //even_parity
		serial_receive(1'b0); //idle
		serial_receive(1'b0); //start
		serial_receive(1'b0); //bit0		
		serial_receive(1'b0); //bit1
		serial_receive(1'b0); //bit2		
		serial_receive(1'b1); //bit3
		serial_receive(1'b1); //bit4		
		serial_receive(1'b1); //bit5
		serial_receive(1'b0); //bit6		
		serial_receive(1'b0); //bit7
		serial_receive(1'b0); //parity		
		serial_receive(1'b1); //stop1
		serial_receive(1'b1); //stop2
		read(1'b1);
		#delay;	
		*/
		/*
		//Data Even Parity, LCR Odd Parity, No Parity Error
		enable=1'b1;		
		lcr=8'b0_0_0_0_1_1_11; //odd_parity
		serial_receive(1'b0); //idle
		serial_receive(1'b0); //start
		serial_receive(1'b0); //bit0		
		serial_receive(1'b0); //bit1
		serial_receive(1'b1); //bit2		
		serial_receive(1'b1); //bit3
		serial_receive(1'b1); //bit4		
		serial_receive(1'b1); //bit5
		serial_receive(1'b0); //bit6		
		serial_receive(1'b0); //bit7
		serial_receive(1'b1); //parity		
		serial_receive(1'b1); //stop1
		serial_receive(1'b1); //stop2
		read(1'b1);
		#delay;	
		*/	
		/*
		//Data Even Parity, Odd Parity, Parity Error
		enable=1'b1;		
		lcr=8'b0_0_0_0_1_1_11; //odd_parity
		serial_receive(1'b0); //idle
		serial_receive(1'b0); //start
		serial_receive(1'b0); //bit0		
		serial_receive(1'b0); //bit1
		serial_receive(1'b1); //bit2		
		serial_receive(1'b1); //bit3
		serial_receive(1'b1); //bit4		
		serial_receive(1'b1); //bit5
		serial_receive(1'b0); //bit6		
		serial_receive(1'b0); //bit7
		serial_receive(1'b0); //parity		
		serial_receive(1'b1); //stop1
		serial_receive(1'b1); //stop2
		read(1'b1);
		#delay;	
		*/			
		/*
		//Data Even Parity, LCR Even Parity, No Parity Error
		enable=1'b1;		
		lcr=8'b0_0_0_1_1_1_11; //even_parity
		serial_receive(1'b0); //idle
		serial_receive(1'b0); //start
		serial_receive(1'b0); //bit0		
		serial_receive(1'b0); //bit1
		serial_receive(1'b1); //bit2		
		serial_receive(1'b1); //bit3
		serial_receive(1'b1); //bit4		
		serial_receive(1'b1); //bit5
		serial_receive(1'b0); //bit6		
		serial_receive(1'b0); //bit7
		serial_receive(1'b0); //parity		
		serial_receive(1'b1); //stop1
		serial_receive(1'b1); //stop2
		read(1'b1);
		#delay;	
		*/				
		/*
		//Data Even Parity, LCR Even Parity, Parity Error
		enable=1'b1;		
		lcr=8'b0_0_0_1_1_1_11; //even_parity
		serial_receive(1'b0); //idle
		serial_receive(1'b0); //start
		serial_receive(1'b0); //bit0		
		serial_receive(1'b0); //bit1
		serial_receive(1'b1); //bit2		
		serial_receive(1'b1); //bit3
		serial_receive(1'b1); //bit4		
		serial_receive(1'b1); //bit5
		serial_receive(1'b0); //bit6		
		serial_receive(1'b0); //bit7
		serial_receive(1'b1); //parity		
		serial_receive(1'b1); //stop1
		serial_receive(1'b1); //stop2
		read(1'b1);
		#delay;	
		*/
		/*
		//Data Odd Parity, LCR Odd Parity, Stick Parity
		enable=1'b1;		
		lcr=8'b0_0_1_0_1_1_11; //odd_parity
		//lcr=8'b0_0_1_1_1_1_11; //even_parity
		serial_receive(1'b0); //idle
		serial_receive(1'b0); //start
		serial_receive(1'b0); //bit0		
		serial_receive(1'b0); //bit1
		serial_receive(1'b1); //bit2		
		serial_receive(1'b1); //bit3
		serial_receive(1'b1); //bit4		
		serial_receive(1'b1); //bit5
		serial_receive(1'b0); //bit6		
		serial_receive(1'b0); //bit7
		serial_receive(1'b0); //parity	
		//serial_receive(1'b1); //parity		
		serial_receive(1'b1); //stop1
		serial_receive(1'b1); //stop2
		read(1'b1);
		#delay;	
		*/
end
	
initial
begin
	$monitor("TIME :",$time,"\n CLOCK = %d, RESET = %d, RECEIVED_SERIAL_DATA =%d, READ_ENABLE = %d, BAUD_RATE = %d, LINE_CONTROL_REGISTER = %b, STATE = %b, WRITE_ENABLE = %d, RECEIVED_DATA = %b, COUNT = %d, FULL = %d, IDLE = %d, OVERRUN =%d, FRAMING_ERROR = %d, PARITY_ERROR = %d, BREAK_ERROR = %d, TIMEOUT = %d EMPTY = %d",pclk,presetn,rxd,pop_rx_fifo,enable,lcr,state,push_rx_fifo,rx_fifo_out,rx_fifo_count,rx_fifo_full,rx_idle,rx_overrun,framing_error,parity_error,break_error,time_out,rx_fifo_empty);
end


initial
begin
	#450;
	$finish;
end


endmodule

		
