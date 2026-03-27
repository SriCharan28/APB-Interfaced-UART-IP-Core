
module transmitter_tb;

reg pclk;
reg presetn;
reg [7:0] pwdata;
reg tx_fifo_push;
reg enable;
reg [7:0] lcr;

wire [4:0] tx_fifo_count;
wire busy;
wire tx_fifo_full,tx_fifo_empty;
wire txd;

transmitter dut(
					pclk,presetn,pwdata,tx_fifo_push,enable,lcr,
					tx_fifo_count,busy,tx_fifo_full,tx_fifo_empty,txd
					);

parameter period = 2;
parameter delay = 4;

wire [3:0] state = dut.tx_state;

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
end
endtask

task write(input [7:0] data_in, input we);
begin
	@(negedge pclk)
	begin
		pwdata=data_in;
		tx_fifo_push=we;
	end
	@(negedge pclk)
	begin
		tx_fifo_push=1'b0;
	end
end
endtask

always
begin
	clock;
end

initial
begin	
		//reset
		pwdata=8'd0;
		tx_fifo_push=1'b0;
		enable=1'b0;
		lcr=8'd0;
		reset;
		#delay;	
		///*
		//no stick parity, odd_parity generator, odd_parity data
		enable=1'b1;		
		lcr=8'b0_0_0_0_1_1_11; //odd_parity	
		write(8'b01110000,1'b1); //odd_parity
		#delay;		
		//stick parity, even_parity generator, even_parity data
		enable=1'b1;
		lcr=8'b0_0_1_1_1_1_11; //even_parity
		write(8'b00011110,1'b1); //even_parity
		#delay;
		//*/
		/*
		//no stick parity, odd_parity generator, odd_parity data
		enable=1'b1;		
		lcr=8'b0_0_0_0_1_1_11; //odd_parity	
		write(8'b00011100,1'b1); //odd_parity
		#delay;
		*/	
		/*
		//no stick parity, odd_parity generator, even_parity data
		enable=1'b1;		
		lcr=8'b0_0_0_0_1_1_11; //odd_parity	
		write(8'b11000011,1'b1); //even_parity
		#delay;
		*/
		/*
		//no stick parity, even_parity generator, odd_parity data
		enable=1'b1;		
		lcr=8'b0_0_0_1_1_1_11; //even_parity
		write(8'b00011100,1'b1); //odd_parity
		#delay;
		*/
		/*
		//no stick parity, even_parity generator, even_parity data
		enable=1'b1;		
		lcr=8'b0_0_0_1_1_1_11; //even_parity
		write(8'b11000011,1'b1); //even_parity
		#delay;
		*/
		/*
		//stick parity, odd_parity generator, odd_parity data
		enable=1'b1;
		lcr=8'b0_0_1_0_1_1_11; //odd_parity
		write(8'b00011100,1'b1); //odd_parity
		#delay;
		*/
		/*
		//stick parity, odd_parity generator, even_parity data
		enable=1'b1;
		lcr=8'b0_0_1_0_1_1_11; //odd_parity
		write(8'b00111100,1'b1); //even_parity
		#delay;	
		*/
		/*
		//stick parity, even_parity generator, odd_parity data
		enable=1'b1;
		lcr=8'b0_0_1_1_1_1_11; //even_parity
		write(8'b00011100,1'b1); //odd_parity
		#delay;
		*/
		/*		
		//stick parity, even_parity generator, even_parity data
		enable=1'b1;
		lcr=8'b0_0_1_1_1_1_11; //even_parity
		write(8'b00111100,1'b1); //even_parity
		#delay;	
		*/		
		/*
		enable=1'b1;
		lcr=8'b0011_1000;
		write(8'b01001010,1'b1);
		#delay;
		*/
end
	
initial
begin
	$monitor("TIME :",$time,"\n CLOCK = %d, RESET = %d, WRITE_DATA =%b, WRITE_ENABLE = %d, BAUD_RATE = %d, LINE_CONTROL_REGISTER = %b, STATE = %b, COUNT = %d, BUSY = %d, FULL = %d, EMPTY = %d, TRANSMITTED_SERIAL_DATA = %d",pclk,presetn,pwdata,tx_fifo_push,enable,lcr,state,tx_fifo_count,busy,tx_fifo_full,tx_fifo_empty,txd);
end


initial
begin
	//#400;
	#800;
	$finish;
end


endmodule

