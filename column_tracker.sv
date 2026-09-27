
module column_tracker(sel_col, left, right, en, clk, reset);
	
	input logic left, right, en, clk, reset;
	
	output logic [2:0] sel_col;
	
	//logic to increment or decrement the counter
	logic inc, dec;
	
	assign inc = en & ~left & right;
	assign dec = en & left & ~right; 
	
	//must apply with clamp
	always_ff @(posedge clk) begin 
		if(reset) sel_col <= 3'b000;
		
		else if(inc && sel_col < 3'd6) sel_col <= sel_col + 1'b1;
		
		else if(dec && sel_col > 3'd0) sel_col <= sel_col - 1'b1;
		
		else sel_col <= sel_col;
		
	end

endmodule

module tb_column_tracker();

	logic left, right, en, clk, reset;
	logic [2:0] sel_col;
	
	column_tracker uut (.sel_col, .left, .right, .en, .clk, .reset);
	
	
	parameter CLOCK_PERIOD = 100;
	
	initial begin
	
		clk = 1'b0;
		left = 1'b0;
		right = 1'b0;
		en = 1'b0;
		reset = 1'b0;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin
	
		reset <= 1'b1; repeat(2) @(posedge clk);
		
		reset <= 0;	   @(posedge clk);
		
		en = 1'b1;		@(posedge clk);
		
		//moving all the way to right testing clamp
		repeat(6) begin
			right <= 1'b1; @(posedge clk);
			right <= 1'b0; @(posedge clk);
		end
		right <= 1'b1; @(posedge clk);
		right <= 1'b0; @(posedge clk);
		
		//moving all the way to the left testing clamp
		repeat(6) begin
			left <= 1'b1; @(posedge clk);
			left <= 1'b0; @(posedge clk);
		end
		left <= 1'b1;	  @(posedge clk);
		left <= 1'b0; @(posedge clk);
		
		//testing enable
		en = 1'b0;		@(posedge clk);
		
		right <= 1'b1; @(posedge clk);
		right <= 1'b0; @(posedge clk);
			
		left <= 1'b1;  @(posedge clk);
		left <= 1'b0;  @(posedge clk);
		
		//testing hold conditions
		en = 1'b1;		@(posedge clk);
		right <= 1'b1; left <= 1'b1; @(posedge clk);
		right <= 1'b0; left <= 1'b0; @(posedge clk);
		
		$stop;
	end
	
endmodule
		
		
		
	