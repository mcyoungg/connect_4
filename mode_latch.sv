
module mode_latch(multiplayer, mode_switch, clk, reset);

	output logic multiplayer;
	input logic mode_switch, clk, reset;
	
	//SW8 determines the kind of game mode we are in
	//sw8 -> 1 is for multiplayer
	//SW8 -> 0 is for single player with AI
	
	//SW9 resets the game based on the type of game mode we are in
	//for e.g. SW9->1, SW8->1, means to reset the multiplayer game board
	//While SW9 is asserted you can switch game modes
	
	always_ff @(posedge clk) begin
		if(reset) multiplayer <= mode_switch;
		else multiplayer <= multiplayer;
	end
	
endmodule

module tb_mode_latch();

	logic multiplayer;
	logic mode_switch, clk, reset;
	
	mode_latch uut (.multiplayer, .mode_switch, .clk, .reset);
	
	parameter CLOCK_PERIOD = 100;
	
	initial begin
	
		clk = 0;
		mode_switch = 0; //starting in single player mode
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin
	
		//While SW9 (reset) is asserted you can switch game modes
		//observe multiplayer output
		
		reset <= 1; @(posedge clk);
		
		mode_switch <= 1; repeat(2) @(posedge clk);
		
		mode_switch <= 0; repeat(2) @(posedge clk);
		
		//While the reset is not asserted, you cannot change the game-mode
		//multiplayer stays latched to 0 (single player)
		reset <= 0; @(posedge clk);
		
		mode_switch <= 1; repeat(2) @(posedge clk);
		
		mode_switch <= 0; repeat(2) @(posedge clk);
		
		//While the reset is not asserted, you cannot change the game-mode
		//multiplayer stays latched to 1 (multiplayer)
		reset <= 1; @(posedge clk);
		mode_switch <= 1; @(posedge clk);
		reset <= 0; @(posedge clk);
		
		mode_switch <= 0; repeat(2) @(posedge clk);
		
		
		$stop;
	end
	
endmodule
	
	