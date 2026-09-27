
module robo_move(robo_col, move_valid, board);

	output logic [2:0] robo_col;
	output logic move_valid;
	input logic [5:0][6:0][1:0] board;

	//uses robo eval as part a local determination for the next best move
	//based on the collective evaluations across the board
	//robo moves makes a decision:
	// --> 1) top priority is to make a wining move
	// --> 2) second priority is to make a blocking move (block another player's win)
	// --> 3) third priority is to make a move with center preference --> more opportunities to win
	
	//intermediate evaluation results from robo eval
	logic [6:0] green_win;
	logic [6:0] red_win;
	logic [6:0] col_full;

	//use genvar to create multiple instantiations of the same module
	genvar c;
	
	//evaluate all 7 columns in parallel
	generate
		for(c=0; c<7; c++) begin : ROBO_EVALS
			robo_eval eval (.green_win(green_win[c]), .red_win(red_win[c]), .col_full(col_full[c]), .board(board), .col(c));
		end
	endgenerate
	
	//prioritize move for center preference given muliple possible wins or blocks, if there are none of those, then,
	//place a valid move (everywhere where !col_full)
	logic win_found, block_found, norm_found;
	logic [2:0] win_sel, block_sel, norm_sel;
	
	robo_decide win_select (.sel_col(win_sel), .found(win_found), .candidates(green_win));
	robo_decide block_select (.sel_col(block_sel), .found(block_found), .candidates(red_win));
	robo_decide norm_select (.sel_col(norm_sel), .found(norm_found), .candidates(~col_full));
	
	//make final robo move, based on decision tree above
	always_comb begin
		move_valid = 1'b1;
		
		if(win_found) robo_col = win_sel;
		else if(block_found) robo_col = block_sel;
		else if(norm_found) robo_col = norm_sel;
		else begin //no valid move found! perhaps board is full
			move_valid = 1'b0;
			robo_col = 3'd0;
		end
	end
		
endmodule

module tb_robo_move();

	//out
	logic [2:0] robo_col;
	logic move_valid;
	
	//in
	logic [5:0][6:0][1:0] board;
	
	robo_move uut (.robo_col, .move_valid, .board);
	
	parameter CLOCK_PERIOD = 100;
	logic clk;
	initial begin
	
		clk = 1'b0;
		board = '0;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
	end
	
	initial begin
		
		//empty board, default move is center most preference
		//robo_col = 3, move_valid = 1
		
		#50 board = '0;
		
		//green has a possible win, robo takes the win
		//robo_col = 4, move_valid = 1
		#50 board = '0;
		board[0][1] = 2'b10;
		board[0][2] = 2'b10;
		board[0][3] = 2'b10;
		
		//red can win, robo blocks
		//robo_col = 2, move_valid = 1
		#50 board = '0;
		board[0][3] = 2'b01;
		board[0][4] = 2'b01;
		board[0][5] = 2'b01;
		
		//green and red can win, robo prioritizes winning
		//robo_col = 0, move_valid = 1
		#50 board = '0;
		
		board[0][0] = 2'b10;
		board[1][0] = 2'b10;
		board[2][0] = 2'b10;
		
		board[0][1] = 2'b01;
		board[0][2] = 2'b01;
		board[0][3] = 2'b01;
		
		//there is no winning or blocking move, center column full
		//robo_col = 2, move_valid = 1
		#50 board = '0;
		
		for(int r=0; r<6; r++) begin
			board[r][3] = (r%2) ? 2'b10 : 2'b01; //alternate colors to prevent a win in this column
		end
		
		//all columns full, checkerboard pattern, we are only checking if all cols are full
		//not so much if there is a win
		//robo_col = 0 (default), move_valid = 0
		#50 board = '0;
		for(int r=0; r<6; r++) begin
			for(int c=0; c<7; c++) begin
				board[r][c] = ((r+c)%2) ? 2'b10 : 2'b01; 
			end
		end
		
		#50 $stop;
		
	end
	
endmodule

