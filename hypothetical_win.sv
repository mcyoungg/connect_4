
module hypothetical_win(hypo_win, board, row, col, color);
	
	output logic hypo_win;
	
	input logic [5:0][6:0][1:0] board;
	input logic [2:0] col, row;
	input logic [1:0] color;
	
	//copy input board and make hypothetical moves
	logic [5:0][6:0][1:0] test_board;
	
	//based on input row and column, we need to determine if making this move
	//will hypothetically result in a win, therefore we need to check all
	//directions from the current move
	
	integer start_r;
	integer start_c;
	
	always_comb begin
		
		test_board = board;
		test_board[row][col] = color;
		
		hypo_win = 1'b0;
		
		//horizontal check, check three 3 columns to the right and to the left 
		for(int k=0; k<4; k++) begin 
			
			//start from "window" furthest left
			start_c = col - k; 
			
			//check for edges
			if((start_c >= 0) && (start_c+3 < 7)) begin
				hypo_win |= &{test_board[row][start_c] == color,
						  test_board[row][start_c+1] == color,
						  test_board[row][start_c+2] == color,
						  test_board[row][start_c+3] == color};
				end
		 end
		 
		//vertical check, check three 3 row upwards and downwards
		for(int k=0; k<4; k++) begin 
			
			//start from "window" furthest down
			start_r = row - k; 
			
			//check for edges
			if((start_r >= 0) && (start_r+3 < 6)) begin
				hypo_win |= &{test_board[start_r][col] == color,
						  test_board[start_r+1][col] == color,
						  test_board[start_r+2][col] == color,
						  test_board[start_r+3][col] == color};
				end
		 end
		 
		 //diagonal check, lower left --> upper right
		 for(int k=0; k<4; k++) begin 
			
			//start from "window" furthest down and left
			start_r = row - k; 
			start_c = col - k; 
			
			//check for edges
			if((start_r >= 0) && (start_r+3 < 6) && (start_c >= 0) && (start_c+3 < 7)) begin
				hypo_win |= &{test_board[start_r][start_c] == color,
						  test_board[start_r+1][start_c+1] == color,
						  test_board[start_r+2][start_c+2] == color,
						  test_board[start_r+3][start_c+3] == color};
				end
		 end
		 
		 //diagonal check, lower right --> upper left
		 for(int k=0; k<4; k++) begin 
			
			//start from "window" furthest down and right
			start_r = row - k; 
			start_c = col + k; 
			
			//check for edges
			if((start_r >= 0) && (start_r+3 < 6) && (start_c-3 >= 0) && (start_c < 7)) begin
				hypo_win |= &{test_board[start_r][start_c] == color,
						  test_board[start_r+1][start_c-1] == color,
						  test_board[start_r+2][start_c-2] == color,
						  test_board[start_r+3][start_c-3] == color};
				end
		 end
	end
endmodule

module tb_hypothetical_win();

	logic hypo_win;
	
	logic [5:0][6:0][1:0] board;
	logic [2:0] col, row;
	logic [1:0] color;
	
	hypothetical_win uut (.hypo_win, .board, .row, .col, .color);
	
	parameter CLOCK_PERIOD = 100;
	logic clk;
	initial begin
	
		clk = 1'b0;
		board = '0;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
	end
	
	initial begin
		
		//horizontal win (green): 3 in a row --> hypo_win = 1 
		#50 for(int c=0; c<3; c++) board[0][c] = 2'b10;
		#10 row = 3'd0; #10 col = 3'd3; #10 color = 2'b10;
		
		//2 in a row --> hypo_win = 0
		#50 board[0][5] = 2'b01;
		#10 row = 3'd0; #10 col = 3'd6; #10 color = 2'b01;
		
		//testing vertical win --> winner (red)
		//hypo_win = 1
		#50 board = '0;
		for(int r=0; r<3; r++) board[r][2] = 2'b01;
		#10 row = 3'd3; #10 col = 3'd2; #10 color = 2'b01;
		
		//testing diagonal win up - right --> winner (green)
		//hypo_win = 1
		#50 board = '0;
		board[0][0] = 2'b10; board[1][1] = 2'b10; board[2][2] = 2'b10;
		#10 row = 3'd3; #10 col = 3'd3; #10 color = 2'b10;
		
		//testing diagonal win down - right --> winner (red)
		//hypo_win = 1
		#50 board = '0;
		board[5][0] = 2'b01; board[4][1] = 2'b01; board[3][2] = 2'b01;
		#10 row = 3'd2; #10 col = 3'd3; #10 color = 2'b01;
		
		#50 board = '0;
		
		#50 $stop;
	end
	
endmodule
		 
			
			
		