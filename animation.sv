
module animation(curr_row, anim_done, landing_row, start, slow_clk, clk, reset);

	input logic [2:0] landing_row;
	input logic start, slow_clk, clk, reset;
	
	output logic [2:0] curr_row;
	output logic anim_done;
	
	//need to create a slow single cycle pulse to visually see and animate
	logic tick, prev_slow;
	always_ff @(posedge clk) begin
		
		if(reset) prev_slow <= 1'b0;
		else prev_slow <= slow_clk;
		
	end
	assign tick = slow_clk & ~prev_slow;
	
	//counter to decrement falling downwards
	always_ff @(posedge clk) begin
		if(reset) curr_row <= 3'b101;
		
		else if(start) curr_row <= 3'b101; //need a way to reset animation without reseting the whole game
		
		else if(tick && curr_row > landing_row) curr_row <= curr_row-1'b1; //decrement
		
		else curr_row <= curr_row; //hold
	end
	
	assign anim_done = (curr_row == landing_row);

endmodule

module tb_animation();

	logic [2:0] landing_row;
	logic start, slow_clk, clk, reset;
	
	logic [2:0] curr_row;
	logic anim_done;
	
	animation uut(.curr_row, .anim_done, .landing_row, .start, .slow_clk, .clk, .reset);

	parameter CLOCK_PERIOD = 100;

	initial begin
	
		clk = 1'b0;
		landing_row = 3'b000;
		start = 1'b0;
		slow_clk = 1'b0;
		reset = 1'b0;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin
	
		reset <= 1'b1; repeat(2) @(posedge clk); //load curr_row as 5
		reset <= 1'b0; @(posedge clk);
		
		landing_row <= 3'b010; @(posedge clk);
		
		start <= 1'b1; @(posedge clk); //load curr_row as 5
		start <= 1'b0; @(posedge clk);
		
		//partial fall
		//enable slow clk ticks, curr_row should be decrementing and not surpass landing row
		//even tho slow clock held high mutiple cycles, should pulse only once
		repeat(6) begin
			slow_clk <= 1'b1; repeat(3) @(posedge clk);
			slow_clk <= 1'b0; repeat(3) @(posedge clk);
		end
		//anim_done should equal 1 at 2
		
		//full fall
		landing_row <= 3'b000; @(posedge clk);
		
		start <= 1'b1; @(posedge clk); //load curr_row as 5 w/o reseting
		start <= 1'b0; @(posedge clk);
		
		//curr_row = 5 -> 4 -> 3 -> 2 -> 1 -> 0 & anim_done=1 at this point
		repeat(8) begin
			slow_clk <= 1'b1; repeat(3) @(posedge clk);
			slow_clk <= 1'b0; repeat(3) @(posedge clk);
		end
		
		$stop;
		
	end
	
endmodule
		

	