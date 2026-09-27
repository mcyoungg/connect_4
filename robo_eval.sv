
module robo_eval(green_win, red_win, col_full, board, col);

	output logic green_win;
	output logic red_win;
	output logic col_full;
	
	input logic [5:0][6:0][1:0] board;
	input logic [2:0] col;
	
	
	logic [2:0] landing_row;
	logic hypo_green_win, hypo_red_win;
	
	//find valid landing row based on selected col
	gravity grav (.landing_row(landing_row), .col_full(col_full), .board(board), .sel_col(col));
	
	//check if robo can win
	hypothetical_win check_green (.hypo_win(hypo_green_win), .board(board), .row(landing_row), .col(col), .color(2'b10));
	
	//check if robo can block
	hypothetical_win check_red (.hypo_win(hypo_red_win), .board(board), .row(landing_row), .col(col), .color(2'b01));
	
	assign green_win = hypo_green_win && !col_full;
	assign red_win = hypo_red_win && !col_full;
	
endmodule

module tb_robo_eval();
	
	//out
	logic green_win;
	logic red_win;
	logic col_full;
	
	//in
	logic [5:0][6:0][1:0] board;
	logic [2:0] col;
	
	robo_eval r_eval (.green_win, .red_win, .col_full, .board, .col);
	
	parameter CLOCK_PERIOD = 100;
	logic clk;
	
	initial begin
		clk = 1'b0;
		board = '0;
		col = 3'd0;
		forever #(CLOCK_PERIOD/2) clk = ~clk;
	end
	
	initial begin
	
		//horizontal win (green): 3 in a row --> green_win = 1 
		#100 for(int c=0; c<3; c++) board[0][c] = 2'b10;
		#10 col = 3'd3;
		
		//2 in a row --> no wins, no connecting 4 for either color
		#100 board[0][5] = 2'b01;
		#10 col = 3'd6;
		
		//testing vertical win --> winner (red)
		//red_win = 1
		#100 board = '0;
		for(int r=0; r<3; r++) board[r][2] = 2'b01;
		#10 col = 3'd2; 
		
		//testing diagonal win up - right --> no winner, landing row = 0;
		//piece falls to the bottom since there is no "support"
		#100 board = '0;
		board[0][0] = 2'b10; board[1][1] = 2'b10; board[2][2] = 2'b10;
		#10 col = 3'd3; 
		
		//testing diagonal win down - right --> no winner, landing row = 0;
		//piece falls to the bottom since there is no "support"
		#100 board = '0;
		board[5][0] = 2'b01; board[4][1] = 2'b01; board[3][2] = 2'b01;
		#10 col = 3'd3;
		
		//testing valid move, col_full = 1, no wins, cant make a valid move here
		#100 board = '0;
		for(int r=0; r<5; r++) board[r][4] = 2'b01; board[5][4] = 2'b10;
		#10 col = 3'd4; 
		
		
		#100 $stop;
	
	end
endmodule


	
	

