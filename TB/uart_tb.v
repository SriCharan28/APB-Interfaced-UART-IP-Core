//actual
module uart_tb;

reg pclk_a;
reg presetn_a;
reg [31:0] paddr_a;
reg [31:0] pwdata_a;
reg pwrite_a;
reg penable_a;
reg psel_a;
reg rxd_a;
wire [31:0] prdata_a;
wire pready_a;
wire pslverr_a;
wire irq_a;
wire txd_a;
wire baud_o_a;

reg pclk_b;
reg presetn_b;
reg [31:0] paddr_b;
reg [31:0] pwdata_b;
reg pwrite_b;
reg penable_b;
reg psel_b;
reg rxd_b;
wire [31:0] prdata_b;
wire pready_b;
wire pslverr_b;
wire irq_b;
wire txd_b;
wire baud_o_b;

//transmitting
uart duta
		(
		pclk_a,presetn_a,paddr_a,pwdata_a,pwrite_a,penable_a,psel_a,rxd_a,
		prdata_a,pready_a,pslverr_a,irq_a,txd_a,baud_o_a
		);
//receiving		
uart dutb
		(
		pclk_b,presetn_b,paddr_b,pwdata_b,pwrite_b,penable_b,psel_b,txd_a,
		prdata_b,pready_b,pslverr_b,irq_b,txd_b,baud_o_b
		);

	
integer i;

parameter period_a = 10;
parameter period_b = 20;
parameter delay = 40;

wire rx_enable_a = duta.rx_enable;
wire rx_enable_b = dutb.rx_enable;
wire tx_enable_a = duta.tx_enable;
wire tx_enable_b = dutb.tx_enable;
wire [7:0] lcr_a = duta.lcr;
wire [7:0] lcr_b = dutb.lcr;
wire [7:0] fcr_a = duta.fcr;
wire [7:0] fcr_b = dutb.fcr;
wire [7:0] ier_a = duta.ier;
wire [7:0] ier_b = dutb.ier;
wire [7:0] iir_a = duta.iir;
wire [7:0] iir_b = dutb.iir;
wire [7:0] lsr_a = duta.lsr;
wire [7:0] lsr_b = dutb.lsr;
wire [7:0] divisor_a = duta.divisor;
wire [7:0] divisor_b = dutb.divisor;

wire [7:0] tx_fifo_out = duta.tx_fifo_out;
wire [7:0] tx_buffer = duta.tx_buffer;
wire [3:0] tx_state = duta.tx_state;
wire tx_fifo_we = duta.tx_fifo_we;

wire [3:0] bit_counter = dutb.bit_counter;
wire [3:0] rx_state = dutb.rx_state;
wire [7:0] rx_buffer = dutb.rx_buffer;
wire [7:0] rx_data_out = dutb.rx_data_out;
wire rx_fifo_re = dutb.rx_fifo_re;

wire [1:0] state_a = duta.state;
wire we_a  = duta.we;
wire re_a = duta.re;
wire [1:0] state_b = dutb.state;
wire we_b  = dutb.we;
wire re_b = dutb.re;


task clockA;
begin
	pclk_a=1'b0;
	#(period_a/2);
	pclk_a=1'b1;
	#(period_a/2);
end
endtask 

task clockB;
begin
	pclk_b=1'b0;
	#(period_b/2);
	pclk_b=1'b1;
	#(period_b/2);
end
endtask 

task reset_A;
begin
	@(negedge pclk_a)
	begin
		presetn_a=1'b0;
	end
	@(negedge pclk_a)
	begin
		presetn_a=1'b1;
	end
end
endtask

task reset_B;
begin
	@(negedge pclk_b)
	begin
		presetn_b=1'b0;
	end
	@(negedge pclk_b)
	begin
		presetn_b=1'b1;
	end
end
endtask

task reset;
fork
	reset_A;
	reset_B;
join
endtask

task write_a(input [4:0] addr_a,input [31:0] data_a);
begin
	//idle
	@(negedge pclk_a)
	begin
		pwdata_a=data_a;
		paddr_a=addr_a;
		pwrite_a=1'b1;
		psel_a=1'b1;
		penable_a=1'b0;
	end	
	//setup
	@(negedge pclk_a)
	begin
		penable_a=1'b1;
	end	
	//access
	@(negedge pclk_a)
	begin
		pwrite_a=1'b0;
		penable_a=1'b0;
		psel_a=1'b0;
	end
end
endtask

task write_b(input [4:0] addr_b,input [31:0] data_b);
begin
	//idle
	@(negedge pclk_b)
	begin
		pwdata_b=data_b;
		paddr_b=addr_b;
		pwrite_b=1'b1;
		psel_b=1'b1;
		penable_b=1'b0;
	end	
	//setup
	@(negedge pclk_b)
	begin
		penable_b=1'b1;
	end	
	//access
	@(negedge pclk_b)
	begin
		pwrite_b=1'b0;
		penable_b=1'b0;
		psel_b=1'b0;
	end
end
endtask

task read_a(input [4:0] addr_a);
begin
	//idle
	@(negedge pclk_a)
	begin
		paddr_a=addr_a;
		pwrite_a=1'b0;
		psel_a=1'b1;
		penable_b=1'b0;
	end	
	//setup
	@(negedge pclk_a)
	begin
		penable_a=1'b1;
	end	
	//access
	@(negedge pclk_a)
	begin
		penable_a=1'b0;
		psel_a=1'b0;
	end
end
endtask

task read_b(input [4:0] addr_b);
begin
	//idle
	@(negedge pclk_b)
	begin
		paddr_b=addr_b;
		pwrite_b=1'b0;
		psel_b=1'b1;
		penable_b=1'b0;
	end	
	//setup
	@(negedge pclk_b)
	begin
		penable_b=1'b1;
	end	
	//access
	@(negedge pclk_b)
	begin
		penable_b=1'b0;
		psel_b=1'b0;
	end
end
endtask

task serial_receive(input rdata);
begin
	for(i=0;i<31;i=i+1)
	begin
		@(negedge pclk_b)
		begin
			rxd_b=rdata;
		end
	end
end
endtask

task write(input [4:0] addr_a,input [31:0] data_a,input [4:0] addr_b,input [31:0] data_b);
fork
	write_a(addr_a,data_a);
	write_b(addr_b,data_b);
join
endtask

always
fork
	clockA;
	clockB;
join

initial
begin
	reset;
	//lcr
	//odd parity
	write(32'hc,32'd15,32'hc,32'd15);
	#delay;	
	//divisor for setting tx_enable and rx_enable
	write(32'h1c,32'd54,32'h1c,32'd27);
	#delay;
	//fcr
	write(32'h8,32'd6,32'h8,32'd6);
	#delay;
	//ier
	write(32'h4,32'd1,32'h4,32'd1);
	#delay;
	//lsr
	read_a(5'h14);
	read_b(5'h14);
	#delay;
	//Transmit_Receive
	write_a(5'd0,32'b01010100);
	//#4000;
	#8000;
	read_b(5'd0);
	read_b(5'd0); //load to prdata
end

initial
begin
	#10000;
	$finish;
end

endmodule
