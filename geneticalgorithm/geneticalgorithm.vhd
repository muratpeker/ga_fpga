library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library work;
use work.types.all;

entity GeneticAlgorithm is
generic (
	population_size 		: integer 								:= 10;  		-- population size of GA
    -- edit ga_type_1d type in types package
    chromosome_size 		: integer 								:= gene_length;	-- size of features to search for
	elitism_size 			: integer 								:= 2;  			-- elitism size of GA
	crossover_size 			: integer 								:= 4;  			-- crossover size of GA
	mutation_size 			: integer 								:= 2;  			-- mutation_size of GA
	init_type  				: init_types 							:= random;  	-- 0 for one_point crossover
	select_type				: selection_types						:= sel_type;
	crossover_type  		: crossover_types 						:= one_point;  	-- 0 for one_point crossover
	mutation_type   		: mutation_types 						:= one_point_flip_bit;  	-- 0 for Flip bit mutation
	random_type   			: random_types 							:= standard;  	-- 
	fitness_module_count 	: integer 								:= 1;
	
	-- termination criterias
	--fitness_goal			: ga_type_fitness						:= conv_std_logic_vector(65025,ga_type_fitness'length);
	fitness_goal			: ga_type_fitness						:= conv_std_logic_vector(0,ga_type_fitness'length);
	--fitness_goal			: ga_type_fitness						:= conv_std_logic_vector(8183,ga_type_fitness'length);
	--fitness_goal			: ga_type_fitness						:= conv_std_logic_vector(63904,ga_type_fitness'length);
	max_it					: integer range 0 to 65535				:= 2000;
	
	-- range must be chromesome_size-1 downto 0
	min_vals 				: ga_type_1d(gene_length-1 downto 0)	:= (others => conv_std_logic_vector(0, gene_bit_width));  	-- minimum value of each chromosome
	max_vals 				: ga_type_1d(gene_length-1 downto 0) 	:= (others => conv_std_logic_vector(400, gene_bit_width)));	-- maximum value of each chromosome
port (
	elapsed_time      		: out std_logic_vector(31 downto 0);
	best_indiv        		: out ga_type_indiv_array(res_size-1 downto 0);
	ready_out         		: out std_logic;
	max_it_reached     		: out std_logic;
	max_fitness_reached		: out std_logic;
  	continues         		: in  std_logic;		-- if 0 then after one step generation waits for continues signal
	it_counter				: out integer range 0 to 65535	:= 0;

	clk 					: in std_logic;		-- clock for GA
	rst 					: in std_logic);	-- reset signal for GA 
end GeneticAlgorithm;

architecture behav of GeneticAlgorithm is
	signal	generation 			: ga_type_indiv_array(population_size-1 downto 0);
	signal 	clear_all			: std_logic := '1';
	-- fitness module signals
	signal fitness_generation_last 			: integer range 0 to population_size+1 :=0;
	signal fitness_generation 				: ga_type_1d_array(population_size-1 downto 0);
	signal sorted_cnt 			: integer range 0 to population_size+1 :=0;
	signal generation_sorting 	: ga_type_indiv_array(population_size-1 downto 0);
	signal fitness_control_rst	: std_logic :='0';
	signal sorting_process_rst	: std_logic :='0';
	signal sorting_add_lock		: std_logic :='0';
	signal sorting_last_indiv 	: integer range 0 to population_size+1 :=0;
	signal sort_indiv 			: individual;
	signal sorting_queue 		: ga_type_indiv_array(population_size-1 downto 0);
	
	
	signal sorting_add			: std_logic :='0';
	signal sorting_add1			: std_logic :='0';
	signal sorting_add_indiv	: individual;
	signal sorting_elitism 		: std_logic :='0';
	
	type	type_active_fitness 	is array(natural range <>) of integer range 0 to fitness_module_count+1;
	signal	fitness_inputs 			: ga_type_1d_array(fitness_module_count-1 downto 0);
	signal	fitness_process_inputs 	: std_logic_vector(fitness_module_count-1 downto 0);
	signal 	fitness_out_ready		: std_logic_vector(fitness_module_count-1 downto 0);
	signal 	fitness_outputs			: ga_type_fitness_1d(fitness_module_count-1 downto 0);
	signal 	fitness_rst 			: std_logic:='0';
	component fitness port (
		-- input signals to control if the module is ready to process
		inputs         	: in	ga_type_1d(gene_length-1 downto 0);    	-- inputs for fitness function
		process_inputs 	: in  	std_logic;
		-- output signals to 
		output_ready    : out 	std_logic;
		output          : out 	ga_type_fitness;      					-- output of fitness value
		-- clk and reset signals
		clk 			: in 	std_logic;                 				-- clock for fitness module
		rst 			: in 	std_logic);                				-- reset signal of module
	end component;

	-- external initialization module
	signal ext_init_rnd_number 		: std_logic_vector(gene_bit_width-1 downto 0);
	signal ext_init_process_inputs 	: std_logic;
	signal ext_init_output_ready 	: std_logic;
	signal ext_init_outputs       	: ga_type_1d(gene_length-1 downto 0);      -- output of ext_init individual
	signal ext_init_rst 			: std_logic;
	component ext_init port (
		-- input signals to control if the module is ready to process
		rnd_number	 	: in	std_logic_vector(gene_bit_width-1 downto 0);
		process_inputs 	: in	std_logic;
		imin_vals 		: in	ga_type_1d(gene_length-1 downto 0);
		imax_vals 		: in	ga_type_1d(gene_length-1 downto 0);

		-- output signals to 
		output_ready 	: out 	std_logic;
		outputs       	: out 	ga_type_1d(gene_length-1 downto 0);      -- output of ext_init individual

		-- clk and reset signals
		clk 			: in std_logic;                 -- clock for ext_init module
		rst 			: in std_logic);                -- reset signal of module
	end component;

	-- external crossover
	signal ext_cross_input0				: ga_type_1d(gene_length-1 downto 0);
	signal ext_cross_input1				: ga_type_1d(gene_length-1 downto 0);
	--signal ext_cross_rnd_number			: std_logic_vector(gene_length-1 downto 0);
	signal ext_cross_process_inputs		: std_logic;
	signal ext_cross_output_ready 		: std_logic;
	signal ext_cross_outputs			: ga_type_1d(gene_length-1 downto 0);
	signal ext_cross_output_ready2 		: std_logic;
	signal ext_cross_outputs2			: ga_type_1d(gene_length-1 downto 0);
	signal ext_cross_rst 				: std_logic;
	component ext_crossover port (
		-- input signals to control if the module is ready to process
		input0			: in ga_type_1d(gene_length-1 downto 0);    -- inputs individual
		input1			: in ga_type_1d(gene_length-1 downto 0);    -- inputs individual
		rnd_number		: in std_logic_vector(gene_length-1 downto 0); -- genomes
		process_inputs	: in std_logic;

		-- output signals to 
		output_ready	: out std_logic;
		output_ready2	: out std_logic;
		outputs			: out ga_type_1d(gene_length-1 downto 0); 
		outputs2		: out ga_type_1d(gene_length-1 downto 0);

		-- clk and reset signals
		clk : in std_logic;                 -- clock for ext_crossover module
		rst : in std_logic);                -- reset signal of module
	end component;

	-- external mutation
	signal ext_mutation_input0				: ga_type_1d(gene_length-1 downto 0);
	signal ext_mutation_input1				: ga_type_1d(gene_length-1 downto 0);
	--signal ext_mutation_rnd_number			: std_logic_vector(gene_length-1 downto 0);
	signal ext_mutation_process_inputs		: std_logic;
	signal ext_mutation_output_ready 		: std_logic;
	signal ext_mutation_outputs				: ga_type_1d(gene_length-1 downto 0);
	signal ext_mutation_rst 				: std_logic;
	component ext_mutation port (
		-- input signals to control if the module is ready to process
		input0			: in ga_type_1d(gene_length-1 downto 0);    -- inputs individual
		input1			: in ga_type_1d(gene_length-1 downto 0);    -- inputs individual
		rnd_number		: in std_logic_vector(gene_length-1 downto 0); -- genomes
		process_inputs	: in std_logic;

		-- output signals to 
		output_ready	: out std_logic;
		outputs			: out ga_type_1d(gene_length-1 downto 0);      -- output of ext_crossover individual

		-- clk and reset signals
		clk : in std_logic;                 -- clock for ext_crossover module
		rst : in std_logic);                -- reset signal of module
	end component;

	-- external random module
	--signal ext_random_rnd_number 		: std_logic_vector(gene_bit_width-1 downto 0);
	signal ext_random_process_inputs 	: std_logic;
	signal ext_random_output_ready 		: std_logic;
	signal ext_random_outputs       	: ga_type_1d(gene_length-1 downto 0);      -- output of ext_init individual
	signal ext_random_rst 				: std_logic;
	component ext_random port (
		-- input signals to control if the module is ready to process
		rnd_number	 	: in	std_logic_vector(gene_bit_width-1 downto 0);
		process_inputs 	: in	std_logic;
		imin_vals 		: in	ga_type_1d(gene_length-1 downto 0);
		imax_vals 		: in	ga_type_1d(gene_length-1 downto 0);

		-- output signals to 
		output_ready 	: out 	std_logic;
		outputs       	: out 	ga_type_1d(gene_length-1 downto 0);      -- output of ext_init individual

		-- clk and reset signals
		clk 			: in std_logic;                 -- clock for ext_init module
		rst 			: in std_logic);                -- reset signal of module
	end component;

	-- random number generator
	signal clk_rnd  			: std_logic                                   			:= '0';  -- clock pulse for random number generator
	signal rst_rnd  			: std_logic                                   			:= '1';  -- reset signal for random number generator(RNG)
	signal crossover_rnd		: std_logic_vector(gene_length-1 downto 0);
	signal mutation_rnd			: std_logic_vector(gene_length-1 downto 0);
	signal random_rnd			: std_logic_vector(gene_bit_width-1 downto 0);
	
	signal select0_rnd			: std_logic_vector(random_selection_bitwidth-1 downto 0);
	signal select1_rnd			: std_logic_vector(random_selection_bitwidth-1 downto 0);
	signal select2_rnd			: std_logic_vector(random_selection_bitwidth-1 downto 0);
	signal select3_rnd			: std_logic_vector(random_selection_bitwidth-1 downto 0);
	
	
	--signal res_rnd  			: std_logic_vector(random_number_bits-1 downto 0);  -- result from RNG
	signal enable_rnd_clk		: std_logic := '0'; 
	component randnumbgen
	generic (
        method             : method_types	:= random_method;  -- select the random number generation type
        -- pseudo random sequence generator (PRSG)
        -- linear feedback shift register (LFSR)
        output_number_bits : integer		:= gene_length);  --output-number-bit-width
	port (
        clk  : in  std_logic;  -- clock for random number generator module
        rst  : in  std_logic;             -- reset signal
        seed : in  std_logic_vector(output_number_bits-1 downto 0);  -- seed value
        res  : out std_logic_vector(output_number_bits-1 downto 0));  -- output generated random value
	end component;
	component randnumbgenfloat
	generic (
        method             : method_types	:= random_method;
		-- pseudo random sequence generator (PRSG)
        -- linear feedback shift register (LFSR)
        output_number_bits : integer		:= gene_bit_width);  --output-number-bit-width
	port (
        clk  : in  std_logic;  -- clock for random number generator module
        rst  : in  std_logic;             -- reset signal
        seed : in  std_logic_vector(output_number_bits-1 downto 0);  -- seed value
        res  : out std_logic_vector(output_number_bits-1 downto 0));  -- output generated random value
	end component;
begin  -- behav

  -- purpose: main process for all GA operations
  -- type   : sequential
  -- inputs : clk, rst
  -- outputs: 
	main_process : process (clk, rst)
		--state variables
		type     state is (INITIALIZE,INIT_POP, NEXT_GEN, ELITISM, CROSS_MUT, WAIT_FOR_ALL_FINISH);  -- states for main_process
		variable inner_state		: state := INIT_POP;  -- state variable of the process
		variable next_state			: state := NEXT_GEN ;
		variable counter			: integer range 0 to 6553500 :=0;
		variable it_count 			: integer range 0 to 65535	:= 0;
		variable extract_feature_of_new_indiv : boolean := false;
		variable elapsed_time_total	: std_logic_vector(31 downto 0);

		--initialization variables
		variable init_gene_cntr		: integer range 0 to gene_length+1 :=0;
		variable init_indiv_cntr	: integer range 0 to population_size+1 :=0;
		variable new_indiv_c		: ga_type_1d(gene_length-1 downto 0);
		variable new_indiv_c2		: ga_type_1d(gene_length-1 downto 0);
		variable new_indiv_m		: ga_type_1d(gene_length-1 downto 0);
		variable new_indiv_r		: ga_type_1d(gene_length-1 downto 0);

		
		-- selection vars
		variable select_best	: std_logic_vector(random_selection_bitwidth-1 downto 0);
		variable select_best2	: std_logic_vector(random_selection_bitwidth-1 downto 0);
		
	    -- elitism vars
		variable elitist_cntr	: integer range 0 to elitism_size+1 :=0;

		-- crossover vars
		variable crossover_index0				: integer range 0 to population_size-1;
		variable crossover_index1				: integer range 0 to population_size-1;
		variable crossover_cntr					: integer range 0 to crossover_size+1 :=0;
		variable crossover_indiv_creation_state : std_logic :='1';
		
		
		

		-- mutation vars
		variable mutation_indiv_count			: std_logic_vector(1 downto 0) := "00";
		variable mutation_indiv0				: ga_type_1d(gene_length-1 downto 0);
		variable mutation_indiv1				: ga_type_1d(gene_length-1 downto 0);
		variable mutation_cntr					: integer range 0 to mutation_size+1 :=0;
		variable mutation_indiv_creation_state 	: std_logic :='0';

		-- random generation vars
		variable random_gene_cntr : integer range 0 to gene_length+1 :=0;
		variable random_indiv_cntr : integer range 0 to population_size+1 :=0;
		

		variable feature_read_ok : boolean :=false;

		variable fitness_generation_last_main: integer range 0 to population_size+1 :=0;

		procedure clearElitismVars is
		begin
			--crossover vars
			--crossover_cntr:=0;
			sorting_add1<='0';
			--crossover_rnd:='0';
		end clearElitismVars;

		procedure clearCrossoverVars is
		begin
			--crossover vars
			crossover_cntr:=0;
			--crossover_rnd:='0';
		end clearCrossoverVars;

		procedure clearMutationVars is
		begin
			-- mutation vars
			mutation_cntr:=0;
			--mutation_rnd:='0';
			mutation_indiv_creation_state:='0';
		end clearMutationVars;

		procedure clearRandomVars is
		begin
			-- random vars
			random_gene_cntr:=0;
			random_indiv_cntr:=0;
		end clearRandomVars;

		procedure clearInitVars is
		begin
			--initialization variables
			init_gene_cntr:=0;
			init_indiv_cntr:=0;
			-- sorted indivs
			--sorting_last_indiv:=0;
			--sorting_queue_size:=0;
			--sorting_current_indiv:=0;
			--sorted_cnt:=0;
			-- 
			feature_read_ok:=true;
			-- Fitness vars
			--clearFitnessVars;
		end clearInitVars;
		
				
	begin  -- process main_process
		--crossover_rnd:=res_rnd(gene_length-1 downto 0);
		--mutation_rnd:=res_rnd(gene_length*2-1 downto gene_length);
		--random_rnd:=res_rnd(gene_length*2+gene_bit_width-1 downto gene_length*2);
		--select0_rnd:=res_rnd(gene_length*2+gene_bit_width+random_selection_bitwidth-1 downto gene_length*2+gene_bit_width);
		--select1_rnd:=res_rnd(gene_length*2+gene_bit_width+random_selection_bitwidth*2-1 downto gene_length*2+gene_bit_width+random_selection_bitwidth);
		--select2_rnd:=res_rnd(gene_length*2+gene_bit_width+random_selection_bitwidth*3-1 downto gene_length*2+gene_bit_width+random_selection_bitwidth*2);
		--select3_rnd:=res_rnd(gene_length*2+gene_bit_width+random_selection_bitwidth*4-1 downto gene_length*2+gene_bit_width+random_selection_bitwidth*3);
		rst_rnd <= '0';
		if rst = '1' then                   -- asynchronous reset (active low)
			-- random number generator reset
			--seed_rnd     <= conv_std_logic_vector(25, gene_bit_width);
			rst_rnd      <= '0';
			enable_rnd_clk<='0';
			-------------------------------------------------------------------------

			-- reset modules
			fitness_rst<='1';

			-- module outputs
			elapsed_time<=conv_std_logic_vector(0,32);
			ready_out<='0';
      
			-- clear vars
			inner_state:=INITIALIZE;
			counter:=0;
			extract_feature_of_new_indiv:=false;

			--initialization variables
			init_gene_cntr:=0;
			init_indiv_cntr:=0;

			

			-- elitism vars
			elitist_cntr:=0;
      
			--crossover vars
			crossover_cntr:=0;
			ext_cross_rst<='1';

			-- mutation vars
			mutation_cntr:=0;
			mutation_indiv_creation_state:='0';
			ext_mutation_rst<='1';

			-- random vars
			random_gene_cntr:=0;
			random_indiv_cntr:=0;
			ext_random_rst<='1';

			-- 
			fitness_generation_last_main:=0;
			
			feature_read_ok:=true;
			sorting_add1<='0';
			fitness_generation_last<=fitness_generation_last_main;
			
			fitness_control_rst<='1';
			sorting_process_rst<='1';
			mutation_indiv_count:="00";
			clear_all<='1';

			--clear_g : for i in 0 to generation'length-1 loop
			--	generation(i)<=(others => conv_std_logic_vector(0, gene_bit_width));
			--end loop ; -- clear_g

		elsif clk'event and clk = '1' then  -- rising clock edge
			fitness_control_rst<='0';
			sorting_process_rst<='0';
			clear_all<='0';
			-- reset modules
			fitness_rst<='0';
			-- random number generator active
			rst_rnd <= '0';
			------------------------------------------------------------------------
			-- cases of GA algotihm
			-- init
			-- elitism
			-- crossover
			-- mutation
			case inner_state is
				when INITIALIZE =>
					inner_state := INIT_POP;
					clearInitVars;
					counter:=0;
					enable_rnd_clk<='1';  -- enable random number generator
					ext_init_rst<='1';
					elapsed_time_total:=conv_std_logic_vector(0,32);
				when INIT_POP =>
					counter:=counter+1;
					ready_out<='0';
					ext_init_rst<='0';
					it_count:=0;
					-- initialize first population
					if init_indiv_cntr<population_size then
						case( init_type ) is
							when random =>
								if init_gene_cntr<gene_length then -- yeni gen oluştur
									-- taşma kontrol ediliyor
									if random_rnd>=min_vals(init_gene_cntr) and random_rnd<=max_vals(init_gene_cntr) then
										-- yeni değeri ata
										new_indiv_r (init_gene_cntr):=random_rnd;
										init_gene_cntr:=init_gene_cntr+1;
									end if ;
									--fitness_process_inputs<='0';
								else -- gen oluşturma bitti ise fitness hesaplamak için queue'ya ekle
									fitness_generation(fitness_generation_last_main)<=new_indiv_r;
									--fitness_generation_chromosomes(fitness_generation_last).chromosome:=new_indiv_r;
									fitness_generation_last_main:=fitness_generation_last_main+1;

									init_gene_cntr:=0; -- yeni birey için pointerı sıfırla
									init_indiv_cntr:=init_indiv_cntr+1;  -- yeni birey üretimine geç  
								end if ;
							when external_init =>
								ext_init_rnd_number<=random_rnd;
								new_indiv_r:=ext_init_outputs;
								if( ext_init_output_ready='0' )then
									ext_init_process_inputs<='1';
								else
									--if( ext_init_output_ready='1' )then
									fitness_generation(fitness_generation_last_main)<=new_indiv_r;
									--fitness_generation_chromosomes(fitness_generation_last).chromosome:=new_indiv_r;
									fitness_generation_last_main:=fitness_generation_last_main+1;
			          
									init_gene_cntr:=0; -- yeni birey için pointerı sıfırla
									init_indiv_cntr:=init_indiv_cntr+1;  -- yeni birey üretimine geç  
									ext_init_process_inputs<='0';
									--end if;
								end if;
						end case;
					else
						ext_init_rst<='1';
						inner_state:=WAIT_FOR_ALL_FINISH;
						next_state:=NEXT_GEN;
					end if ;
				when WAIT_FOR_ALL_FINISH => --  waiting for finish of the fitness and sorting process of the new generation
					elapsed_time<=conv_std_logic_vector(counter,32);
					--elapsed_time<=conv_std_logic_vector(sorted_cnt,32);
					--best_indiv<=generation_sorting(0);
					if sorted_cnt>=population_size then -- new generation is ready
						generation <= generation_sorting(generation'length-1 downto 0);
						inner_state:=NEXT_GEN;
						--enable_rnd_clk<='1';  -- start random number generator
						ready_out<='1';
						best_indiv<=generation_sorting(best_indiv'length-1 downto 0);
						if( FIND_MIN='1' )then
							if( generation_sorting(0).fitness<=fitness_goal or it_count+1>=max_it )then
								if( generation_sorting(0).fitness<=fitness_goal )then
									max_fitness_reached<='1';
								end if;
								if( it_count+1>=max_it )then
									max_it_reached<='1';
								end if;

								inner_state:=WAIT_FOR_ALL_FINISH;
								elapsed_time<=elapsed_time_total+conv_std_logic_vector(counter,32);
							else
								it_count:=it_count+1;
								elapsed_time_total:=elapsed_time_total+conv_std_logic_vector(counter,32);
								fitness_control_rst<='1';
								sorting_process_rst<='1';
							end if;
						else
							if( generation_sorting(0).fitness>=fitness_goal or it_count+1>=max_it )then
								if( generation_sorting(0).fitness>=fitness_goal )then
									max_fitness_reached<='1';
								end if;
								if( it_count+1>=max_it )then
									max_it_reached<='1';
								end if;
								inner_state:=WAIT_FOR_ALL_FINISH;
								elapsed_time<=elapsed_time_total+conv_std_logic_vector(counter,32);
							else
								it_count:=it_count+1;
								elapsed_time_total:=elapsed_time_total+conv_std_logic_vector(counter,32);
								fitness_control_rst<='1';
								sorting_process_rst<='1';
							end if;
						end if;

						it_counter<=it_count;
						-- reset modules
						fitness_rst<='1';
					else
						counter:=counter+1;
					end if ;
				when NEXT_GEN =>
					-- reset modules
					fitness_rst<='1';
					--rst_rnd <= '1';
					-- wait for next step or continue auto
					ready_out<='1';
					ext_cross_rst<='0';
					ext_mutation_rst<='0';
					ext_random_rst<='0';
					if continues='1' then
						enable_rnd_clk<='1';  -- start random number generator
						elitist_cntr:=0;
						inner_state:=ELITISM;
						counter:=0;
						clearElitismVars;
						clearInitVars;
						fitness_generation_last_main:=0;
						fitness_rst<='1';
						--clearFitnessVars;
						ext_cross_rst<='1';
						ext_mutation_rst<='1';
						ext_random_rst<='1';
						sorting_add1<='0';
						fitness_control_rst<='0';
						sorting_process_rst<='0';
						mutation_indiv_count:="00";
					end if ;
				when ELITISM =>
					counter:=counter+1;
					ready_out<='0';
					-- elitist selection
					if( sorting_elitism='0' )then
						sorting_add1<='1';
					else
						elitist_cntr:=elitism_size;
						sorting_add1<='0';
						inner_state:=CROSS_MUT;
						--inner_state:=CROSSOVER;
						crossover_indiv_creation_state:='1';
						clearCrossoverVars;
						
						--clear variables MUTATION;
						mutation_indiv_creation_state:='0';
						enable_rnd_clk<='1';  -- enable random number generator
						clearMutationVars;
						fitness_rst<='0';
						--clear variables RANDOM;
						clearRandomVars;
					end if;
				when CROSS_MUT =>
					counter:=counter+1;
					-- selection
					case( select_type )is 
						when srandom =>
							crossover_index0:=conv_integer(select0_rnd);
							crossover_index1:=conv_integer(select1_rnd);
						when stournament =>
							select_best:=select0_rnd;
							if( select_best>select1_rnd )then
								select_best:=select1_rnd;
							end if;
							if( select_best>select2_rnd )then
								select_best:=select2_rnd;
							end if;
							if( select_best>select3_rnd )then
								select_best:=select3_rnd;
							end if;
							crossover_index0:=conv_integer(select_best);
								
							select_best2:=select0_rnd;
							if( select_best2=select_best )then
								select_best2:=select1_rnd;
							end if;
							if( select_best>select1_rnd and select_best2/=select_best )then
								select_best2:=select1_rnd;
							end if;
							if( select_best>select2_rnd and select_best2/=select_best )then
								select_best2:=select2_rnd;
							end if;
							if( select_best>select3_rnd and select_best2/=select_best )then
								select_best2:=select3_rnd;
							end if;
							crossover_index1:=conv_integer(select_best2);
						when sroulette =>
						when selitist =>
							crossover_index0:=crossover_cntr+1;
							crossover_index1:=crossover_cntr+2;
						when others =>
					end case;
					
					
					
					-- crossover operations
					if crossover_cntr<crossover_size then
						case( crossover_type ) is
							when one_point =>
								-- apply one point crossover
								parallel_op_crossover0 : for i in 0 to gene_length-1 loop
									if conv_integer(crossover_rnd(random_numbit_gene-1 downto 0))>i then
										new_indiv_c(i):=generation(crossover_index0).chromosome(i);
										new_indiv_c2(i):=generation(crossover_index1).chromosome(i);
									else
										new_indiv_c(i):=generation(crossover_index1).chromosome(i);
										new_indiv_c2(i):=generation(crossover_index0).chromosome(i);
									end if;
								end loop ; -- parallel one point crossover

								fitness_generation(fitness_generation_last_main)<=new_indiv_c;
								fitness_generation(fitness_generation_last_main+1)<=new_indiv_c2;
								--fitness_generation_chromosomes(fitness_generation_last).chromosome:=new_indiv_c;
								fitness_generation_last_main:=fitness_generation_last_main+2;

								crossover_cntr:=crossover_cntr+2;
								mutation_indiv0:=new_indiv_c;
								mutation_indiv1:=new_indiv_c2;
								mutation_indiv_count:="10";
							when multiple_point =>
								-- apply multiple point crossover
								parallel_op_crossover1 : for i in 0 to gene_length-1 loop
									if crossover_rnd(i)='1' then
										new_indiv_c(i):=generation(crossover_index0).chromosome(i);
										new_indiv_c2(i):=generation(crossover_index1).chromosome(i);
									else
										new_indiv_c(i):=generation(crossover_index1).chromosome(i);
										new_indiv_c2(i):=generation(crossover_index0).chromosome(i);
									end if;
								end loop ; -- parallel one point crossover
								fitness_generation(fitness_generation_last_main)<=new_indiv_c;
								fitness_generation(fitness_generation_last_main+1)<=new_indiv_c2;
								--fitness_generation_chromosomes(fitness_generation_last).chromosome:=new_indiv_c;
								fitness_generation_last_main:=fitness_generation_last_main+2;
			
								crossover_cntr:=crossover_cntr+2;
								mutation_indiv0:=new_indiv_c;
								mutation_indiv1:=new_indiv_c2;
								mutation_indiv_count:="10";
							when external_crossover =>
								ext_cross_rst<='0';
								--ext_cross_rnd_number<=crossover_rnd;
								ext_cross_input0<=generation(crossover_index0).chromosome;
								ext_cross_input1<=new_indiv_c;
								new_indiv_c:=ext_cross_outputs;
								new_indiv_c2:=ext_cross_outputs2;
								if( ext_cross_output_ready='0' )then
									ext_cross_process_inputs<='1';
								else
									fitness_generation(fitness_generation_last_main)<=new_indiv_c;
									fitness_generation_last_main:=fitness_generation_last_main+1;
									crossover_cntr:=crossover_cntr+1;
									mutation_indiv0:=new_indiv_c;
									mutation_indiv_count:="01";
									if( ext_cross_output_ready2='1' )then
										fitness_generation(fitness_generation_last_main)<=new_indiv_c2;
										fitness_generation_last_main:=fitness_generation_last_main+1;
										crossover_cntr:=crossover_cntr+1;
										mutation_indiv1:=new_indiv_c2;
										mutation_indiv_count:="10";
									end if;
									ext_cross_process_inputs<='0';
									
								end if;
							when others =>
						end case ;
					end if ;

					-- mutations operations
					if mutation_cntr<mutation_size then
						case( mutation_type ) is
							when one_point_flip_bit =>
								if( mutation_indiv_count>"00" )then
									-- apply one point flipbit mutation
									parallel_op_mutation0 : for i in 0 to gene_length-1 loop
										if conv_integer(mutation_rnd(random_numbit_gene-1 downto 0))=i then
											new_indiv_m(i):=not mutation_indiv0(i);
										else
											new_indiv_m(i):=mutation_indiv0(i);
										end if;
									end loop ; -- parallel one point mutation
									fitness_generation(fitness_generation_last_main)<=new_indiv_m;
									fitness_generation_last_main:=fitness_generation_last_main+1;

									mutation_cntr:=mutation_cntr+1;
								end if;
							when multiple_point_flip_bit =>
								if( mutation_indiv_count>"00" )then
									-- apply multiple point mutation
									parallel_op_mutation1 : for i in 0 to gene_length-1 loop
										if mutation_rnd(i)='1' then
											new_indiv_m(i):=not mutation_indiv0(i);
										else
											new_indiv_m(i):=mutation_indiv0(i);
										end if;
									end loop ; -- parallel one point mutation
									fitness_generation(fitness_generation_last_main)<=new_indiv_m;
									fitness_generation_last_main:=fitness_generation_last_main+1;
									mutation_cntr:=mutation_cntr+1;
								end if;
							when one_point_random =>
								if( mutation_indiv_count>"00" )then-- apply one point random mutation
									parallel_op_mutation2 : for i in 0 to gene_length-1 loop
										if conv_integer(mutation_rnd(random_numbit_gene-1 downto 0))=i then
											new_indiv_m(i):=random_rnd;
										else
											new_indiv_m(i):=mutation_indiv0(i);
										end if;
									end loop ; -- parallel one point mutation
									fitness_generation(fitness_generation_last_main)<=new_indiv_m;
									fitness_generation_last_main:=fitness_generation_last_main+1;

									mutation_cntr:=mutation_cntr+1;
								end if;
							when multiple_point_random =>
								if( mutation_indiv_count>"00" )then
									-- apply multiple point mutation
									parallel_op_mutation3 : for i in 0 to gene_length-1 loop
										if mutation_rnd(i)='1' then
											new_indiv_m(i):=random_rnd;
										else
											new_indiv_m(i):=mutation_indiv0(i);
										end if;
									end loop ; -- parallel one point mutation
									fitness_generation(fitness_generation_last_main)<=new_indiv_m;
									fitness_generation_last_main:=fitness_generation_last_main+1;
									mutation_cntr:=mutation_cntr+1;
								end if;
							when external_mutation =>
								if( mutation_indiv_creation_state='0' )then
									if( mutation_indiv_count>"00" )then
										ext_mutation_rst<='0';
										--ext_mutation_rnd_number<=mutation_rnd;
										ext_mutation_input0<=mutation_indiv0;
										if( mutation_indiv_count="10" )then
											ext_mutation_input1<=mutation_indiv1;
										else
											ext_mutation_input1<=generation(crossover_index0).chromosome;
										end if;
									end if;
									mutation_indiv_creation_state:='1';
								else
									new_indiv_m:=ext_mutation_outputs;
									if( ext_mutation_output_ready='0' )then
										ext_mutation_process_inputs<='1';
									else
										fitness_generation(fitness_generation_last_main)<=new_indiv_m;
										--fitness_generation_chromosomes(fitness_generation_last).chromosome:=new_indiv_m;
										fitness_generation_last_main:=fitness_generation_last_main+1;

										mutation_cntr:=mutation_cntr+1;
										ext_mutation_process_inputs<='0';
										mutation_indiv_creation_state:='0';
									end if;
								end if;
							when others =>
						end case ;
						--if new_indiv_m(0)>=min_vals(0) and new_indiv_m(0)<=max_vals(0) then
						--	if new_indiv_m(1)>=min_vals(1) and new_indiv_m(1)<=max_vals(1) then
						--		mutation_indiv_creation_state:='0';
						--	end if;
						--end if;
						
					end if ;

					if( random_indiv_cntr<population_size-(elitism_size+crossover_size+mutation_size) )then
						case( random_type ) is
							when standard =>
								if random_gene_cntr<gene_length then -- yeni gen oluştur
									-- taşma kontrol ediliyor   floating  için geliştirilmediği için iptal ettim!!!!!
									--if random_rnd>=min_vals(random_gene_cntr) and random_rnd<=max_vals(random_gene_cntr) then
										new_indiv_r(random_gene_cntr):=random_rnd;-- yeni değeri ata
										random_gene_cntr:=random_gene_cntr+1;
									--end if ;
								end if;
								if random_gene_cntr=gene_length then -- gen oluşturma bitti ise fitness hesaplamak için queue'ya ekle
									fitness_generation(fitness_generation_last_main)<=new_indiv_r;
									--fitness_generation_chromosomes(fitness_generation_last).chromosome:=new_indiv_r;
									fitness_generation_last_main:=fitness_generation_last_main+1;

									random_gene_cntr:=0; -- yeni birey için pointerı sıfırla
									random_indiv_cntr:=random_indiv_cntr+1;  -- yeni birey üretimine geç  
								end if ;
							when external_random =>
								ext_random_rst<='0';
								--ext_random_rnd_number<=random_rnd;
								new_indiv_r:=ext_random_outputs;
								if( ext_random_output_ready='0' )then
									ext_random_process_inputs<='1';
								else
									fitness_generation(fitness_generation_last_main)<=new_indiv_r;
									--fitness_generation_chromosomes(fitness_generation_last).chromosome:=new_indiv_r;
									fitness_generation_last_main:=fitness_generation_last_main+1;

									ext_random_process_inputs<='0';
									random_indiv_cntr:=random_indiv_cntr+1;  -- yeni birey üretimine geç  
								end if;
						end case ;	
					end if;
					if (elitist_cntr+crossover_cntr+mutation_cntr+random_indiv_cntr)>=population_size then
						inner_state:=WAIT_FOR_ALL_FINISH;
						next_state:=NEXT_GEN;
					end if ;
				when others => null;
			end case;
      ------------------------------------------------------------------------
			
			fitness_generation_last<=fitness_generation_last_main;
			
		end if;
	end process main_process;
	
	
	fitness_control_process : process(clk,fitness_control_rst)
		-- fitness modules vars
		variable fitness_generation_chromosomes 	: chromosome_type_array(population_size-1 downto 0);
		variable fitness_availables 				: type_active_fitness(fitness_module_count-1 downto 0);
		variable fitness_availables_temp 			: type_active_fitness(fitness_module_count-1 downto 0);
		variable fitness_available_size 			: integer range 0 to fitness_module_count+1;
		variable fitness_running 					: type_active_fitness(fitness_module_count-1 downto 0);
		variable fitness_running_temp 				: type_active_fitness(fitness_module_count-1 downto 0);
		variable fitness_queue_indiv 				: chromosome_type_array(fitness_module_count-1 downto 0);
		variable fitness_available_c 				: integer range 0 to fitness_module_count+1;
		variable fitness_generation_current 		: integer range 0 to population_size+1 :=0;
		variable feature_ext_last_indiv : ga_type_1d(gene_length-1 downto 0);  

		
		-- procedures
		procedure clearFitnessVars is
		begin
			fitness_available_size:=fitness_module_count;
			for i in 0 to fitness_module_count-1 loop
				fitness_availables(i):=i;
				fitness_process_inputs(i)<='0';
			end loop;
--			fitness_generation_last<=0;
			fitness_generation_current:=0;
		end clearFitnessVars;
		
	begin
	
		if( fitness_control_rst='1' )then
			-- fitness vars
			fitness_available_size:=fitness_module_count;
			for i in 0 to fitness_module_count-1 loop
				fitness_availables(i):=i;
				fitness_process_inputs(i)<='0';
			end loop;
			
			fitness_generation_current:=0;
			sorting_last_indiv<=0;
		elsif( clk'event and clk = '1' )then 

			-- if there is available fitness modules
			if fitness_available_size>0 then
				if fitness_generation_last>fitness_generation_current then
					fitness_inputs(fitness_availables(0))<=fitness_generation(fitness_generation_current);
					fitness_queue_indiv(fitness_availables(0)).chromosome:=fitness_generation(fitness_generation_current);--fitness_generation_chromosomes(fitness_generation_current).chromosome;
					fitness_process_inputs(fitness_availables(0))<='1';
					fitness_running(fitness_module_count-fitness_available_size):=fitness_availables(0);
					-- shift to erase 0
					fitness_availables_temp:=fitness_availables;
					activate0 : for i in 1 to fitness_module_count-1 loop
						fitness_availables(i-1):=fitness_availables_temp(i);
					end loop ; -- activate
					fitness_available_size:=fitness_available_size-1;
					fitness_generation_current:=fitness_generation_current+1;
				end if;
			end if;
			
			if( fitness_available_size<fitness_module_count )then
				fitness_available_c:=fitness_running(0);
				if fitness_out_ready(fitness_available_c)='1'  then
					sorting_queue(sorting_last_indiv).chromosome<=fitness_queue_indiv(fitness_available_c).chromosome;
					sorting_queue(sorting_last_indiv).fitness<=fitness_outputs(fitness_available_c);
					sorting_last_indiv<=sorting_last_indiv+1;
					-- re-calc available nn modules
					fitness_process_inputs(fitness_available_c)<='0';
					fitness_availables(fitness_available_size):=fitness_available_c;
					fitness_available_size:=fitness_available_size+1;
					-- shift to erase index 0
					fitness_running_temp:=fitness_running;
					running_shift0 : for i in 1 to fitness_module_count-1 loop
						fitness_running(i-1):=fitness_running_temp(i);
					end loop ; -- running_shift
				end if ;
			else
				sorting_add<='0';
			end if ;
		end if;
	end process fitness_control_process;
	

	sorting_process: process(clk,sorting_process_rst)
		-- sorted indivs
		
		variable sort_indiv_c 			: individual;
		variable sorting_current_indiv 	: integer range 0 to population_size+1 :=0;
		variable sorting_comp_pntr 		: integer range 0 to population_size+1 :=0;
		variable sorting_c_pntr 		: integer range 0 to population_size+1 :=0;
		variable sorting_comp_offset	: integer range 0 to population_size+1 :=0;
	begin
		if( sorting_process_rst='1' )then
			-- sorted indivs
			sorting_current_indiv:=0;
			sorted_cnt<=0;
			sorting_comp_offset:=0;
			--if( clear_all='1' )then
			--	clear_f : for i in 0 to generation_sorting'length-1 loop
			--		generation_sorting(i)<=(others => '0');
			--	end loop ; -- clear_f
			--end if;
		elsif( clk'event and clk = '1' )then 			
			if( sorting_add1='1' and sorting_elitism='0' )then
				elitist_pop : for i in 0 to elitism_size-1 loop
					generation_sorting(i)<=generation(i);
				end loop ; -- running_shift
				sorted_cnt<=elitism_size;
				sorting_elitism<='1';
				sorting_comp_offset:=0;
				--sorting_comp_offset:=population_size-1;
			elsif( sorting_add1='0' )then
				sorting_elitism<='0';
			end if;
			
			if( sorting_current_indiv<sorting_last_indiv )then
				sort_indiv_c:=sorting_queue(sorting_current_indiv);
				if( sorting_comp_offset=0 )then
					sorting_c_pntr:=sorted_cnt-sorting_comp_pntr;
				else
					sorting_c_pntr:=(sorting_comp_offset)-sorting_comp_pntr;	
				end if;
				if sorting_c_pntr>0 then
					if( FIND_MIN='1' )then
						if( (signed(sort_indiv_c.fitness)<signed(generation_sorting(sorting_c_pntr-1).fitness)) and (COMP_SIGNED='1') )then
							generation_sorting(sorting_c_pntr)<=generation_sorting(sorting_c_pntr-1); 
							sorting_comp_pntr:=sorting_comp_pntr+1;
						elsif( (sort_indiv_c.fitness)<(generation_sorting(sorting_c_pntr-1).fitness) and (COMP_SIGNED='0') )then
							generation_sorting(sorting_c_pntr)<=generation_sorting(sorting_c_pntr-1); 
							sorting_comp_pntr:=sorting_comp_pntr+1;
						else
							generation_sorting(sorting_c_pntr)<=sort_indiv_c;
							sorting_current_indiv:=sorting_current_indiv+1;
							sorting_comp_pntr:=0;
							sorted_cnt<=sorted_cnt+1;
						end if ;
					else
						if( (signed(sort_indiv_c.fitness)>signed(generation_sorting(sorting_c_pntr-1).fitness)) and (COMP_SIGNED='1') )then
							generation_sorting(sorting_c_pntr)<=generation_sorting(sorting_c_pntr-1); 
							sorting_comp_pntr:=sorting_comp_pntr+1;
						elsif( (sort_indiv_c.fitness)>(generation_sorting(sorting_c_pntr-1).fitness) and (COMP_SIGNED='0') )then
							generation_sorting(sorting_c_pntr)<=generation_sorting(sorting_c_pntr-1); 
							sorting_comp_pntr:=sorting_comp_pntr+1;
						else
							generation_sorting(sorting_c_pntr)<=sort_indiv_c;
							sorting_current_indiv:=sorting_current_indiv+1;
							sorting_comp_pntr:=0;
							sorted_cnt<=sorted_cnt+1;
						end if ;
					end if;
				else
					generation_sorting(0)<=sort_indiv_c;
					sorting_current_indiv:=sorting_current_indiv+1;
					sorting_comp_pntr:=0;
					sorted_cnt<=sorted_cnt+1;
				end if;
			else
				sorting_comp_pntr:=0;
			end if ;
		end if;
	end process sorting_process;
	
	
	
	-- definiton of fitness components
	fitness_module_array : for i in 0 to fitness_module_count-1 generate
	begin
		fitness_module : fitness port map(	  
			-- input signals to control if the module is ready to process
			inputs 			=> fitness_inputs(i),
			process_inputs 	=> fitness_process_inputs(i),
			-- output signals to 
			output_ready 	=> fitness_out_ready(i),
			output 			=> fitness_outputs(i),
			-- clk and reset signals
			clk 			=> clk,
			rst 			=> fitness_rst);
	end generate; -- fitness_module_array


	-- definition of external init module connections
	ext_init_module : ext_init port map(
		-- input signals to control if the module is ready to process
		rnd_number	 	=> ext_init_rnd_number,
		process_inputs 	=> ext_init_process_inputs,
		imin_vals 		=> min_vals,
		imax_vals 		=> max_vals,

		-- output signals to 
		output_ready 	=> ext_init_output_ready,
		outputs       	=> ext_init_outputs,

		-- clk and reset signals
		clk 			=> clk,
		rst 			=> ext_init_rst);                -- reset signal of module

	-- definition of external crossover module connections
	ext_cross_module : ext_crossover port map(
		-- input signals to control if the module is ready to process
		input0			=> ext_cross_input0,
		input1			=> ext_cross_input1,
		rnd_number		=> crossover_rnd,
		process_inputs	=> ext_cross_process_inputs,

		-- output signals to 
		output_ready	=> ext_cross_output_ready,
		outputs			=> ext_cross_outputs,
		output_ready2	=> ext_cross_output_ready2,
		outputs2		=> ext_cross_outputs2,

		-- clk and reset signals
		clk 			=> clk,
		rst 			=> ext_cross_rst);                -- reset signal of module


	-- definition of external mutation module connections
	ext_mutation_module : ext_mutation port map(
		-- input signals to control if the module is ready to process
		input0			=> ext_mutation_input0,
		input1			=> ext_mutation_input1,
		rnd_number		=> mutation_rnd,
		process_inputs	=> ext_mutation_process_inputs,

		-- output signals to 
		output_ready	=> ext_mutation_output_ready,
		outputs			=> ext_mutation_outputs,

		-- clk and reset signals
		clk 			=> clk,
		rst 			=> ext_mutation_rst);                -- reset signal of module


	-- definition of external init module connections
	ext_random_module : ext_random port map(
		-- input signals to control if the module is ready to process
		rnd_number	 	=> random_rnd,
		process_inputs 	=> ext_random_process_inputs,
		imin_vals 		=> min_vals,
		imax_vals 		=> max_vals,

		-- output signals to 
		output_ready 	=> ext_random_output_ready,
		outputs       	=> ext_random_outputs,

		-- clk and reset signals
		clk 			=> clk,
		rst 			=> ext_random_rst);                -- reset signal of module


	-- definitions of random number generator
	--clk_rnd<=clk ;--and enable_rnd_clk;
	--rand : randnumbgen generic map (
	--	method             => LFSR,
	--	output_number_bits => random_number_bits)
	--port map (
	--	clk  => clk_rnd,
	--	rst  => rst_rnd,
	--	seed => seed_rnd,
	--	res  => res_rnd);
		
	clk_rnd<=clk ;--and enable_rnd_clk;
	
	--crossover_rnd:=res_rnd(gene_length-1 downto 0);
	rand_crossover : randnumbgen generic map (
		method             => random_method,
		output_number_bits => gene_length)
	port map (
		clk  => clk_rnd,
		rst  => rst_rnd,
		seed => seed_crossover_rnd,
		res  => crossover_rnd);

	--mutation_rnd:=res_rnd(gene_length*2-1 downto gene_length);
	rand_mutation: randnumbgen generic map (
		method             => random_method,
		output_number_bits => gene_length)
	port map (
		clk  => clk_rnd,
		rst  => rst_rnd,
		seed => seed_mutation_rnd,
		res  => mutation_rnd);
		
	--random_rnd:=res_rnd(gene_length*2+gene_bit_width-1 downto gene_length*2);	
--	rand_random: randnumbgen generic map (
--		method             => random_method,
--		output_number_bits => gene_bit_width)
--	port map (
--		clk  => clk_rnd,
--		rst  => rst_rnd,
--		seed => seed_random_rnd,
--		res  => random_rnd);
	rand_random: randnumbgenfloat generic map (
		method             => random_method,
		output_number_bits => gene_bit_width)
	port map (
		clk  => clk_rnd,
		rst  => rst_rnd,
		seed => seed_random_rnd,
		res  => random_rnd);
		
	--select0_rnd:=res_rnd(gene_length*2+gene_bit_width+random_selection_bitwidth-1 downto gene_length*2+gene_bit_width);
	rand_select0: randnumbgen generic map (
		method             => random_method,
		output_number_bits => random_selection_bitwidth)
	port map (
		clk  => clk_rnd,
		rst  => rst_rnd,
		seed => seed_select0_rnd,
		res  => select0_rnd);
		
	--select1_rnd:=res_rnd(gene_length*2+gene_bit_width+random_selection_bitwidth*2-1 downto gene_length*2+gene_bit_width+random_selection_bitwidth);	
	rand_select1: randnumbgen generic map (
		method             => random_method,
		output_number_bits => random_selection_bitwidth)
	port map (
		clk  => clk_rnd,
		rst  => rst_rnd,
		seed => seed_select1_rnd,
		res  => select1_rnd);	
	
	--select2_rnd:=res_rnd(gene_length*2+gene_bit_width+random_selection_bitwidth*3-1 downto gene_length*2+gene_bit_width+random_selection_bitwidth*2);
	rand_select2: randnumbgen generic map (
		method             => random_method,
		output_number_bits => random_selection_bitwidth)
	port map (
		clk  => clk_rnd,
		rst  => rst_rnd,
		seed => seed_select2_rnd,
		res  => select2_rnd);	
	
	--select3_rnd:=res_rnd(gene_length*2+gene_bit_width+random_selection_bitwidth*4-1 downto gene_length*2+gene_bit_width+random_selection_bitwidth*3);
	rand_select3: randnumbgen generic map (
		method             => random_method,
		output_number_bits => random_selection_bitwidth)
	port map (
		clk  => clk_rnd,
		rst  => rst_rnd,
		seed => seed_select3_rnd,
		res  => select3_rnd);
	
	
end behav;
