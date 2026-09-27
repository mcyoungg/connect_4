
module clean_inputs(
	output logic c_left, c_right, c_select,
	
	input logic lvl_left, lvl_right, lvl_select, //level presses from dff
	input logic p_left, p_right, p_select); //pulsed presses for user input

	
	assign c_left = p_left & lvl_right & lvl_select; //pulse is high, levels are released (high as well)
	assign c_right = p_right & lvl_left & lvl_select;
	assign c_select = p_select & lvl_left & lvl_right;
	
endmodule


module tb_clean_inputs();
	
	//out
	logic c_left, c_right, c_select;
	
	//in
	logic lvl_left, lvl_right, lvl_select;
	logic p_left, p_right, p_select;
	
	clean_inputs uut (.c_left, .c_right, .c_select, .lvl_left, .lvl_right, .lvl_select, .p_left, .p_right, .p_select);
	
	parameter CLOCK_PERIOD = 100;
	logic clk;
	
	initial begin
		clk = 1'b0;
		forever #(CLOCK_PERIOD/2) clk = ~clk;
		
	end
	
	initial begin
		
		//idle	
		lvl_left = 1'b1; lvl_right = 1'b1; lvl_select = 1'b1;
		p_left = 1'b0; p_right = 1'b0; p_select = 1'b0; @(posedge clk);
		
		//clean left
		lvl_left = 1'b0; lvl_right = 1'b1; lvl_select = 1'b1;
		p_left = 1'b1; p_right = 1'b0; p_select = 1'b0; @(posedge clk);
		
		//left pulse but right held down
		lvl_left = 1'b1; lvl_right = 1'b0; lvl_select = 1'b1;
		p_left = 1'b1; p_right = 1'b0; p_select = 1'b0; @(posedge clk);
		
		//clean right, test: right level held --> makes no difference is redundant
		lvl_left = 1'b1; lvl_right = 1'b1; lvl_select = 1'b1;
		p_left = 1'b0; p_right = 1'b1; p_select = 1'b0; @(posedge clk);
		
		//right pulse but select held high
		lvl_left = 1'b1; lvl_right = 1'b1; lvl_select = 1'b0;
		p_left = 1'b0; p_right = 1'b1; p_select = 1'b0; @(posedge clk);
		
		//clean select
		lvl_left = 1'b1; lvl_right = 1'b1; lvl_select = 1'b0;
		p_left = 1'b0; p_right = 1'b0; p_select = 1'b1; @(posedge clk);
		
		//select pulse but left still held high
		lvl_left = 1'b1; lvl_right = 1'b0; lvl_select = 1'b1;
		p_left = 1'b0; p_right = 1'b0; p_select = 1'b1; @(posedge clk);
		
		//release/idle
		lvl_left = 1'b1; lvl_right = 1'b1; lvl_select = 1'b1;
		p_left = 1'b0; p_right = 1'b0; p_select = 1'b0; @(posedge clk);
		
		$stop;
	end
	
endmodule


