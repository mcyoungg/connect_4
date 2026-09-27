
// Top-level module that defines the I/Os for the DE-1 SoC board
module DE1_SoC (HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, SW, LEDR, GPIO_1, CLOCK_50);
    output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	 output logic [9:0]  LEDR;
	 
    input  logic [3:0]  KEY;
    input  logic [9:0]  SW;
    output logic [35:0] GPIO_1;
    input logic CLOCK_50;

	 //reset - toggle this on startup
	 logic RST;
	 assign RST = SW[9];
	 
	 
	 /* Set up system base clock to 1526 Hz (50 MHz / 2**(14+1))
	    ===========================================================*/
	 logic [31:0] clk;
	 logic SYSTEM_CLOCK;
	 
	 clock_divider divider (.clock(CLOCK_50), .reset(RST), .divided_clocks(clk));
	 /*FOR BOARD*/
	 assign SYSTEM_CLOCK = clk[14]; // 1526 Hz clock signal
	 
	 /*FOR SIM*/
	 //assign SYSTEM_CLOCK = CLOCK_50;
	 
	 //assigning blinking and falling clks
	 logic blink_clk, fall_clk, race_clk;
	 
	 /*FOR BOARD*/
	 assign blink_clk = clk[23]; //blinking column cursor is disabled in favor of seeing clean left and right movement
	 assign fall_clk = clk[22];
	 assign race_clk = clk[20];
	 
	 /*FOR SIM*/
	 //assign blink_clk = clk[5];
	 //assign fall_clk = clk[3];
	 //assign race_clk = clk[2];
	 
	 /* If you notice flickering, set SYSTEM_CLOCK faster.
	    However, this may reduce the brightness of the LED board. */
		 
	/* Determine game mode single player (0) or multiplayer (1)
	    ================================================================== */
		logic game_mode;
		
		mode_latch mode (.multiplayer(game_mode), .mode_switch(SW[8]), .clk(SYSTEM_CLOCK), .reset(RST));
	 
	 /* Set up LED board driver
	    ================================================================== */
	 logic [15:0][15:0]RedPixels; // 16 x 16 array representing red LEDs
    logic [15:0][15:0]GrnPixels; // 16 x 16 array representing green LEDs
	 
	 /* Standard LED Driver instantiation - set once and 'forget it'. 
	    See LEDDriver.sv for more info. Do not modify unless you know what you are doing! */
	 LEDDriver Driver (.CLK(SYSTEM_CLOCK), .RST, .EnableCount(1'b1), .RedPixels, .GrnPixels, .GPIO_1);
	 
	 
	 /* User input stabalizing and conditioning
		 =================================================================== */
	 //for left
	 logic left_ff, left_lvl, left_p;
	 d_ff L1 (.q(left_ff), .d(KEY[2]), .clk(SYSTEM_CLOCK), .reset(RST));
	 d_ff L2 (.q(left_lvl), .d(left_ff), .clk(SYSTEM_CLOCK), .reset(RST));
	 
	 //for select
	 logic sel_ff, sel_lvl, sel_p;
	 d_ff S1 (.q(sel_ff), .d(KEY[1]), .clk(SYSTEM_CLOCK), .reset(RST));
	 d_ff S2 (.q(sel_lvl), .d(sel_ff), .clk(SYSTEM_CLOCK), .reset(RST));
	 
	 //for right
	 logic right_ff, right_lvl, right_p;
	 d_ff R1 (.q(right_ff), .d(KEY[0]), .clk(SYSTEM_CLOCK), .reset(RST));
	 d_ff R2 (.q(right_lvl), .d(right_ff), .clk(SYSTEM_CLOCK), .reset(RST));	 
	 
	 //sync one pulse to clock
	 logic left, select, right;	 
	 user_input uin_L (.out(left_p), .in(left_lvl), .clk(SYSTEM_CLOCK), .reset(RST));
	 user_input uin_S (.out(sel_p), .in(sel_lvl), .clk(SYSTEM_CLOCK), .reset(RST));
	 user_input uin_R (.out(right_p), .in(right_lvl), .clk(SYSTEM_CLOCK), .reset(RST));
	 
	 //clean presses
	 clean_inputs clean (.c_left(left), .c_right(right), .c_select(select), .lvl_left(left_lvl), .lvl_right(right_lvl), .lvl_select(sel_lvl), .p_left(left_p), .p_right(right_p), .p_select(sel_p));
	 
	 /* CONTROLLER FSM, main game organization logic
	    =================================================================== */	 
	 logic robo_select;
	 logic robo_turn;
	 logic move_valid;
	 logic game_select;
	 logic [2:0] game_sel_col;
	 
	 logic col_full;
	 logic win;
	 logic board_full;
	 logic anim_done;
	 logic [5:0][6:0][1:0] board;
	 
	 logic sel_en;
	 logic toggle;
	 logic anim_start;
	 logic wr_en;
	 logic [2:0] phase;
	 
	 logic [5:0][6:0] win_mask; //flash wining move
	 
	 //robo needs to mimick a human select button press to activate the game controller
	 assign robo_select = robo_turn && move_valid && sel_en;
	 assign game_select = robo_turn ? robo_select : select;
	 
	 controller control (.sel_en(sel_en), .toggle(toggle), .anim_start(anim_start), .wr_en(wr_en), .phase(phase),
						      .clk(SYSTEM_CLOCK), .reset(RST), .select(game_select), .col_full(col_full), .anim_done(anim_done),
						      .win(win), .board_full(board_full));
	
	 
	 /* Player tracker - who is playing right now
	    =================================================================== */
	 logic player; //0:P1, 1:P2
	 player_tracker pt (.player(player), .toggle(toggle), .clk(SYSTEM_CLOCK), .reset(RST));
	 
	 /* Robo player - for single player mode (green player) -> 1
	    =================================================================== */
	 logic [2:0] robo_sel_col;
	 logic [2:0] human_sel_col;
	 assign robo_turn = !game_mode && player;
	 robo_move robo (.robo_col(robo_sel_col), .move_valid(move_valid), .board(board));
	 
	 //multiplex based on game_mode the current column selection
	 
	 assign game_sel_col = robo_turn ? robo_sel_col : human_sel_col;
	 /* Column cursor - column selection, exclusively monitors human col selection
	    =================================================================== */
	 column_tracker ct (.sel_col(human_sel_col), .left(left), .right(right), .en(sel_en && !robo_turn), .clk(SYSTEM_CLOCK), .reset(RST));
	 //during robo turn do not let inputs on human cursor change
	 
	 /* Gravity - lowest available row from selected column
	    =================================================================== */
	 logic [2:0] landing_row;
	 gravity grav (.landing_row(landing_row), .col_full(col_full), .board(board), .sel_col(game_sel_col));
	
	 
	 /* Board - playing field
	    =================================================================== */
	 logic [1:0] cur_color;
	 assign cur_color = player ? 2'b10: 2'b01;
	 board_state bstate (.board(board), .wr_col(game_sel_col), .wr_row(landing_row), .wr_color(cur_color), .wr_en(wr_en), .clk(SYSTEM_CLOCK), .reset(RST));
	 
	 
	 /* Animation - falling piece
	    =================================================================== */
	 logic [2:0] anim_row;
	 animation anim (.curr_row(anim_row), .anim_done(anim_done), .landing_row(landing_row), .start(anim_start), .slow_clk(fall_clk), .clk(SYSTEM_CLOCK), .reset(RST));
	 
	 
	 /* WIN and DRAW detection - falling piece
	    =================================================================== */
	 win_detect wdet (.board(board), .win(win), .win_mask(win_mask));
	 draw_detect ddet (.board_full(board_full), .commit(wr_en), .clk(SYSTEM_CLOCK), .reset(RST));
	 
	 
	 /* LED Matrix Mapper - code driving RedPixels and GrnPixels
		 =================================================================== */
	 led_mapper led_map (.RedPixels(RedPixels), .GrnPixels(GrnPixels), .board(board), .curr_row(anim_row), .sel_col(game_sel_col), .player(player), .phase(phase), .blink(blink_clk), .win_mask(win_mask));
	 
	  
	 /* Hex Mapping
		 =================================================================== */
	 hex_display hex_disp (.HEX5(HEX5), .HEX4(HEX4), .HEX3(HEX3), .HEX2(HEX2), .HEX1(HEX1), .HEX0(HEX0), .phase(phase), .player(player), .game_mode(game_mode));
	 
	  /* LEDR Racing
		 =================================================================== */
	 led_racer race (.LEDR(LEDR), .phase(phase), .tick(race_clk), .clk(SYSTEM_CLOCK),. reset(RST));
	 
endmodule


module tb_DE1_SoC();
	
	//out
	logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	logic [9:0]  LEDR;
	 
	//in
   logic [3:0]  KEY;
   logic [9:0]  SW;
   logic [35:0] GPIO_1;
   logic CLOCK_50;
	
	DE1_SoC uut (.HEX0, .HEX1, .HEX2, .HEX3, .HEX4, .HEX5, .KEY, .SW, .LEDR, .GPIO_1, .CLOCK_50);
	
	//Set up a simulated clock. 
	parameter CLOCK_PERIOD=100; 
	initial begin 
		CLOCK_50 <= 0; 
		forever #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50; // Forever toggle the clock
	end
		
	// Test the design. 
	initial begin 
		//reset input keys
		KEY = 4'b1111; //released
		SW = 10'b0;
		
		//=========================================================================
		//MULTIPLAYER GAME PLAY TEST: P1 WINS
		//=========================================================================
		
		//reset, choose multiplayer, phase = INIT --> SELECT
		SW[9] <= 1'b1; SW[8] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		SW[9] <= 1'b0; repeat(1) @(posedge CLOCK_50);
		
		repeat(3) begin
			//P1 TURN: walks left, cursor clamps, will choose to stack in col0
			repeat(6) begin
				KEY[2] <= 1'b0; repeat(4) @(posedge CLOCK_50);
				KEY[2] <= 1'b1; repeat(4) @(posedge CLOCK_50);
			end
			//P1 makes a selection
			KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		
			repeat(120) @(posedge CLOCK_50);
			
			//P2 TURN: walks right, will choose to stack in col6
			repeat(6) begin
				KEY[0] <= 1'b0; repeat(4) @(posedge CLOCK_50);
				KEY[0] <= 1'b1; repeat(4) @(posedge CLOCK_50);
			end
			//P2 makes a selection
			KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
			
			repeat(120) @(posedge CLOCK_50);
		end
		
		//P1 TURN: walks left, will choose to stack in col0
		repeat(6) begin
			KEY[2] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[2] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		end
		//P1 TURN: final move to WIN, HEX HOLDS -> P1 1ST
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		
		repeat(120) @(posedge CLOCK_50);
		
		//RESET
		SW[9] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		SW[9] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		
		//=========================================================================
		//MULTIPLAYER GAME PLAY TEST: P2 WINS
		//=========================================================================
		
		//P1 TURN: will choose col0
		repeat(6) begin
			KEY[2] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[2] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		end
		//P1 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(120) @(posedge CLOCK_50);
		
		//P2 TURN: walks right, will choose to stack in col4
		repeat(4) begin
			KEY[0] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[0] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		end
		//P2 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(120) @(posedge CLOCK_50);
		
		//P1 TURN: will choose col1
		repeat(3) begin
			KEY[2] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[2] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		end
		//P1 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(120) @(posedge CLOCK_50);
		
		//P2 TURN: walks right, will choose to stack in col4
		repeat(3) begin
			KEY[0] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[0] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		end
		//P2 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(120) @(posedge CLOCK_50);
		
		//P1 TURN: will choose col0
		repeat(6) begin
			KEY[2] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[2] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		end
		//P1 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(120) @(posedge CLOCK_50);
		
		//P2 TURN: walks right, will choose to stack in col4
		repeat(4) begin
			KEY[0] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[0] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		end
		//P2 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(120) @(posedge CLOCK_50);
		
		//P1 TURN: will choose col1
		repeat(3) begin
			KEY[2] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[2] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		end
		//P1 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(120) @(posedge CLOCK_50);
		
		//P2 TURN: walks right, will choose to stack in col4
		//P2 TURN: final move to WIN, HEX HOLDS -> P2 1ST
		repeat(3) begin
			KEY[0] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[0] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		end
		//P2 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(120) @(posedge CLOCK_50);
		
		
		//=========================================================================
		//SINGLE PLAYER GAME PLAY TEST: BOT BLOCKS POSSIBLE P1 WIN
		//=========================================================================
		
		//reset, choose single player, phase = INIT --> SELECT
		SW[9] <= 1'b1; SW[8] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		SW[9] <= 1'b0; repeat(1) @(posedge CLOCK_50);
		
		repeat(3) begin
			//P1 TURN: walks left, cursor clamps, will choose to stack in col0
			repeat(6) begin
				KEY[2] <= 1'b0; repeat(4) @(posedge CLOCK_50);
				KEY[2] <= 1'b1; repeat(4) @(posedge CLOCK_50);
			end
			//P1 makes a selection
			KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		
			repeat(240) @(posedge CLOCK_50); //give robot enough time to decide (prob doesnt need it tbh)
														//HERE we should observe the HEX displays going between the bot
														//and P1
														//BOT blocks winning move
		end
		
				
		//=========================================================================
		//SINGLE PLAYER GAME PLAY TEST: P1 WIN
		//=========================================================================
		
		SW[9] <= 1'b1; SW[8] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		SW[9] <= 1'b0; repeat(1) @(posedge CLOCK_50);
		
		//P1 walks right col0 -> col3
		repeat(3) begin
			KEY[0] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[0] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		end
		//P1 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(240) @(posedge CLOCK_50); //wait for bot, chooses col3 (default)
		
		//P1 move from col3 to 1
		repeat(2) begin
			KEY[2] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[2] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		end
		
		//P1 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(240) @(posedge CLOCK_50); //wait for bot chooses col3 (default)
		
		//P1 turn, go to column 2
		KEY[0] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[0] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		//P1 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(240) @(posedge CLOCK_50); //wait for bot, bot recognizes threat, chooses col4
		
		//P1 move from col2 to 0
		repeat(2) begin
			KEY[2] <= 1'b0; repeat(4) @(posedge CLOCK_50);
			KEY[2] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		end
		//P1 makes a selection and wins: HEX = P11ST
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(240) @(posedge CLOCK_50);
		
		//=========================================================================
		//SINGLE PLAYER GAME PLAY TEST: BOT WIN
		//=========================================================================
		
		SW[9] <= 1'b1; SW[8] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		SW[9] <= 1'b0; repeat(1) @(posedge CLOCK_50);
		
		//P1 TURN: walks left, cursor clamps, will col0
			repeat(6) begin
				KEY[2] <= 1'b0; repeat(4) @(posedge CLOCK_50);
				KEY[2] <= 1'b1; repeat(4) @(posedge CLOCK_50);
			end
		//P1 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(240) @(posedge CLOCK_50); //wait for bot chooses col3 (default)
		
		//P1 makes a selection again in col0
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(240) @(posedge CLOCK_50); //wait for bot chooses col3 (default)
		
		//P1 TURN: walks right col0 -> col1
		KEY[0] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[0] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		//P1 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(240) @(posedge CLOCK_50); //wait for bot chooses col3 (default)
		
		//P1 TURN: walks left col1 -> col0
		KEY[2] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[2] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		//P1 makes a selection
		KEY[1] <= 1'b0; repeat(4) @(posedge CLOCK_50);
		KEY[1] <= 1'b1; repeat(4) @(posedge CLOCK_50);
		repeat(240) @(posedge CLOCK_50); //wait for bot chooses col3 prioritzing winning
													//over the treat of P1 stacking red in col0!
													//HEX -> BOT1ST
		
		$stop;
		
	end
	
endmodule


