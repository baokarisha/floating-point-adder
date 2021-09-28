//=========================================================================================================
//Date: 	02/24/21
//Description: Testbench for 3-stage pipelined half-precision floating point adder
//=========================================================================================================

`timescale 1ns/10ps

	module HP_FP_Pipelined_Adder_Test();
	reg [15:0]	num1_46,num2_46;
	reg 		reset_46,clk_46;
	wire [15:0]	Sum_46;
	
	HP_FP_Pipelined_Adder a1(clk_46,reset_46,num1_46,num2_46,Sum_46);
	
	always 
	#2	clk_46 = ~clk_46;
	
	initial
	begin
		clk_46	= 1;
		reset_46 = 1;
		
	#1	reset_46 = 0;
	end
	
	initial
	begin
		
		num1_46 = 16'h5620;			//98
		num2_46 = 16'h5948;			//169
		// Sum_46	= 16'h5C2C;		//267
		
		
	#4	num1_46 = 16'h5630;			//99
		num2_46 = 16'hD590;			//-89
		// Sum_46	= 16'h4900;		//10
		
	#4	num1_46 = 16'hD1A0;			//-45
		num2_46 = 16'h54F0;			//79
		// Sum_46	= 16'h5040;		//34
		
	#4	num1_46 = 16'hDC6C;			//-283
		num2_46 = 16'hD420;			//-66
		// Sum_46	= 16'hDD74;		//-349
		
	#4	num1_46 = 16'h0000;			//0
		num2_46 = 16'h0000;			//0
		// Sum_46	= 16'h00000;	//0
		
	#4	num1_46 = 16'h0000;			//0
		num2_46 = 16'hD750;			//-117
		// Sum_46	= 16'hD750;		//-117
		
	#4	num1_46 = 16'hD6E2;			//-110.1
		num2_46 = 16'h563E;			//99.9
		// Sum_46	= 16'hC920;		//-10.25
		
	#4	num1_46 = 16'h56E2;			//110.1
		num2_46 = 16'h563E;			//99.9
		// Sum_46	= 16'h5A90;		//210.0
		
	
	#10 $finish;
	end
	
	initial
	begin
		$dumpfile("HP_FP_Pipelined_Adder_Test.vcd");
		$dumpvars(0,HP_FP_Pipelined_Adder_Test);
		$display("			Num_1 | Num_2  | Sum |");
		$monitor($time,"	%h | %h | %h |",num1_46,num2_46,Sum_46);
	end
endmodule
