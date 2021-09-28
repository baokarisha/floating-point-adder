//=========================================================================================================
//Date: 	02/24/21
//Description: 3-stage piplined half-precision floating point adder
//=========================================================================================================

`timescale 1ns/10ps

module HP_FP_Pipelined_Adder(input clk, input reset, input [15:0] num1, input [15:0] num2, output [15:0] sum);

	reg [15:0]	shift_46;
	reg [4:0]	larger_expo_46,sum_expo_46;
	reg [9:0]	small_expo_mant_46,large_expo_mant_46, S_mant_46, L_mant_46, large_mant_46, sum_mant_46;
	reg [10:0]	add_mant_46, add1_mant_46;
	reg [3:0]	denorm_shift_46;
	integer signed denorm_expo_46;
	reg [15:0]	sum_46;
	
	reg			s1_46,s2_46,sum_sign_46;
	reg	[4:0]	e1_46,e2_46;
	reg	[9:0]	m1_46,m2_46;
	
	assign sum	= sum_46;
	
	reg [4:0]	larger_expo_pipe1_46,larger_expo_pipe2_46,larger_expo_pipe3_46;
	reg [9:0]	S_expo_mant_46,L_expo_mant_46, S_expo_mant_pipe1_46, L_expo_mant_pipe1_46;
	reg	[10:0]	add_mant_pipe2_46,add_mant_pipe3_46;
	reg	[3:0]	denorm_shift_pipe3_46;
	integer signed	denorm_expo_pipe3_46;
	
	reg			s1_pipe1_46,s1_pipe2_46,s1_pipe3_46,s2_pipe1_46,s2_pipe2_46,s2_pipe3_46;
	reg	[4:0]	e1_pipe1_46,e1_pipe2_46,e1_pipe3_46,e2_pipe1_46,e2_pipe2_46,e2_pipe3_46;
	reg	[9:0]	m1_pipe1_46,m1_pipe2_46,m1_pipe3_46,m2_pipe1_46,m2_pipe2_46,m2_pipe3_46;
	
	always @(posedge clk) 
	begin
	
		// Extract sign bit, exponent and mantissa from both numbers
		
		s1_46	=	num1[15];	//1 bit for SP
		s2_46	=	num2[15];
		
		e1_46	=	num1[14:10];	//8 bit for SP
		e2_46	=	num2[14:10];
		
		m1_46	=	num1[9:0];		// 23 bit for SP
		m2_46	=	num2[9:0];
		
//**************************************************************************************************

		//Stage I)
		//Compare the exponents and determine the amount of shift required
		
		if(e1_46 > e2_46)		// Here Expo_1 is larger
		begin
			shift_46			=	e1_46 - e2_46;
			larger_expo_46		=	e1_46;
			small_expo_mant_46	=	m2_46;
			large_expo_mant_46	=	m1_46;
		end
		
		else					// Here Expo_2 is larger
		begin
			shift_46			=	e2_46 - e1_46;
			larger_expo_46		=	e2_46;
			small_expo_mant_46	=	m1_46;
			large_expo_mant_46	=	m2_46;
		end
		
		if(e1_46 == 0 | e2_46 == 0)	// If any one of the exponent is zero, no need to shift
			shift_46 = 0;
		else
			shift_46 = shift_46;
		
//**************************************************************************************************

		// Right shift the smaller exponent mantissa & the nnormalise both the mantissas
		
		if(e1_46 != 0) 
		begin
			S_expo_mant_46	= {1'b1,small_expo_mant_46[9:1]};
			S_expo_mant_46	= (S_expo_mant_46 >> shift_46);
		end
		else
			S_expo_mant_46 = small_expo_mant_46;
		
		if(e2_46 != 0)
			L_expo_mant_46 = {1'b1,large_expo_mant_46[9:1]};
		else
			L_expo_mant_46 = large_expo_mant_46;
		
//**************************************************************************************************

		// Stage II)
		//Compare the two aligned mantissas and determine which is smaller among both
		
		if (S_expo_mant_pipe1_46 < L_expo_mant_pipe1_46)
		begin
			S_mant_46	= 	S_expo_mant_pipe1_46;
			L_mant_46	=	L_expo_mant_pipe1_46;
		end
		else
		begin
			S_mant_46	=	L_expo_mant_pipe1_46;
			L_mant_46	=	S_expo_mant_pipe1_46;
		end
		
//**************************************************************************************************
		
		// Add two mantissas if both num1 & num2 have same sign
		// Subtract smaller mantissa from larger mantissa if num1 & num2 have different signs
		
		if(e1_pipe1_46 != 0 & e2_pipe1_46 != 0) 
		begin
			if(s1_pipe1_46 == s2_pipe1_46)
				add_mant_46 = L_mant_46 + S_mant_46;
			else
				add_mant_46 = L_mant_46 - S_mant_46;
		end
		else
			add_mant_46 = L_mant_46;
		
//**************************************************************************************************

		// Stage III)
		// Determine the amount of shift required to denormalise the mantisas &
		// the corresponding direction (right or left shift) 
		
		if(add_mant_pipe2_46[10])
		begin
			denorm_shift_46 =	4'd1;
			denorm_expo_46	=	4'd1;
		end
		else if (add_mant_pipe2_46[9])
		begin
			denorm_shift_46	=	4'd2;
			denorm_expo_46	=	0;
		end
		else if (add_mant_pipe2_46[8])
		begin
			denorm_shift_46	=	4'd3;
			denorm_expo_46	=	-1;
		end
		else if (add_mant_pipe2_46[7])
		begin
			denorm_shift_46	=	4'd4;
			denorm_expo_46	=	-2;
		end
		else if (add_mant_pipe2_46[6])
		begin
			denorm_shift_46	=	4'd5;
			denorm_expo_46	=	-3;
		end
		else
		begin
			denorm_expo_46	=	0;
		end
		
		sum_expo_46 = larger_expo_pipe3_46 + denorm_expo_pipe3_46;
		
//**************************************************************************************************

		// Stage IV)
		// Calculate sign bit, exponent and mantissa for final addition
		if(denorm_shift_pipe3_46 != 0)
			add1_mant_46 = add_mant_pipe3_46 << denorm_shift_pipe3_46;
		else
			add1_mant_46 = add_mant_pipe3_46;
		
		sum_mant_46 = add1_mant_46[10:1];

		if (s1_pipe3_46 == s2_pipe3_46)
			sum_sign_46	=	s1_pipe3_46;
		
		if(e1_pipe3_46 > e2_pipe3_46)
			sum_sign_46	=	s1_pipe3_46;
		else if(e2_pipe3_46 > e1_pipe3_46)
			sum_sign_46	=	s2_pipe3_46;
		else
		begin
			if(m1_pipe3_46 > m2_pipe3_46)
				sum_sign_46	=	s1_pipe3_46;
			else	
				sum_sign_46	=	s2_pipe3_46;
		end
		
		sum_46 = {sum_sign_46,sum_expo_46,sum_mant_46};
	end	
	
	always @(posedge clk)
	begin
		if(reset)
		begin
			// Reg_1 Output
			larger_expo_pipe1_46		<=	0;
			S_expo_mant_pipe1_46		<=	0;
			L_expo_mant_pipe1_46		<=	0;
			s1_pipe1_46					<=	0;
			s2_pipe1_46					<=	0;
			e1_pipe1_46					<=	0;
			e2_pipe1_46					<=	0;
			m1_pipe1_46					<=	0;
			m2_pipe1_46					<=	0;
			
			// Reg_2 Output
			add_mant_pipe2_46			<=	0;
			larger_expo_pipe2_46		<=	0;
			s1_pipe2_46					<=	0;
			s2_pipe2_46					<=	0;
			e1_pipe2_46					<=	0;
			e2_pipe2_46					<=	0;
			m1_pipe2_46					<=	0;
			m2_pipe2_46					<=	0;
			
			// Reg_3 Output
			denorm_expo_pipe3_46		<=	0;
			denorm_shift_pipe3_46		<=	0;
			larger_expo_pipe3_46		<=	0;
			add_mant_pipe3_46			<=	0;
			s1_pipe3_46					<=	0;
			s2_pipe3_46					<=	0;
			e1_pipe3_46					<=	0;
			e2_pipe3_46					<=	0;
			m1_pipe3_46					<=	0;
			m2_pipe3_46					<=	0;
			
			sum_46						<=	0;
		end
		else 
		begin
			///////////////////////// Pipelining stages /////////////////////////
			// Propagate the variable to the next stgae through register
			
			larger_expo_pipe1_46		<=	larger_expo_46;
			S_expo_mant_pipe1_46		<=	S_expo_mant_46;
			L_expo_mant_pipe1_46		<=	L_expo_mant_46;
			s1_pipe1_46					<=	s1_46;
			s2_pipe1_46					<=	s2_46;
			e1_pipe1_46					<=	e1_46;
			e2_pipe1_46					<=	e2_46;
			m1_pipe1_46					<=	m1_46;
			m2_pipe1_46					<=	m2_46;
			
			add_mant_pipe2_46			<=	add_mant_46;
			larger_expo_pipe2_46		<=	larger_expo_pipe1_46;
			s1_pipe2_46					<=	s1_pipe1_46;
			s2_pipe2_46					<=	s2_pipe1_46;
			e1_pipe2_46					<=	e1_pipe1_46;
			e2_pipe2_46					<=	e2_pipe1_46;
			m1_pipe2_46					<=	m1_pipe1_46;
			m2_pipe2_46					<=	m2_pipe1_46;
			
			denorm_expo_pipe3_46		<=	denorm_expo_46;
			denorm_shift_pipe3_46		<=	denorm_shift_46;
			larger_expo_pipe3_46		<=	larger_expo_pipe2_46;
			add_mant_pipe3_46			<=	add_mant_pipe2_46;
			s1_pipe3_46					<=	s1_pipe2_46;
			s2_pipe3_46					<=	s2_pipe2_46;
			e1_pipe3_46					<=	e1_pipe2_46;
			e2_pipe3_46					<=	e2_pipe2_46;
			m1_pipe3_46					<=	m1_pipe2_46;
			m2_pipe3_46					<=	m2_pipe2_46;
		end
	end
	
endmodule
