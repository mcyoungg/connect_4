
module board_state(board, wr_col, wr_row, wr_color, wr_en, clk, reset);

	input logic [2:0] wr_col, wr_row;
	input logic [1:0] wr_color;
	input logic wr_en, clk, reset;
	
	output logic [5:0][6:0][1:0] board;
	
	always_ff @(posedge clk) begin
	
		if (reset) board <= '0; //zero the whole board, the width is dynmaically allocated
		
		else if (wr_en) board[wr_row][wr_col] <= wr_color; //write in specified color to the board 
		
		else board <= board; //hold the current state
		
	end
	
endmodule

module tb_board_state();

	logic [2:0] wr_col, wr_row;
	logic [1:0] wr_color;
	logic wr_en, clk, reset;
	
	logic [5:0][6:0][1:0] board;
	
	
	board_state uut (.board, .wr_col, .wr_row, .wr_color, .wr_en, .clk, .reset);
	
	parameter CLOCK_PERIOD = 100;
	
	initial begin
	
		clk = 0;
		wr_col = 3'b000;
		wr_row = 3'b000;
		wr_en = 0;
		wr_color = 2'b00;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin
	
		reset <= 1; 		   repeat(2) @(posedge clk);
		
		reset <= 0;				@(posedge clk);
		
		wr_row <= 3'b100; wr_col <= 3'b010; wr_color <= 2'b10; repeat(3) @(posedge clk);
		
		//assert enable, board is written to by color indiciated, green
		wr_en <= 1;				@(posedge clk);
		
		wr_en <= 0; 			@(posedge clk);
		
		//red
		wr_row <= 3'b101; wr_col <= 3'b011; wr_color <= 2'b01; repeat(3) @(posedge clk);
		
		wr_en <= 1;				@(posedge clk);
		
		wr_en <= 0; 			@(posedge clk);
		
		$stop;
	end
	
endmodule
		
		
	
	