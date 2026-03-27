
module register_tb;
reg pclk,presetn,psel,pwrite,penable;
reg tx_fifo_empty,tx_fifo_full,tx_busy;
reg rx_idle,rx_overrun,rx_fifo_empty,rx_fifo_full,push_rx_fifo;
reg parity_error,framing_error,break_error,time_out;
reg [4:0] tx_fifo_count;
reg [4:0] rx_fifo_count;
reg [4:0] paddr;
reg [7:0] rx_data_out;
reg [31:0] pwdata;
				
wire pready,pslverr,loopback,irq,baud_o;
wire tx_fifo_we,tx_enable,rx_enable,rx_fifo_re;
wire [7:0] lcr;
wire [31:0] prdata;

register dut
				(
				pclk,presetn,psel,pwrite,pwdata,penable,paddr,
				tx_fifo_count,tx_fifo_empty,tx_fifo_full,tx_busy,
				rx_data_out,rx_idle,rx_overrun,
				rx_fifo_count,rx_fifo_empty,rx_fifo_full,push_rx_fifo,
				parity_error,framing_error,break_error,time_out,
				prdata,pready,pslverr,lcr,tx_fifo_we,tx_enable,
				rx_enable,rx_fifo_re,loopback,irq,baud_o
				);
				
parameter period = 2;
parameter delay = 4;

wire [1:0] state = dut.state;
wire [7:0] fcr = dut.fcr;
wire re = dut.re;
wire we = dut.we;
wire [7:0] divisor = dut.divisor;

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

task write(input [4:0] addr,input [31:0] data);
begin
	//idle
	@(negedge pclk)
	begin
		pwdata=data;
		paddr=addr;
		pwrite=1'b1;
		psel=1'b1;
		penable=1'b0;
	end	
	//setup
	@(negedge pclk)
	begin
		penable=1'b1;
	end	
	//access
	@(negedge pclk)
	begin
		pwrite=1'b0;
		penable=1'b0;
		psel=1'b0;
	end
end
endtask

task read(input [4:0] addr);
begin
	//idle
	@(negedge pclk)
	begin
		paddr=addr;
		pwrite=1'b0;
		psel=1'b1;
		penable=1'b0;
	end	
	//setup
	@(negedge pclk)
	begin
		penable=1'b1;
	end	
	//access
	@(negedge pclk)
	begin
		penable=1'b0;
		psel=1'b0;
	end
end
endtask


always
begin
	clock;
end

initial
begin
	reset;
	#delay;
	//divisor
	write(5'd7,32'd16);
	read(5'd7);
	//lcr
	write(5'd3,32'd7);
	#delay;
	//fcr
	write(5'd2,32'd2);
	#delay;
	//rx_fifo_re	
	rx_data_out=8'd8;
	read(5'd0);
	#delay;
	//tx_fifo_we	
	paddr=5'd0;
	pwrite=1'd1;
	psel=1'b1;
	penable=1'b0;
	#delay;
	penable=1'b1;
	#delay;
	psel=1'b0;
	penable=1'b0;
	#delay;
	//divisor
	write(5'd8,32'd16);
	read(5'd8);
end

initial
begin
	#120;
	$finish;
end
endmodule

	/*
	//lcr,prdata
	//idle state
	pwdata=32'd2;	//0000_0010
	paddr=5'h3;
	psel=1'b1; //move to setup
	penable=1'b0; //move to setup
	#delay;
	//setup state	
	pwdata=32'd2;	//0000_0010
	paddr=5'h3;
	psel=1'b1; //move to access
	penable=1'b1; //move to access
	pwrite=1'b1;
	#delay;
	//access state
	pwdata=32'd2;	//0000_0010
	paddr=5'h3;
	pwrite=1'b0;
	#delay;
	*/
	/*
	//rx_fifo_re,prdata
	//idle state
	rx_data_out=8'd8;
	paddr=5'h0;
	psel=1'b1; //move to setup
	penable=1'b0; //move to setup
	#delay;
	//setup state	
	rx_data_out=8'd8;
	paddr=5'h0;
	psel=1'b1; //move to access
	penable=1'b1; //move to access
	pwrite=1'b0;
	#delay;
	*/
	/*
	//tx_fifo_we
	//idle state
	paddr=5'h0;
	psel=1'b1; //move to setup
	penable=1'b0; //move to setup
	#delay;
	//setup state	
	paddr=5'h0;
	psel=1'b1; //move to access
	penable=1'b1; //move to access
	pwrite=1'b1;
	#delay;
	*/
	/*
	//divisor
	write(5'd8,32'd16);
	*/
	/*
	//fcr,prdata
	//idle state
	pwdata=32'd4;	//0000_0100
	paddr=5'h2;
	psel=1'b1;
	penable=1'b0;
	#delay;
	//setup state	
	pwdata=32'd4;	//0000_1000
	paddr=5'h2;
	psel=1'b1;
	pwrite=1'b1;
	penable=1'b1;
	#delay;	
	//access state	
	pwdata=32'd4;	//0000_0100
	paddr=5'h2;
	pwrite=1'b0;
	#delay;
	*/	