library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.types.all;

entity fitness is
	port (
		-- input signals to control if the module is ready to process
		inputs         : in ga_type_1d(gene_length-1 downto 0);    -- inputs for fitness function
		process_inputs : in  std_logic;

		-- output signals to 
		output_ready : out std_logic;
		output       : out ga_type_fitness;      -- output of fitness value

		-- clk and reset signals
		clk : in std_logic;                 -- clock for fitness module
		rst : in std_logic);                -- reset signal of module
end fitness;

architecture beh of fitness is
	signal aclr_mult_sig		: std_logic;
	signal dataa_mult_sig	: std_logic_vector(31 downto 0);
	signal datab_mult_sig	: std_logic_vector(31 downto 0);
	signal result_mult_sig	: std_logic_vector(31 downto 0);		
	component mult port (
		aclr	 : in std_logic;
		clock	 : in std_logic;
		dataa	 : in std_logic_vector(31 downto 0);
		datab	 : in std_logic_vector(31 downto 0);
		result	 : out std_logic_vector(31 downto 0)
	);
	end component;
	
	
	signal aclr_sub_sig		: std_logic;
	signal addsub_sig		: std_logic;
	signal dataa_sub_sig	: std_logic_vector(31 DOWNTO 0);
	signal datab_sub_sig	: std_logic_vector(31 DOWNTO 0);
	signal result_sub_sig	: std_logic_vector(31 DOWNTO 0);
	component sub port(
		aclr	 : in std_logic;
		clock	 : in std_logic;
		add_sub  : in std_logic;
		dataa	 : in std_logic_vector(31 DOWNTO 0);
		datab	 : in std_logic_vector(31 DOWNTO 0);
		result	 : out std_logic_vector(31 DOWNTO 0)
	);
	end component;
	
 

begin  -- beh

	-- purpose: Fitness function calculator module
	-- type   : sequential
	-- inputs : clk, rst
	-- outputs: 
	main : process (clk, rst)
		type		states	is (GET_INPUT,WAIT_MULT2,WAIT_MULT,WAIT_SUB,WAIT_SUB2,WAIT_SUB3,PROC_INPUTS,PROC_INPUTS1,SEND_OUTPUT);
		variable	state	: states :=GET_INPUT;
		
		variable	wait_cntr : integer := 0;
		variable	inner_cntr : integer := 0;
		variable	iter_cntr : integer := 0;
		
		variable	res		: std_logic_vector(31 downto 0);
		variable	res2	: std_logic_vector(31 downto 0);
		variable	sum		: std_logic_vector(31 downto 0);
		
		constant mult_clk : integer := 5;
		constant sub_clk : integer := 7;
	begin  -- process main
		if rst = '1' then                   -- asynchronous reset (active low)
			output_ready 	<= '0';
			state	:= GET_INPUT;
			aclr_sub_sig <= '1';
			aclr_mult_sig <= '1';
			inner_cntr := 0;
			iter_cntr := 0;
			wait_cntr := 0;
			addsub_sig <= '0';
		-----------------------------------------------------------------------------
		elsif clk'event and clk = '1' then  -- rising clock edge
			-- Process clocks
			case state is
				when GET_INPUT =>
					if( process_inputs='1' )then
						--state:=SEND_OUTPUT;
						state:=PROC_INPUTS;
						
						
						inner_cntr := 0;
						iter_cntr := 0;
						wait_cntr := 0;
						aclr_sub_sig <= '1';
						aclr_mult_sig <= '1';
						addsub_sig <= '0';
						sum:=(others=>'0');
						
						
						
						output_ready<='0';
					end if;
	  ---------------------------------------------------------------------------  
				when PROC_INPUTS =>
					if( iter_cntr<1 )then
						if( inner_cntr=0 )then
							dataa_mult_sig <= inputs(iter_cntr);
							datab_mult_sig <= inputs(iter_cntr);
							
							aclr_mult_sig <= '0';
							
							state:=WAIT_MULT;
						elsif( inner_cntr=1 )then
							aclr_sub_sig <= '0';
							dataa_sub_sig <= inputs(iter_cntr+1);
							datab_sub_sig <= res;
							addsub_sig <= '0';

							state:=WAIT_SUB;
						elsif( inner_cntr=2 )then
							aclr_mult_sig <= '0';
							dataa_mult_sig <= res;
							datab_mult_sig <= res;
		
							state:=WAIT_MULT;
						elsif( inner_cntr=3 )then
							aclr_mult_sig <= '0';
							dataa_mult_sig <= x"42c80000";
							datab_mult_sig <= res;

							state:=WAIT_MULT;
						elsif( inner_cntr=4 )then
							aclr_sub_sig <= '0';
							datab_sub_sig <= x"3f800000";
							dataa_sub_sig <= inputs(iter_cntr);
							addsub_sig <= '0';

							state:=WAIT_SUB2;
						elsif( inner_cntr=5 )then
							aclr_mult_sig <= '0';
							dataa_mult_sig <= res2;
							datab_mult_sig <= res2;

							state:=WAIT_MULT2;
						elsif( inner_cntr=6 )then
							aclr_sub_sig <= '0';
							dataa_sub_sig <= res;
							datab_sub_sig <= res2;
							addsub_sig <= '1';
							state:=WAIT_SUB;
						elsif( inner_cntr=7 )then
							aclr_sub_sig <= '0';
							dataa_sub_sig <= res;
							datab_sub_sig <= sum;
							addsub_sig <= '1';
							state:=WAIT_SUB3;
						end if;
					else
						state:=SEND_OUTPUT;
					end if;
				when WAIT_MULT =>
					wait_cntr := wait_cntr+1;
					if( wait_cntr>6 )then
						res := result_mult_sig;
						state:=PROC_INPUTS;
						inner_cntr:=inner_cntr+1;
						aclr_mult_sig <= '1';
						wait_cntr:=0;
					end if;
				when WAIT_MULT2 =>
					wait_cntr := wait_cntr+1;
					if( wait_cntr>6 )then
						res2 := result_mult_sig;
						state:=PROC_INPUTS;
						inner_cntr:=inner_cntr+1;
						aclr_mult_sig <= '1';
						wait_cntr:=0;
					end if;
				when WAIT_SUB =>
					wait_cntr := wait_cntr+1;
					if( wait_cntr>8 )then
						res := result_sub_sig;
						state:=PROC_INPUTS;
						inner_cntr:=inner_cntr+1;
						aclr_sub_sig <= '1';
						wait_cntr:=0;
					end if;
				when WAIT_SUB2 =>
					wait_cntr := wait_cntr+1;
					if( wait_cntr>8 )then
						res2 := result_sub_sig;
						state:=PROC_INPUTS;
						inner_cntr:=inner_cntr+1;
						aclr_sub_sig <= '1';
						wait_cntr:=0;
					end if;
				when WAIT_SUB3 =>
					wait_cntr := wait_cntr+1;
					if( wait_cntr>8 )then
						sum := result_sub_sig;
						state:=PROC_INPUTS;
						aclr_sub_sig <= '1';
						iter_cntr:=iter_cntr+1;
						inner_cntr:=0;
						wait_cntr:=0;
					end if;
	  ---------------------------------------------------------------------------    
				when SEND_OUTPUT =>
					output<=sum;
					--output<=output_value;
					output_ready<='1';
					if( process_inputs='0' )then
						output_ready<='0';
						state:=GET_INPUT;
					end if;
	  --------------------------------------------------------------------------- 
				when others => null;
			end case;
		end if;
	end process main;
	
	
	mult_inst : mult port map(
		aclr	 => aclr_mult_sig,
		clock	 => clk,
		dataa	 => dataa_mult_sig,
		datab	 => datab_mult_sig,
		result	 => result_mult_sig
	);

	sub_inst : sub port map(
		aclr	 => aclr_sub_sig,
		add_sub	 => addsub_sig,
		clock	 => clk,
		dataa	 => dataa_sub_sig,
		datab	 => datab_sub_sig,
		result	 => result_sub_sig
	);

	
	
end beh;
