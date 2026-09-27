
module player_tracker(player, toggle, clk, reset);

	input logic toggle, clk, reset;
	
	output logic player;
	
	//implemented as a t-flip flop to toggle between the players when toggle is asserted
	
	always_ff @(posedge clk) begin
		if(reset) player <= 0;
		
		else if(toggle) player <= ~player;
		
		else player <= player; 
	end

endmodule

module tb_player_tracker();

	logic toggle, clk, reset;
	
	logic player;
	
	player_tracker uut(.player, .toggle, .clk, .reset);
	
	
	parameter CLOCK_PERIOD = 100;
	
	initial begin
		clk = 1'b0;
		toggle = 1'b0;
		reset = 1'b0;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
	end
	
	initial begin
		reset <= 1'b1; repeat(2) @(posedge clk);
		reset <= 1'b0;	   		 @(posedge clk);
		
		//assert toggle as a single pulse, move to P2
		toggle <= 1'b1; @(posedge clk);
		toggle <= 1'b0; @(posedge clk);
		repeat(3) @(posedge clk); //current player should hold
		
		//assert toggle again move to P1
		toggle <= 1'b1; @(posedge clk);
		toggle <= 1'b0; @(posedge clk);
		repeat(3) @(posedge clk); //current player should hold
		
		$stop;
	end
	
endmodule

		
	