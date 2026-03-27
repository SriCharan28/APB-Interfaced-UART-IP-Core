
module fifo_tb;
reg clk;
reg rstn;
reg [7:0] data_in;
reg push,pop;
wire [7:0] data_out;
wire fifo_full,fifo_empty;
wire [4:0] count;

fifo dut(clk,rstn,data_in,push,pop,data_out,fifo_full,fifo_empty,count);

integer i;
parameter period = 10;
parameter delay = 20;

task clock;
begin
	clk=1'd0;
	#(period/2);
	clk=1'd1;
	#(period/2);
end
endtask

task reset;
begin
	@(negedge clk)
	begin
		rstn=1'b0;
	end
	@(negedge clk)
	begin  
		rstn=1'd1;
	end
end
endtask

task write(input we,input [7:0] write_data);
begin
	@(negedge clk)
	begin
		push   = we;
		data_in = write_data;
	end	
	@(negedge clk)
	begin
		push   = 1'd0;
		data_in = 8'd0;
	end
end
endtask

task read(input re);
begin
	@(negedge clk)
	begin
		pop = re;
	end	
	@(negedge clk)
	begin
		pop = 1'd0;
	end
end
endtask

always
begin
	clock;
end

initial
begin	
	push=1'd0;
	pop=1'd0;
	data_in=8'd0;
	reset;
	#delay;
	for(i=0;i<16;i=i+1)
	begin
		write(1'd1,i);
	end
	#delay;
	write(1'd0,8'd0);
	#delay;
	repeat(16)
	begin
		read(1'd1);
	end
	#delay;
	repeat(2)
	begin
		read(1'd0);
	end
	#delay;
	repeat(2)
	begin
		write(1'b1,{$random}%10);
	end
	#delay;
	repeat(2)
	begin
		read(1'b1);
	end
	#delay;
	reset;
end

initial
begin
	$monitor("TIME :",$time,
	"\n CLOCK = %d, RESET = %d, WRITE_DATA = %d, WRITE_ENABLE = %d, READ_ENABLE = %d, READ_DATA = %d, FIFO_FULL = %d, FIFO_EMPTY = %d, ELEMENT_COUNT = %d",
	clk,rstn,data_in,push,pop,data_out,fifo_full,fifo_empty,count);
end

initial
begin 
	#1000;
	$finish;
end

endmodule



/*
module tb_fifo;
reg clk;
reg rstn;
reg [7:0] data_in;
reg push,pop;
wire [7:0] data_out;
wire fifo_full,fifo_empty;
wire [4:0] count;

fifo dut (
			clk,rstn,data_in,push,pop,
			data_out,fifo_full,fifo_empty,count
			);


    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rstn = 0;
        push = 0;
        pop = 0;
        data_in = 8'd0;


        #10 rstn = 1;

        $display("Filling FIFO");
        repeat(16) begin  
            @(negedge clk);
            push = 1;
            data_in = $random % 256;
        end
        @(negedge clk) push = 0; 


        @(negedge clk);
        push = 1; data_in = 8'hAA;
        @(negedge clk) push = 0;


        $display("Emptying FIFO");
        repeat(16) begin
            @(negedge clk);
            pop = 1;
        end
        @(negedge clk) pop = 0;

        @(negedge clk);
        pop = 1;
        @(negedge clk) pop = 0;

        #50 $finish;
    end

    initial begin
        $monitor("T=%0t | clk=%b rstn=%b push=%b pop=%b data_in=%d data_out=%d full=%b empty=%b", 
                  $time, clk, rstn, push, pop, data_in, data_out, fifo_full, fifo_empty);
    end
endmodule
*/
