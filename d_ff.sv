
module d_ff(q, d, clk, reset);
	
	input logic d, clk, reset;
	output logic q;
	
	always_ff @(posedge clk) begin
	
		if(reset)
			q <= 0;
			
		else
			q <= d;
			
	end
	
endmodule

module tb_dff();

	logic q, d, clk, reset;
	
	d_ff uut(.q(q), .d(d), .clk(clk), .reset(reset));
	
	parameter CLOCK_PERIOD = 100;
	
	initial begin
	
		clk = 0;
		
		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin 
	
		reset <= 1; 			@(posedge clk);
		reset <= 0; d <= 0;  @(posedge clk);
									@(posedge clk);
									@(posedge clk);
		d <= 1;					@(posedge clk);
		d <= 0;					@(posedge clk);
		d <= 1; 					@(posedge clk);
									@(posedge clk);
		d <= 0;					@(posedge clk);
									@(posedge clk);
		$stop;
		
	end
	
endmodule
