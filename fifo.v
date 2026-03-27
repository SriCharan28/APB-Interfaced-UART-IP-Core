
module fifo
(
clk,rstn,data_in,push,pop,
data_out,fifo_full,fifo_empty,count
);
input wire clk;
input wire rstn;
input wire [7:0] data_in;
input wire push,pop;
output reg [7:0] data_out;
output wire fifo_full,fifo_empty;
output wire [4:0] count;

reg [7:0] mem [15:0];
reg [3:0] ip_count_reg,ip_count_next;
reg [3:0] op_count_reg,op_count_next;
reg [4:0] count_reg,count_next;

integer i;


//write_read
always@(posedge clk)
begin
	if(rstn==1'b0)
	begin
		data_out<=8'd0;
		for(i=0;i<16;i=i+1)
		begin
			mem[i]<=8'd0;
		end
	end
	else
	begin
		//write
		if(push==1'b1 && fifo_full!=1'b1)
		begin
			mem[ip_count_reg]<=data_in;
		end		
		//read
		if(pop==1'b1 && fifo_empty!=1'b1)
		begin
			data_out<=mem[op_count_reg];
		end
	end
end


//ip_count
always@(posedge clk)
begin
	if(rstn==1'd0)
	begin
		ip_count_reg<=4'd0;
	end
	else
	begin
		ip_count_reg<=ip_count_next;
	end
end

always@*
begin
		case({push,pop})
		2'd0:ip_count_next=ip_count_reg;
		2'd1:ip_count_next=ip_count_reg;
		2'd2:
			  begin
					if(count_reg<=4'd15)
					begin
						ip_count_next=ip_count_reg+4'd1;
					end
					else
					begin
						ip_count_next=ip_count_reg;
					end
			  end
		2'd3:ip_count_next=ip_count_reg+4'd1;
		default:ip_count_next=ip_count_reg;
		endcase
	
end


//op_count
always@(posedge clk)
begin
	if(rstn==1'd0)
	begin
		op_count_reg<=4'd0;
	end
	else
	begin
		op_count_reg<=op_count_next;
	end
end

always@*
begin
		case({push,pop})
		2'd0:op_count_next=op_count_reg;
		2'd1:			  
			 begin
					if(count_reg>4'd0)
					begin
						op_count_next=op_count_reg+4'd1;
					end
					else
					begin
						op_count_next=op_count_reg;
					end
			  end
		2'd2:op_count_next=op_count_reg;
		2'd3:op_count_next=op_count_reg+4'd1;
		default:op_count_next=op_count_reg;
		endcase
end


//count
always@(posedge clk)
begin
	if(rstn==1'd0)
	begin
		count_reg<=5'd0;
	end
	else
	begin
		count_reg<=count_next;
	end
end

always@*
begin
		case({push,pop})
		2'd0:count_next=count_reg;
		2'd1:
			 begin
				if(count_reg>5'd0)
				begin
					count_next=count_reg-5'd1;
				end
				else
				begin
					count_next=count_reg;
				end
			 end
		2'd2:			 
			 begin
				if(count_reg<=5'd15)
				begin
					count_next=count_reg+5'd1;
				end
				else
				begin
					count_next=count_reg;
				end
			 end
		2'd3:count_next=count_reg;
		default:count_next=count_reg;
		endcase
end

assign count = count_reg;


//fifo_full
assign fifo_full = (count==5'd16) ? 1'd1 : 1'd0;

//fifo_empty
assign fifo_empty = ~|count;


endmodule

/*
module fifo
(
clk,rstn,data_in,push,pop,
data_out,fifo_full,fifo_empty,count
);
input wire clk;
input wire rstn;
input wire [7:0] data_in;
input wire push,pop;
output reg [7:0] data_out;
output wire fifo_full,fifo_empty;
output wire [4:0] count;

reg [7:0] mem [15:0];
reg [3:0] ip_count,op_count;

integer i;


//write_read
always@(posedge clk)
begin
	if(rstn==1'b0)
	begin
		data_out<=8'd0;
		for(i=0;i<16;i=i+1)
		begin
			mem[i]<=8'd0;
		end
	end
	else
	begin
		//write
		if(push==1'b1 && fifo_full!=1'b1)
		begin
			mem[ip_count]<=data_in;
		end		
		//read
		if(pop==1'b1 && fifo_empty!=1'b1)
		begin
			data_out<=mem[op_count];
		end
	end
end


//ip_count
always@(posedge clk)
begin
	if(rstn==1'd0)
	begin
		ip_count<=4'd0;
	end
	else
	begin
		case({push,pop})
		2'd0:ip_count<=ip_count;
		2'd1:ip_count<=ip_count;
		2'd2:
			  begin
					if(count<=4'd15)
					begin
						ip_count<=ip_count+4'd1;
					end
					else
					begin
						ip_count<=ip_count;
					end
			  end
		2'd3:ip_count<=ip_count+4'd1;
		default:ip_count<=ip_count;
		endcase
	end	
end


//op_count
always@(posedge clk)
begin
	if(rstn==1'd0)
	begin
		op_count<=4'd0;
	end
	else
	begin
		case({push,pop})
		2'd0:op_count<=op_count;
		2'd1:			  
			 begin
					if(count>4'd0)
					begin
						op_count<=op_count+4'd1;
					end
					else
					begin
						op_count<=op_count;
					end
			  end
		2'd2:op_count<=op_count;
		2'd3:op_count<=op_count+4'd1;
		default:op_count<=op_count;
		endcase
	end	
end


//count
always@(posedge clk)
begin
	if(rstn==1'd0)
	begin
		count<=5'd0;
	end
	else
	begin
		case({push,pop})
		2'd0:count<=count;
		2'd1:
			 begin
				if(count>5'd0)
				begin
					count<=count-5'd1;
				end
				else
				begin
					count<=count;
				end
			 end
		2'd2:			 
			 begin
				if(count<=5'd15)
				begin
					count<=count+5'd1;
				end
				else
				begin
					count<=count;
				end
			 end
		2'd3:count<=count;
		default:count<=count;
		endcase
	end
end


//fifo_full
assign fifo_full = (count==5'd16) ? 1'd1 : 1'd0;

//fifo_empty
assign fifo_empty = ~|count;


endmodule
*/