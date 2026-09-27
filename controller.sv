
module controller(
	output logic sel_en, //enable cursor
	output logic toggle, //change player
	output logic anim_start, //begin falling animation
	output logic wr_en, //enable write to game board
	output logic [2:0] phase, //current state in controller fsm for LEDs and HEX
	
	input logic clk, reset,
	input logic select, //user inputs
	input logic col_full, //check is chosen column is full
	input logic anim_done, //check if animation is done to move to next state or not
	input logic win, //win detection
	input logic board_full //results in draw state
);

	enum logic [2:0] {INIT, SELECT, ANIMATE, COMMIT, CHECK, WIN, DRAW} state, next_state;
	
	assign phase = state;
	
	//next state logic
	always_comb begin
		//default values
		sel_en = 1'b0;
		wr_en = 1'b0;
		anim_start = 1'b0;
		toggle = 1'b0;
		
		case(state)
			INIT: next_state = SELECT;
			
			SELECT: begin
				sel_en = 1'b1;
				if(select && !col_full) begin
					anim_start = 1'b1;
					next_state = ANIMATE;
				end
				else next_state = SELECT;
			end
			
			ANIMATE: begin
				if(anim_done) next_state = COMMIT;
				else next_state = ANIMATE;
			end
			
			COMMIT: begin
				wr_en = 1'b1;
				next_state = CHECK;
			end
			
			CHECK: begin
				if(win) next_state = WIN;
				else if(board_full) next_state = DRAW;
				else begin
					toggle = 1'b1;
					next_state = SELECT;
				end
			end
			
			WIN: next_state = WIN;
			
			DRAW: next_state = DRAW;
			
			default: next_state = INIT;
		endcase
	end
	
	//store next state, compute present state
	always_ff @(posedge clk) begin
		if(reset) state <= INIT;
		else state <= next_state;	
	end

endmodule

module tb_controller();

	//outputs
	logic sel_en;
	logic toggle;
	logic anim_start;
	logic wr_en;
	logic [2:0] phase;
	
	//inputs
	logic clk, reset;
	logic select;
	logic col_full;
	logic anim_done;
	logic win;
	logic board_full;
	
	controller uut (.sel_en, .toggle, .anim_start, .wr_en, .phase,
						 .clk, .reset, .select, .col_full, .anim_done,
						 .win, .board_full
						 );
	
	parameter CLOCK_PERIOD = 100;
	
	initial begin
	
		clk = 1'b0;
		reset = 1'b0;
		select = 1'b0;
		col_full = 1'b0;
		anim_done = 1'b0;
		win = 1'b0;
		board_full = 1'b0;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin
	
		//turn 1 reset, FSM to INIT
		reset <= 1'b1; repeat(2) @(posedge clk);
		reset <= 1'b0; @(posedge clk);
		
		//reject a full column, stay in SELECT
		col_full <= 1'b1; @(posedge clk);
		select <= 1'b1;   @(posedge clk);
		select <= 1'b0;	@(posedge clk);
		col_full <= 1'b0; @(posedge clk);
		
		//make a valid selection, go to ANIMATE
		select <= 1'b1;   @(posedge clk);
		select <= 1'b0;	@(posedge clk);
		
		repeat(4) @(posedge clk);
		
		//finish animation, anim_done asserted go to COMMIT
		anim_done <= 1'b1; @(posedge clk);
		anim_done <= 1'b0; @(posedge clk);
		
		//COMMIT done -> move to CHECK, wait, theres no win, set toggle -> switch player
		@(posedge clk);
		
		//should be back to SELECT make next turn starting from SELECT
		
		//turn 2, repeat then WIN, player 2
		select <= 1'b1;   @(posedge clk); //SELECT
		select <= 1'b0;	@(posedge clk);
		repeat(4) @(posedge clk); //ANIMATE
		anim_done <= 1'b1; @(posedge clk);
		anim_done <= 1'b0; //COMMIT
		//win in same clock cycle, win detection combinational when move is commited to board
		win <= 1'b1; @(posedge clk);
		@(posedge clk); //CHECK -> WIN
		win <= 1'b0; repeat(4) @(posedge clk); //WIN should hold
		
		//turn 3 reset FSM to INIT, turn ends in DRAW, player 1
		reset <= 1'b1; repeat(2) @(posedge clk); //INIT
		reset <= 1'b0; @(posedge clk);
		
		select <= 1'b1;   @(posedge clk); //SELECT
		select <= 1'b0;	@(posedge clk);
		repeat(4) @(posedge clk); //ANIMATE
		anim_done <= 1'b1; @(posedge clk);
		anim_done <= 1'b0;  //COMMIT
		board_full <= 1'b1; @(posedge clk);
		@(posedge clk); //CHECK -> DRAW
		board_full <= 1'b0; repeat(4) @(posedge clk); //DRAW should hold
		
		$stop;
	
	end
	
endmodule
