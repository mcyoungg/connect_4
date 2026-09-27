
module user_input(out, in, clk, reset); //active low button press
	
	input logic in, clk, reset;
	output logic out;
	
	logic prev_state;//0 -> pressed, 1 -> not pressed
	
	d_ff u_in (.q(prev_state), .d(in), .clk(clk), .reset(reset));
	
	assign out = ~in & prev_state;
	
endmodule

module tb_user_input();

	logic out, in, clk, reset;
	
	user_input uut(.out(out), .in(in), .clk(clk), .reset(reset));
	
	parameter CLOCK_PERIOD = 100;
	
	initial begin
	
		clk = 0;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin 
	
		reset <= 1; 						 @(posedge clk);
		reset <= 0; in <= 1; repeat(2) @(posedge clk);
		
		in <= 0;			      repeat(4) @(posedge clk); //holding input high should result in out being high for one clock pulse

		in <= 1;					repeat(3) @(posedge clk);

		in <= 0; 				repeat(2) @(posedge clk);
	
		in <= 0;					@(posedge clk);
		in <= 1;					@(posedge clk);
		in <= 0;					@(posedge clk); //back and forth behavior for multiple button presses?
		in <= 1;					@(posedge clk);
		in <= 0;					@(posedge clk);
									@(posedge clk);
		$stop;
		
	end
	
endmodule
