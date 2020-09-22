library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package types is
--	constant	fitness_bit_width		: integer 	:= 16;
--	constant	gene_length      		: integer 	:= 8; -- genome count
--	constant	gene_bit_width   		: integer 	:= 1;
--	constant	COMP_SIGNED   			: std_logic := '0';
--
--	constant	random_numbit_gene		: integer := 1; -- 
--	constant	random_number_bits		: integer := gene_length*2+gene_bit_width; -- crossover+mutation=gene_length*2  +  random=gene_bit_width;

--	constant	fitness_bit_width		: integer 	:= 24;
--	constant	gene_length      		: integer 	:= 8; -- genome count
--	constant	gene_bit_width   		: integer 	:= 3;
--	constant	COMP_SIGNED   			: std_logic := '1';
--
--	constant	random_numbit_gene		: integer := 3; -- 
--	constant	random_number_bits		: integer := gene_length*2+gene_bit_width; -- crossover+mutation=gene_length*2  +  random=gene_bit_width;

	constant	fitness_bit_width		: integer 	:= 32;
	constant	gene_length      		: integer 	:= 2; -- genome count
	constant	gene_bit_width   		: integer 	:= 32;
	constant	COMP_SIGNED   			: std_logic := '0';
	constant	FIND_MIN				: std_logic := '1';

	constant	random_numbit_gene			: integer := 2; -- 
	constant	tournament_size				: integer := 16;
	constant	random_selection_bitwidth	: integer := 2;
	--constant	random_number_bits			: integer := gene_length*2+gene_bit_width+random_selection_bitwidth*tournament_size; -- crossover+mutation=gene_length*2  +  random=gene_bit_width;
	subtype		ga_type_fitness 		is std_logic_vector(fitness_bit_width-1 downto 0);  -- fitness function output value type
	type		ga_type_fitness_1d 		is array (natural range<>) of ga_type_fitness;  -- array for fitness values

	subtype		ga_type_gene 			is std_logic_vector(gene_bit_width-1 downto 0);  -- gene type for GA
	type		ga_type_1d 				is array(natural range <>) of ga_type_gene;  -- 1D array for GA
	type		ga_type_1d_array 		is array(natural range <>) of ga_type_1d(gene_length-1 downto 0);  -- 1D array for GA
	type		ga_type_2d 				is array(natural range <>, natural range <>) of ga_type_gene;  -- 2D array for GA

	type		individual 				is record
				chromosome 				: ga_type_1d(gene_length-1 downto 0);  --gene_length-1 downto 0
				fitness    				: ga_type_fitness;
	end record;
	type		chromosome_type 		is record
				chromosome 				: ga_type_1d(gene_length-1 downto 0);  --gene_length-1 downto 0
	end record;  

	type 		ga_type_indiv_array		is array (natural range<>) of individual;
	type		chromosome_type_array	is array (natural range<>) of chromosome_type;

	--subtype		feature 				is std_logic_vector(feature_bitwidth-1 downto 0);
	--type		feature_vect 			is array(feature_size-1 downto 0) of feature;
	--type		feature_vect_array 		is array(natural range <>) of feature_vect;
	type		selection_types			is (srandom, sroulette,stournament,selitist);
	type		init_types 				is (random, external_init);
	type		crossover_types 		is (one_point, multiple_point, external_crossover);
	type		mutation_types 			is (one_point_flip_bit,multiple_point_flip_bit,one_point_random,multiple_point_random,external_mutation);
	type		random_types 			is (standard,external_random);	

	type		method_types 	is (PRSG, LFSR);
	
	constant seed_crossover_rnd 	: std_logic_vector(gene_length-1 downto 0) 						:= conv_std_logic_vector(10, gene_length);  -- seed value of RNG
	constant seed_mutation_rnd		: std_logic_vector(gene_length-1 downto 0) 						:= conv_std_logic_vector(5, gene_length);  -- seed value of RNG
	constant seed_random_rnd 		: std_logic_vector(gene_bit_width-1 downto 0) 					:= conv_std_logic_vector(361, gene_bit_width);  -- seed value of RNG
	constant seed_select0_rnd		: std_logic_vector(random_selection_bitwidth-1 downto 0) 		:= conv_std_logic_vector(2, random_selection_bitwidth);  -- seed value of RNG
	constant seed_select1_rnd		: std_logic_vector(random_selection_bitwidth-1 downto 0) 		:= conv_std_logic_vector(7, random_selection_bitwidth);  -- seed value of RNG
	constant seed_select2_rnd		: std_logic_vector(random_selection_bitwidth-1 downto 0) 		:= conv_std_logic_vector(8, random_selection_bitwidth);  -- seed value of RNG
	constant seed_select3_rnd		: std_logic_vector(random_selection_bitwidth-1 downto 0) 		:= conv_std_logic_vector(9, random_selection_bitwidth);  -- seed value of RNG
	-------------------------------------------------------------------------------------------------

	-------------------------------------------------------------------------------------------------
	constant	pop_size				: integer 			:= 32;
	constant	elt_size				: integer			:= 3;
	constant	cross_size				: integer			:= pop_size/3;
	constant	mut_size				: integer			:= pop_size/6;
	constant	sel_type				: selection_types	:= stournament;
	constant	initialization_type		: init_types		:= external_init;
	constant	cross_type				: crossover_types	:= one_point;
	constant	mut_type				: mutation_types	:= one_point_random;
	constant	rand_type				: random_types		:= standard;
	constant	fit_size				: integer			:= 5;
	constant	random_method			: method_types		:= LFSR;
	constant	fit_goal				: ga_type_fitness	:= x"3a83126f";
	--constant	mi_vals    				: ga_type_1d(gene_length-1 downto 0) 	:= ("0","0","0","0","0","0","0","0");
    --constant	ma_vals					: ga_type_1d(gene_length-1 downto 0) 	:= ("1","1","1","1","1","1","1","1") ;
--	constant	mi_vals    				: ga_type_1d(gene_length-1 downto 0) 	:= (x"C059000000000000",
--																					x"C059000000000000",
--																					x"C059000000000000",
--																					x"C059000000000000",
--																					x"C059000000000000",
--																					x"C059000000000000",
--																					x"C059000000000000",
--																					x"C059000000000000",
--																					x"C059000000000000",
--																					x"C059000000000000");
--    constant	ma_vals					: ga_type_1d(gene_length-1 downto 0) 	:= (x"4059000000000000",
--																					x"4059000000000000",
--																					x"4059000000000000",
--																					x"4059000000000000",
--																					x"4059000000000000",
--																					x"4059000000000000",
--																					x"4059000000000000",
--																					x"4059000000000000",
--																					x"4059000000000000",
--																					x"4059000000000000") ;
	constant	mi_vals    				: ga_type_1d(gene_length-1 downto 0) 	:= (x"C0590000",
																					x"C0590000");--,
																					--x"C0590000",
																					--x"C0590000",
																					--x"C0590000",
																					--x"C0590000",
																					--x"C0590000",
																					--x"C0590000",
																					--x"C0590000",
																					--x"C0590000");
    constant	ma_vals					: ga_type_1d(gene_length-1 downto 0) 	:= (x"40590000",
																					x"40590000");--,
																					--x"40590000",
--																					x"40590000",
																					--x"40590000",
																					--x"40590000",
																					--x"40590000",
																					--x"40590000",
																					---x"40590000",
																				--	x"40590000") ;

--	constant	mi_vals    				: ga_type_1d(gene_length-1 downto 0) 	:= (x"10",
--																					x"10",
--																					x"10",
--																					x"10",
--																					x"10",
--																					x"10",
--																					x"10",
--																					x"10",
--																					x"10",
--																					x"10");
--    constant	ma_vals					: ga_type_1d(gene_length-1 downto 0) 	:= (x"7F",
--																					x"7F",
--																					x"7F",
--																					x"7F",
--																					x"7F",
--																					x"7F",
--																					x"7F",
--																					x"7F",
--																					x"7F",
--																					x"7F") ;
	constant	res_size				: integer			:= pop_size;
end types;
