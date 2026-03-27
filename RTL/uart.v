
module uart
(
pclk,presetn,paddr,pwdata,pwrite,penable,psel,rxd,
prdata,pready,pslverr,irq,txd,baud_o
);
input wire pclk;
input wire presetn;
input wire [31:0] paddr;
input wire [31:0] pwdata;
input wire pwrite;
input wire penable;
input wire psel;
input wire rxd;

output wire [31:0] prdata;
output wire pready;
output wire pslverr;
output wire irq;
output wire txd;
output wire baud_o;

//internal signals
wire loopback; //register,reciever
wire rx_fifo_empty; //register
wire rx_idle; //receiver,register
wire rx_fifo_we; //receiver,register
wire rx_enable; //receiver,register
wire rx_overrun; //receiver,register
wire push_rx_fifo; //receiver,register
wire rx_fifo_re; //receiver,register
wire rx_fifo_full; //receiver,register
wire time_out; //receiver,register
wire break_error; //receiver,register
wire parity_error; //receiver,register
wire framing_error; //receiver,register
wire [4:0] rx_fifo_count; //receiver,register
wire [7:0] rx_data_out; //receiver,register
wire tx_busy; //transmitter,register
wire tx_fifo_full; //transmitter,register
wire tx_fifo_empty; //transmitter,register
wire [4:0] tx_fifo_count; //transmitter,register
wire tx_fifo_we; //transmitter,register
wire tx_enable; //transmitter,register
wire [7:0] lcr; //transmitter,receiver,register
wire [7:0] fcr; //transmitter,receiver,register
wire [7:0] ier; //transmitter,receiver,register
wire [7:0] iir; //transmitter,receiver,register
wire [7:0] lsr; //transmitter,receiver,register
wire [7:0] divisor; //transmitter,receiver,register

///*
//additional internal signals
wire [7:0] tx_fifo_out = tx_uart.tx_fifo_out;
wire [7:0] tx_buffer = tx_uart.tx_buffer;
wire [3:0] tx_state = tx_uart.tx_state;

wire  [3:0] bit_counter = rx_uart.bit_counter;
wire [3:0] rx_state = rx_uart.rx_state;
wire [7:0] rx_buffer = rx_uart.rx_buffer;

wire [1:0] state = reg_uart.state;
wire we  = reg_uart.we;
wire re  = reg_uart.re;

assign fcr = reg_uart.fcr;
assign ier = reg_uart.ier;
assign iir = reg_uart.iir;
assign lsr = reg_uart.lsr;
assign divisor = reg_uart.divisor;
//*/

//transmitter
transmitter tx_uart
(
pclk,presetn,pwdata[7:0],tx_fifo_we,tx_enable,lcr,
tx_fifo_count,tx_busy,tx_fifo_full,tx_fifo_empty,txd
);

//receiver
rx rx_uart
(
pclk,presetn,rxd,rx_fifo_re,rx_enable,lcr,
rx_idle,rx_fifo_count,rx_data_out,push_rx_fifo,rx_fifo_full,rx_overrun,framing_error,parity_error,break_error,time_out,rx_fifo_empty
);

//register
register reg_uart
(
pclk,presetn,psel,pwrite,pwdata,penable,paddr[4:0],
tx_fifo_count,tx_fifo_empty,tx_fifo_full,tx_busy,
rx_data_out,rx_idle,rx_overrun,
rx_fifo_count,rx_fifo_empty,rx_fifo_full,push_rx_fifo,
parity_error,framing_error,break_error,time_out,
prdata,pready,pslverr,lcr,tx_fifo_we,tx_enable,
rx_enable,rx_fifo_re,loopback,irq,baud_o
);

endmodule
