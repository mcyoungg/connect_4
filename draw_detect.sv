
module draw_detect(board_full, commit, clk, reset);

	output logic board_full;
	
	input logic commit, clk, reset;
	
	logic [5:0] count;
	
	always_ff @(posedge clk) begin
		if(reset) count <= 6'd0;
		else if(commit && count < 6'd42) count <= count + 1'b1;
		else count <= count;
	end
	
	assign board_full = (count == 6'd42);

endmodule

module tb_draw_detect();

	logic board_full;
	logic commit, clk, reset;
	
	draw_detect uut (.board_full, .commit, .clk, .reset);
	
	parameter CLOCK_PERIOD = 100;
	
	initial begin
	
		clk = 1'b0;
		commit = 1'b0;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin
	
		//reset count = 0, board_full = 0
		reset <= 1'b1; repeat(2) @(posedge clk);
		reset <= 1'b0;  @(posedge clk);
		
		//commit enabled, count increments
		commit <= 1'b1; @(posedge clk);
		commit <= 1'b0; @(posedge clk);
		commit <= 1'b1; @(posedge clk);
		
		//commit not enabled, count doesnt not increment
		commit <= 1'b0; repeat(5) @(posedge clk);
		
		//count up to 42, hold? board_full = 1 @ 42
		repeat(42) begin
			commit <= 1'b1; @(posedge clk);
			commit <= 1'b0; @(posedge clk);
		end
			
		$stop;
		
	end
	
endmodule

		
		
	
	
	