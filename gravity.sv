
module gravity(landing_row, col_full, board, sel_col);
	
	input logic [2:0] sel_col;
	input logic [5:0][6:0][1:0] board;
	
	output logic [2:0] landing_row;
	output logic col_full;
	
	always_comb begin
		if     (board[0][sel_col] == 2'b00) begin landing_row = 3'b000; col_full = 1'b0; end
		else if(board[1][sel_col] == 2'b00) begin landing_row = 3'b001; col_full = 1'b0; end
		else if(board[2][sel_col] == 2'b00) begin landing_row = 3'b010; col_full = 1'b0; end
		else if(board[3][sel_col] == 2'b00) begin landing_row = 3'b011; col_full = 1'b0; end
		else if(board[4][sel_col] == 2'b00) begin landing_row = 3'b100; col_full = 1'b0; end
		else if(board[5][sel_col] == 2'b00) begin landing_row = 3'b101; col_full = 1'b0; end
		else begin landing_row = 2'b00; col_full = 1'b1; end
	end
	
endmodule 

module tb_gravity();

	logic [2:0] sel_col;
	logic [5:0][6:0][1:0] board;
	
	logic [2:0] landing_row;
	logic col_full;
	
	gravity uut(.landing_row, .col_full, .board, .sel_col);
	
	parameter CLOCK_PERIOD = 100;
	logic clk;
	
	initial begin
	
		clk = 1'b0;
		board = '0;
		sel_col = 3'b000;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin
		//look at empty column
		sel_col = 3'b010; @(posedge clk); //landing row = 0, col_full = 0
		
		//look at partially full column
		board[0][2] = 2'b10;
		board[1][2] = 2'b10;
		board[2][2] = 2'b10;
		board[3][2] = 2'b01; 
		sel_col = 3'b010; @(posedge clk); //landing row = 4, col_full = 0
		
		
		//look at full column
		for(int r=0; r < 6; r++) board[r][3] = 2'b10;
		sel_col = 3'b011; @(posedge clk); //landing row = 0, col_full = 1
		
		$stop;
		
	end
	
endmodule
	
	