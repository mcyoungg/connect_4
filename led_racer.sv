
module led_racer(LEDR, phase, tick, clk, reset);
	//racing LEDRs when there is a win
	output logic [9:0] LEDR;
	input logic [2:0] phase;
	input logic tick;
	input logic clk, reset;
	
	logic [9:0] pos; //current led positioning
	logic dir; //the direction of travel, 1 -> right, 0 -> left
	
	localparam [2:0] WIN = 3'b101; 
	
	//edge detect the slow clk to have smooth transistions
	logic slow_clk, prev_slow;
	always_ff @(posedge clk) begin
		
		if(reset) prev_slow <= 1'b0;
		else prev_slow <= tick;
		
	end
	assign slow_clk = tick & ~prev_slow;
	
	always_ff @(posedge clk) begin
		if( reset || (WIN != phase)) begin
			pos <= 10'b0000000001;
			dir <= 1'b0;
		end
		else if(slow_clk) begin
			if(dir == 1'b0) begin
				if(pos == 10'b1000000000) dir <= 1'b1; //reaches furthest left, change directions, go right
				else pos <= pos << 1; //shift the bit left
			end
			
			else begin
				if(pos == 10'b0000000001) dir <= 1'b0; //reaches furthest right, change directions, go left
				else pos <= pos >> 1; //shift the bit right
			end
		end
	end
	
	assign LEDR = (WIN == phase) ? pos: 10'b0;

endmodule

module tb_led_racer();

	logic [9:0] LEDR; //out
	//in
	logic [2:0] phase;
	logic tick;
	logic clk, reset;
	
	led_racer uut (.LEDR, .phase, .tick, .clk, .reset);
	
	localparam [2:0] WIN = 3'b101; 
	localparam [2:0] SELECT = 3'b101; 
	
	parameter CLOCK_PERIOD = 100;
	initial begin
		clk = 1'b0;
		tick = 1'b0;
		phase = SELECT;
		forever #(CLOCK_PERIOD/2) clk = ~clk;
	end
	
	initial begin
		
		//reset state
		reset <= 1; repeat(2) @(posedge clk);
		reset <= 1; repeat(2) @(posedge clk);
		
		//enter phase = win, ledr should be racing, enable tick
		phase = WIN;
		repeat(24) begin
			tick <= 1'b1; @(posedge clk);
			tick <= 1'b0; @(posedge clk);
		end
		
	
		//LEAVING win state
		phase = SELECT; repeat(2) @(posedge clk);
		repeat(2) @(posedge clk); //confirming the ledrs are 0
		
		//re-entering win state, starting race from right to left
		phase = WIN;
		repeat(12) begin
			tick <= 1'b1; @(posedge clk);
			tick <= 1'b0; @(posedge clk);
		end
		
	end

endmodule
	
	
	
	
	
	
	

	