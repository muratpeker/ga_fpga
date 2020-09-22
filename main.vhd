library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--- sim
use std.textio.all;
use IEEE.STD_LOGIC_TEXTIO.ALL;

library work;
use work.types.all;

entity GA is
  port (
    CLOCK_50 : in  std_logic;                       -- 50MHz clock
    SW       : in  std_logic_vector(17 downto 0);   -- input switches
    LEDR     : out std_logic_vector(17 downto 0);  -- output red leds
    LEDG     : out std_logic_vector(7 downto 0);  -- output green leds

    -- UART ports
    UART_CTS : out std_logic;
    UART_RTS : in std_logic;
    UART_RXD : in std_logic;
    UART_TXD : out std_logic;

    GPIO : out std_logic_vector(7 downto 0) );
end GA;

architecture arch_ga of GA is

  type states 		  is (WAIT_SWITCH,
							GA_STEPS,
							WAIT_CLCK);
  type inner_states is (INIT,
							SRUN,
							SWAIT,
							SEND);

  component GeneticAlgorithm
	generic (
		population_size 		: integer                            	:= 5;  		-- population size of GA
		-- edit ga_type_1d type in types package
		chromosome_size 		: integer                            	:= gene_length;	-- size of features to search for
		elitism_size    		: integer                            	:= 1;  			-- elitism size of GA
		crossover_size  		: integer                            	:= 1;  			-- crossover size of GA
		mutation_size   		: integer                            	:= 1;  			-- mutation_size of GA
		init_type  				: init_types 							:= external_init;  
		crossover_type  		: crossover_types                    	:= external_crossover;  	-- 0 for one_point crossover
		mutation_type   		: mutation_types                     	:= one_point_flip_bit;  	-- 0 for Flip bit mutation
		random_type   			: random_types 							:= external_random;  	-- 
		fitness_module_count 	: integer                       		:= 1;
		fitness_goal			: ga_type_fitness						:= conv_std_logic_vector(0,ga_type_fitness'length);
		-- range must be chromesome_size-1 downto 0
		min_vals        		: ga_type_1d(gene_length-1 downto 0) 	:= (others => conv_std_logic_vector(0, gene_bit_width));  	-- minimum value of each chromosome
		max_vals        		: ga_type_1d(gene_length-1 downto 0) 	:= (others => conv_std_logic_vector(1, gene_bit_width)));	-- maximum value of each chromosome
	port (
		elapsed_time			: out std_logic_vector(31 downto 0);
		best_indiv 				: out ga_type_indiv_array(res_size-1 downto 0);
		ready_out 				: out std_logic;
		max_it_reached     		: out std_logic;
		max_fitness_reached		: out std_logic;
		continues 				: in std_logic;		-- if 0 then after one step generation waits for continues signal
		it_counter				: out integer range 0 to 65535	:= 0;

		clk 					: in std_logic;		-- clock for GA
		rst 					: in std_logic);	-- reset signal for GA  
  end component;
  signal ga_continues 	: std_logic;
  signal ga_rst 		: std_logic;
  signal ga_ready 		: std_logic;
  signal ga_max_it		: std_logic;
  signal ga_max_fit		: std_logic;
  signal ga_elapsed 	: std_logic_vector(31 downto 0);
  signal ga_best 		: ga_type_indiv_array(res_size-1 downto 0);
  signal ready_out  	: std_logic;
  signal iteration_cntr : integer range 0 to 65535	:= 0;

  -- FUNCTIONS --
begin  -- arch_ga

  -- purpose: main process of GA algorithm
  -- type   : sequential
  -- inputs : CLOCK_50, SW[0]
  -- outputs: outs
  main_process : process (CLOCK_50, SW(0))
  
	file 	 gen	: text is out "~/sim/generation.txt";
	variable tline	: line;
	variable input_0    : std_logic_vector(gene_length-1 downto 0);
	
    variable state			: states :=WAIT_SWITCH;
    variable inner_state	: inner_states :=SRUN;
    variable cntr 			: integer range 0 to 1000000000 :=0;
    variable ga_run_counter : integer :=0;
    variable elapsed_cntr 	: integer :=0;
    variable elapsed_cntr1 	: integer :=0;


    procedure changeState (
        istate 				: in	states;
        iinner_state 		: in	inner_states) is
    begin
      state					:=istate;
      inner_state			:=iinner_state;
    end changeState;

    variable pstate_next : states;
    variable pinner_state_next : inner_states;
    variable state_next : states;
    variable inner_state_next : inner_states;
    variable wait_clk : integer :=2;
    variable delay_counter : integer:=0;
    procedure waitClk (
        clk_count : in integer;
        pstate_next : in states;
        pinner_state_next : in inner_states ) is
    begin
      delay_counter:=0;
      state_next:=pstate_next;
      inner_state_next:=pinner_state_next;
      state:=WAIT_CLCK;
    end waitClk;

    procedure resetGA is
    begin
      ga_rst<='1';
    end resetGA;

    procedure initStepGA is
    begin
      ga_rst<='0';
      ga_continues<='0';
    end initStepGA;

  begin  -- process main_process
    if SW(0) = '1' then                 -- asynchronous reset (active low)
      -- clear leds
      LEDR(17 downto 0) <= (others => '0');
      LEDG <= (others => '0');
      LEDR(17)<='1';

      -- reset GA module
      resetGA;

      -- reset states
      state:=GA_STEPS;
      inner_state:=INIT;

      --iteration_cntr<=conv_std_logic_vector(0,32);
    elsif CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
      case( state ) is
        -----------------------------------------------------
        when WAIT_SWITCH =>
          if SW(1) = '1' then
            state:=GA_STEPS; 
            inner_state:=INIT;
          end if;
        when GA_STEPS =>
        case( inner_state ) is
            when INIT =>
				initStepGA;
				inner_state:=SRUN;
				ga_continues<='0';
				write(tline,res_size); --1
				writeline(gen,tline);

				write(tline,pop_size); --2
				writeline(gen,tline);

				write(tline,elt_size); --3
				writeline(gen,tline);

				write(tline,cross_size); --4
				writeline(gen,tline);

				write(tline,mut_size); --5
				writeline(gen,tline);

				--selection_types			is (, sroulette,stournament);
				--init_types 				is (random, external_init);
				--crossover_types 		is (one_point, multiple_point, external_crossover);
				--mutation_types 			is (one_point_flip_bit,multiple_point_flip_bit,external_mutation);
				--random_types 			is (standard,external_random);	
				case( sel_type ) is
					when srandom =>
						write(tline,0); --6
						writeline(gen,tline);
					when stournament =>
						write(tline,1); --6
						writeline(gen,tline);
					when sroulette =>
						write(tline,2); --6
						writeline(gen,tline);
					when others =>
						write(tline,-1); --6
						writeline(gen,tline);
				end case ;
				
				case( initialization_type ) is
					when random =>
						write(tline,0); --7
						writeline(gen,tline);
					when external_init =>
						write(tline,1); --7
						writeline(gen,tline);
					when others =>
						write(tline,-1); --7
						writeline(gen,tline);
				end case ;

				case( cross_type ) is
					when one_point =>
						write(tline,0); --8
						writeline(gen,tline);
					when multiple_point =>
						write(tline,1); --8
						writeline(gen,tline);
					when external_crossover =>
						write(tline,2); --8
						writeline(gen,tline);
					when others =>
						write(tline,-1); --8
						writeline(gen,tline);
				end case ;

				case( mut_type ) is
					when one_point_flip_bit =>
						write(tline,0); --9
						writeline(gen,tline);
					when multiple_point_flip_bit =>
						write(tline,1); --9
						writeline(gen,tline);
					when external_mutation =>
						write(tline,2); --9
						writeline(gen,tline);
					when others =>
						write(tline,-1); --9
						writeline(gen,tline);
				end case ;
				
				case( rand_type ) is
					when standard =>
						write(tline,0); --10
						writeline(gen,tline);
					when external_random =>
						write(tline,1); --10
						writeline(gen,tline);
					when others =>
						write(tline,-1); --10
						writeline(gen,tline);
				end case ;
				write(tline,fit_size); --11
				writeline(gen,tline);
            when SRUN =>
				ga_continues<='0';
				if( ga_ready='1' )then
					parallel_write : for j in 0 to res_size-1 loop
						parallel_copy : for i in 0 to gene_length-1 loop
								input_0(i):=ga_best(j).chromosome(i)(0);
						end loop ; -- parallel one point mutation
						LEDG(0)<=ga_best(j).chromosome(0)(0);
						write(tline,(conv_integer(input_0)));
						writeline(gen,tline);
						write(tline,ga_best(j).fitness);
						writeline(gen,tline);
					end loop;
					ga_continues<='0';
					inner_state:=SWAIT;
				end if;
				
			when SWAIT =>
				ga_continues<='1';
				if( ga_max_it='1' or ga_max_fit='1' )then
					write(tline,conv_integer(ga_elapsed));
					writeline(gen,tline);
					write(tline,iteration_cntr);
					writeline(gen,tline);
					inner_state:=SEND;
				else
					inner_state:=SRUN;
				end if;
			when SEND =>
				inner_state:=SEND;
            when others =>
          end case ;
        -----------------------------------------------------
        when WAIT_CLCK =>
          delay_counter:=delay_counter+1;
          if( delay_counter>wait_clk )then
            inner_state:=inner_state_next;
            state:=state_next;
          end if ;
        -----------------------------------------------------
        when others =>
      end case ;
    end if;
  end process main_process;


  -- GA module
  GA : GeneticAlgorithm generic map(
    population_size       	=> pop_size,   		-- population size of GA
    chromosome_size       	=> gene_length,  	-- size of features to search for
    elitism_size          	=> elt_size,  		-- elitism size of GA
    crossover_size        	=> cross_size, 		-- crossover size of GA
    mutation_size         	=> mut_size, 		-- mutation_size of GA
--    init_type  				=> external_init, 
--    crossover_type        	=> external_crossover,      -- 0 for one_point crossover
--    mutation_type         	=> external_mutation,      -- 0 for Flip bit mutation
--    random_type   			=> external_random,  	-- 
	init_type  				=> initialization_type, 
    crossover_type        	=> cross_type,      -- 0 for one_point crossover
    mutation_type         	=> mut_type,      -- 0 for Flip bit mutation
    random_type   			=> rand_type,  	
    fitness_module_count  	=> fit_size,
	fitness_goal			=> fit_goal,
    -- range must be chromesome_size-1 downto 
--    min_vals              	=> ("000","000","000","000","000","000","000","000"),  -- minimum value of each chromosome
--    max_vals              	=> ("111","111","111","111","111","111","111","111") )
--	min_vals              	=> ("0","0","0","0","0","0","0","0"),  -- minimum value of each chromosome
--    max_vals              	=> ("1","1","1","1","1","1","1","1") )
	min_vals              	=> mi_vals,  -- minimum value of each chromosome
    max_vals              	=> ma_vals )
  port map(
    elapsed_time 		=> ga_elapsed,
    best_indiv 			=> ga_best,
    ready_out 			=> ga_ready,
	max_it_reached		=> ga_max_it,
	max_fitness_reached	=> ga_max_fit,
    continues 			=> ga_continues,   -- if 0 then after one step generation waits for continues signal
    it_counter			=> iteration_cntr,
    clk 				=> CLOCK_50,       -- clock for GA
    rst 				=> ga_rst
  );
end arch_ga;



