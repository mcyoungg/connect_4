
module led_mapper(RedPixels, GrnPixels, board, curr_row, sel_col, player, phase, blink, win_mask);

	output logic [15:0][15:0] RedPixels;
	output logic [15:0][15:0] GrnPixels;
	
	input logic [5:0][6:0][1:0] board;
	input logic [2:0] curr_row; //from animation, current row to light for falling piece
	input logic [2:0] sel_col;
	input logic player; //current player, 0:P1 (2'b01 -> red), 1:P2 (2'b10 -> green)
	input logic [2:0] phase; //current state from controller
	input logic blink; //tick that is passed through to light flashing column selection
	input logic [5:0][6:0] win_mask; //bits that resulted in the winning move
	
	//map phase bits back to states from controller
	localparam [2:0] SELECT = 3'b001; 
	localparam [2:0] ANIMATE = 3'b010; 
	localparam [2:0] WIN = 3'b101; 
	
	//need to map board coordinates to the actual LED matrix
	//shift 5 rows to center it on led matrix
	//shift 4 columns to center it on the led matrix
	logic [3:0] dr, dc;
	
	//take note of the current player assigned color
	logic [1:0] cur_color;
	assign cur_color = player ? 2'b10: 2'b01;
	
	//loop variables
	integer r,c;
	
	always_comb begin
		RedPixels = '0;
		GrnPixels = '0;
		
		//draw the existing settled pieces on the board shifted to led matrix
		for(r=0; r<6; r++) begin
			for(c=0; c<7; c++) begin
				dr = 4'(10-r);
				dc = 4'(11-c);
				
				if(board[r][c] == 2'b01) RedPixels[dr][dc] = 1'b1;
				else if(board[r][c] == 2'b10) GrnPixels[dr][dc] = 1'b1;
			end
		end
		
		//if the state is SELECT, create a cursor
		if(phase == SELECT) begin 
		
			dr = 4; //one row above playable field
			dc = 4'(11-sel_col);
			
			if(cur_color == 2'b10) GrnPixels[dr][dc] = 1'b1;
			else RedPixels[dr][dc] = 1'b1;
		end
		
		//if the state is ANIMATE, turn on currently selected row and column
		//the freuqency at which the curr_row changes is done in animation
		if(phase == ANIMATE) begin
			
			dr = 4'(10-curr_row);
			dc = 4'(11-sel_col);
			
			if(cur_color == 2'b10) GrnPixels[dr][dc] = 1'b1;
			else RedPixels[dr][dc] = 1'b1;
		end
		
		//if the state is WIN, flash the winning move
		if(phase == WIN) begin
			for(r=0; r<6; r++) begin
				for(c=0; c<7; c++) begin
					if(win_mask[r][c]) begin
						dr = 4'(10-r);
						dc = 4'(11-c);
						//flash or blink on when blink=1, off when blink=0
							if(blink) begin
								//flash the wininng cell in its own color
								if(board[r][c] == 2'b01) RedPixels[dr][dc] = 1'b1;
								else if(board[r][c] == 2'b10) GrnPixels[dr][dc] = 1'b1;
							end
							else begin
								RedPixels[dr][dc] = 1'b0;
								GrnPixels[dr][dc] = 1'b0;
							end
					end
				end
			end
		end
						
		//boarder yellow-orange outline, U shape
		for(r=5; r<=11; r++) begin 
		//left wall
			RedPixels[r][12] = 1'b1; GrnPixels[r][12] = 1'b1;
		//right wall
			RedPixels[r][4] = 1'b1; GrnPixels[r][4] = 1'b1;
		end
		
		//lower wall
		for(c=4; c<=12; c++) begin
			RedPixels[11][c] = 1'b1; GrnPixels[11][c] = 1'b1;
		end
	end

endmodule

module tb_led_mapper();
	//out
	logic [15:0][15:0] RedPixels;
	logic [15:0][15:0] GrnPixels;
	
	//in
	logic [5:0][6:0][1:0] board;
	logic [2:0] curr_row;
	logic [2:0] sel_col;
	logic player;
	logic [2:0] phase;
	logic blink;
	logic [5:0][6:0] win_mask;
	
	led_mapper uut (.RedPixels, .GrnPixels, .board, .curr_row, .sel_col, .player, .phase, .blink, .win_mask);
	
	localparam [2:0] INIT = 3'd0;
	localparam [2:0] SELECT = 3'd1;
	localparam [2:0] ANIMATE = 3'd2;
	localparam [2:0] WIN = 3'd5;
	
	parameter CLOCK_PERIOD = 100;
	logic clk;
	
	initial begin
	
		clk = 1'b0;
		
		board = '0;
		win_mask = '0;
		curr_row = 3'd0;
		sel_col = 3'd0;
		player = 1'b0;
		blink = 1'b0;
		phase = INIT;

		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin
	
		//phase = INIT, empty board with clear orange outline?
		repeat(2) @(posedge clk);
		
		//mapping of board pieces [r][c] to red and green led matricies[10-r][11-4]
		board[0][0] = 2'b10;
		board[1][0] = 2'b10; 
		
		board[0][5] = 2'b01;
		board[1][5] = 2'b01; 
		repeat(2) @(posedge clk);
		
		//blinking cursor during phase = SELECT, player 1 turn (red)
		phase = SELECT;
		sel_col = 3'd2;
		repeat(3) begin
			blink = 1'b1; @(posedge clk); 
			blink = 1'b0; @(posedge clk);
		end
		
		// cursor during phase = SELECT, player 2 turn (green) 
		sel_col = 3'd5;
		player = 1'b1;
		
		 @(posedge clk);
		 
		//recreate falling piece during phase = ANIMATE, cursor gone
		phase = ANIMATE;
		
		curr_row = 3'd5; @(posedge clk);
		curr_row = 3'd3; @(posedge clk); 
		curr_row = 3'd0; @(posedge clk); 
		
		//nothing should happen in phase = WIN, only current settled pieces and outline
		//animation piece is not commited here, only simulated as falling
		board = '0;
		board[0][0] = 2'b10; board[0][1] = 2'b10;
		board[0][2] = 2'b10; board[0][3] = 2'b10;
		
		win_mask = '0;
		win_mask[0][0] = 1'b1; win_mask[0][1] = 1'b1;
		win_mask[0][2] = 1'b1; win_mask[0][3] = 1'b1;
		
		//create a blink, should see wining move go high and low based on blink
		repeat(3) begin
			blink = 1'b1; @(posedge clk);
			blink = 1'b0; @(posedge clk);
		end
		
		
		$stop;
		
	end
	
endmodule
	
		