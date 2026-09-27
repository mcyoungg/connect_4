
module robo_decide(sel_col, found, candidates);
	
	output logic [2:0] sel_col;
	output logic found;
	
	input logic [6:0] candidates;
	
	//based on the multiple possible wins in each column from candidates
	//we prioritze center columns to make the robo column selection
	
	always_comb begin
		sel_col = 3'd0;
		found = 1'b1;
		
		//start from center and branch out
		if(candidates[3]) sel_col = 3'd3;
		else if(candidates[2]) sel_col = 3'd2;
		else if(candidates[4]) sel_col = 3'd4;
		else if(candidates[1]) sel_col = 3'd1;
		else if(candidates[5]) sel_col = 3'd5;
		else if(candidates[0]) sel_col = 3'd0;
		else if(candidates[6]) sel_col = 3'd6;
		
		//no valid moves are found!
		else begin
			sel_col = 3'd0;
			found = 1'b0;
		end
	end
endmodule

module tb_robo_decide();
	
	//out
	logic [2:0] sel_col;
	logic found;
	
	//in
	logic [6:0] candidates;
	
	robo_decide uut (.sel_col, .found, .candidates);
	
	parameter CLOCK_PERIOD = 100;
	logic clk;
	initial begin
	
		clk = 1'b0;
		candidates = '0;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
	end
	
	initial begin
		//no candidates
		//sel_col = 0, found = 0
		#50 candidates = '0;
		
		//center only
		//sel_col = 3, found = 1
		#50 candidates = '0;
		#5 candidates[3] = 1;
		
		//edge only
		//sel_col = 6, found = 1
		#50 candidates = '0;
		#5 candidates[6] = 1;
		
		//multiple candidates including center
		//sel_col = 3, found = 1
		#50 candidates = '0;
		#5 candidates[3] = 1;
		#5 candidates[2] = 1;
		#5 candidates[4] = 1;
		
		//multiple candidaes without center
		//sel_col = 2, found = 1
		#50 candidates = '0;
		#5 candidates[5] = 1;
		#5 candidates[2] = 1;
		#5 candidates[4] = 1;
		
		//all candidates
		//sel_col = 3, found = 1
		#50 candidates = 7'b1111111;
		
		#50 $stop;
		
	end
endmodule
	
	