
module hex_display(HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, phase, player, game_mode);
	
	output logic [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
	
	input logic [2:0] phase;
	input logic player, game_mode;
	
	//bring back the state encoding
	localparam [2:0] SELECT=1, ANIMATE=2, COMMIT=3, CHECK=4, WIN=5, DRAW=6;
	
	//number and letter encoding
	localparam [6:0] BLANK	= 7'b1111111;
	localparam [6:0] ONE 	= 7'b1111001;
	localparam [6:0] TWO 	= 7'b0100100;
	localparam [6:0] P		= 7'b0001100;
	localparam [6:0] T		= 7'b0000111;
	localparam [6:0] U		= 7'b1100011;
	localparam [6:0] R		= 7'b0101111;
	localparam [6:0] N		= 7'b0101011;
	localparam [6:0] S		= 7'b0010010;
	localparam [6:0] F		= 7'b0001110;
	localparam [6:0] L		= 7'b1000111;
	localparam [6:0] O		= 7'b0100011;
	localparam [6:0] B		= 7'b0000011;
	
	//based on player substitute 
	logic [6:0] player_num;
	assign player_num = player ? TWO: ONE;
	
	//based on state, hex needs to behave in certain ways
	logic in_play;
	assign in_play = ((phase == SELECT)||
						 (phase == ANIMATE) || 
						 (phase == COMMIT)  ||
						 (phase == CHECK));
						 
	//assign outputs
	always_comb begin
		if(in_play && game_mode) {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = {P, player_num, T, U, R, N};
		
		else if(in_play && !game_mode) begin //take into account single player mode
			if(player) {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = {B, O, T, T, R, N};
			else {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = {P, ONE, T, U, R, N};
		end
		
		else if((phase == WIN) && game_mode) {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = {P, player_num, BLANK, ONE, S, T};
		
		else if((phase == WIN) && !game_mode) begin //take into account single player mode
			if(player) {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = {B, O, T, ONE, S, T};
			else {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = {P, ONE, BLANK, ONE, S, T};
		end
		
		else if(phase == DRAW) {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = {BLANK, F, U, L, L, BLANK};
		
		else {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = {BLANK, BLANK, BLANK, BLANK, BLANK, BLANK};
		
	end
	
endmodule
	
module tb_hex_display();
	
	//out
	logic [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
	
	//in
	logic [2:0] phase;
	logic player, game_mode;
	
	hex_display uut (.HEX5, .HEX4, .HEX3, .HEX2, .HEX1, .HEX0, .phase, .player, .game_mode);
	
	localparam [2:0] INIT = 3'd0;
	localparam [2:0] SELECT = 3'd1;
	localparam [2:0] ANIMATE = 3'd2;
	localparam [2:0] COMMIT = 3'd3;
	localparam [2:0] CHECK = 3'd4;
	localparam [2:0] WIN = 3'd5;
	localparam [2:0] DRAW = 3'd6;
	
	parameter CLOCK_PERIOD = 100;
	logic clk;
	
	initial begin
	
		clk = 1'b0;

		player = 1'b0;
		phase = INIT;
		game_mode = 1;

		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin
		
		//multiplayer (game_mode = 1): starting phase = INIT, and player 1, HEXs -> BLANK
		repeat(2) @(posedge clk);
		
		//phase = SELECT, HEXs -> P1 turn
		phase = SELECT; @(posedge clk);
		
		//phase = ANIMATE, HEXs -> P1 turn
		phase = ANIMATE; @(posedge clk);
		
		//phase = COMMIT, HEXs -> P1 turn
		phase = COMMIT; @(posedge clk);
		
		//phase = CHECK, HEXs -> P1 turn
		phase = CHECK; @(posedge clk);
		
		//phase = WIN, HEXs -> P1 1ST
		phase = WIN; @(posedge clk);
		
		
		//multiplayer (game_mode = 1): change to P2 turn
		phase = INIT; player = 1'b1; repeat(2) @(posedge clk);
		
		//phase = SELECT, HEXs -> P2 turn
		phase = SELECT; @(posedge clk);
		
		//phase = ANIMATE, HEXs -> P2 turn
		phase = ANIMATE; @(posedge clk);
		
		//phase = COMMIT, HEXs -> P2 turn
		phase = COMMIT; @(posedge clk);
		
		//phase = CHECK, HEXs -> P2 turn
		phase = CHECK; @(posedge clk);
		
		//phase = WIN, HEXs -> P2 1ST
		phase = WIN; @(posedge clk);
		
		
		//check for draw? in multiplayer HEXs -> FULL
		phase = INIT; repeat(2) @(posedge clk);
		
		phase = DRAW; @(posedge clk);
		

		//single player: bot turn
		phase = INIT; game_mode = 0; player = 1'b1; repeat(2) @(posedge clk);
		
		//phase = SELECT, HEXs -> bot trn
		phase = SELECT; @(posedge clk);
		
		//phase = ANIMATE, HEXs -> bot trn
		phase = ANIMATE; @(posedge clk);
		
		//phase = COMMIT, HEXs -> bot trn
		phase = COMMIT; @(posedge clk);
		
		//phase = CHECK, HEXs -> bot trn
		phase = CHECK; @(posedge clk);
		
		//phase = WIN, HEXs -> bot 1ST
		phase = WIN; @(posedge clk);
		
		
		
		//single player: human turn
		phase = INIT; game_mode = 0; player = 1'b0; repeat(2) @(posedge clk);
		
		//phase = SELECT, HEXs -> P1 turn
		phase = SELECT; @(posedge clk);
		
		//phase = ANIMATE, HEXs -> P1 turn
		phase = ANIMATE; @(posedge clk);
		
		//phase = COMMIT, HEXs -> P1 turn
		phase = COMMIT; @(posedge clk);
		
		//phase = CHECK, HEXs -> P1 turn
		phase = CHECK; @(posedge clk);
		
		//phase = WIN, HEXs -> P1 turn
		phase = WIN; @(posedge clk);
		
		
		//check for draw? in single player HEXs -> FULL
		phase = INIT; game_mode = 0; repeat(2) @(posedge clk);
		
		phase = DRAW; @(posedge clk);
		
		$stop;
		
	end
	
endmodule

		