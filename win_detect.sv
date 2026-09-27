
module win_detect(board, win, win_mask);

	input logic [5:0][6:0][1:0] board;
	
	output logic win;
	output logic [5:0][6:0] win_mask; //find the location of the winning move
	
	//seperate the color positions
	logic [5:0][6:0] is_red, is_green;
	
	//accumulators for wins across windows
	logic red_win, green_win;
	
	always_comb begin
	
		for(int r=0; r<6; r++) begin
			for(int c=0; c<7; c++) begin
				is_red[r][c] = (board[r][c] == 2'b01);
				is_green[r][c] = (board[r][c] == 2'b10);
			end
		end
		
		red_win = 1'b0;
		green_win = 1'b0;
		win_mask = '0;
		
		//check horizontal wins
		for(int r=0; r<6; r++) begin
			for(int c=0; c<4; c++) begin
				if(&{is_red[r][c], is_red[r][c+1], is_red[r][c+2], is_red[r][c+3]}) begin
					red_win = 1'b1;
					win_mask[r][c] = 1'b1;   win_mask[r][c+1] = 1'b1;
					win_mask[r][c+2] = 1'b1; win_mask[r][c+3] = 1'b1;
				end
				
				if(&{is_green[r][c], is_green[r][c+1], is_green[r][c+2], is_green[r][c+3]}) begin
					green_win = 1'b1;
					win_mask[r][c] = 1'b1;   win_mask[r][c+1] = 1'b1;
					win_mask[r][c+2] = 1'b1; win_mask[r][c+3] = 1'b1;
				end
			end
		end
		
		//check vertical wins
		for(int r=0; r<3; r++) begin
			for(int c=0; c<7; c++) begin
				if(&{is_red[r][c], is_red[r+1][c], is_red[r+2][c], is_red[r+3][c]}) begin
					red_win = 1'b1;
					win_mask[r][c] = 1'b1;   win_mask[r+1][c] = 1'b1;
					win_mask[r+2][c] = 1'b1; win_mask[r+3][c] = 1'b1;
				end
				
				if(&{is_green[r][c], is_green[r+1][c], is_green[r+2][c], is_green[r+3][c]}) begin
					green_win = 1'b1;
					win_mask[r][c] = 1'b1;   win_mask[r+1][c] = 1'b1;
					win_mask[r+2][c] = 1'b1; win_mask[r+3][c] = 1'b1;
				end
			end
		end
		
		//check diagonal wins lower left to upper right
		for(int r=0; r<3; r++) begin
			for(int c=0; c<4; c++) begin
				if(&{is_red[r][c], is_red[r+1][c+1], is_red[r+2][c+2], is_red[r+3][c+3]}) begin
					red_win = 1'b1;
					win_mask[r][c] = 1'b1;     win_mask[r+1][c+1] = 1'b1;
					win_mask[r+2][c+2] = 1'b1; win_mask[r+3][c+3] = 1'b1;
				end
					
				if(&{is_green[r][c], is_green[r+1][c+1], is_green[r+2][c+2], is_green[r+3][c+3]}) begin
					green_win = 1'b1;
					win_mask[r][c] = 1'b1;     win_mask[r+1][c+1] = 1'b1;
					win_mask[r+2][c+2] = 1'b1; win_mask[r+3][c+3] = 1'b1;
				end
			end
		end
		
		//check diagonal wins upper left to lower right
		for(int r=3; r<6; r++) begin
			for(int c=0; c<4; c++) begin
				if(&{is_red[r][c], is_red[r-1][c+1], is_red[r-2][c+2], is_red[r-3][c+3]}) begin
					red_win = 1'b1;
					win_mask[r][c] = 1'b1;     win_mask[r-1][c+1] = 1'b1;
					win_mask[r-2][c+2] = 1'b1; win_mask[r-3][c+3] = 1'b1;
				end
					
				if(&{is_green[r][c], is_green[r-1][c+1], is_green[r-2][c+2], is_green[r-3][c+3]}) begin
					green_win = 1'b1;
					win_mask[r][c] = 1'b1;     win_mask[r-1][c+1] = 1'b1;
					win_mask[r-2][c+2] = 1'b1; win_mask[r-3][c+3] = 1'b1;
				end
			end
		end
	
		//evaluate
		win = red_win | green_win;
	end
	
endmodule

module tb_win_detect();

	logic [5:0][6:0][1:0] board;
	logic win;
	logic win_mask;
	
	win_detect uut (.board, .win);
	
	parameter CLOCK_PERIOD = 100;
	logic clk;
	
	initial begin
	
		clk = 1'b0;
		board = '0;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin
		
		//3 in a row --> win = 0
		#50 for(int c=0; c<3; c++) board[0][c] = 2'b10;
		
		//4 mixed in a row --> win = 0
		#50 board[0][3] = 2'b01;
		
		#50 board = '0;
		//testing horizontal win --> winner = 1 (green)
		 for(int c=0; c<4; c++) board[0][c] = 2'b10;
		
		#50 board = '0;
		//testing vertical win --> winner = 0 (red)
		for(int r=0; r<4; r++) board[r][2] = 2'b01;
		
		//testing diagonal win up - right --> winner = 1 (green)
		#50 board = '0;
		board[0][0] = 2'b10; board[1][1] = 2'b10; board[2][2] = 2'b10; board[3][3] = 2'b10;
		
		//testing diagonal win down - right --> winner = 0 (red)
		#50 board = '0;
		board[5][0] = 2'b01; board[4][1] = 2'b01; board[3][2] = 2'b01; board[2][3] = 2'b01;
		
		#50 board = '0;
		
		#50 $stop;
	end
	
endmodule
		
		
		
	
	

			
			
	