library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

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
	signal dataa_mult_sig	: std_logic_vector(63 downto 0);
	signal datab_mult_sig	: std_logic_vector(63 downto 0);
	signal result_mult_sig	: std_logic_vector(63 downto 0);		
	component mult port (
		aclr	 : in std_logic;
		clock	 : in std_logic;
		dataa	 : in std_logic_vector(63 downto 0);
		datab	 : in std_logic_vector(63 downto 0);
		result	 : out std_logic_vector(63 downto 0)
	);
	end component;
	
	
	signal aclr_sub_sig		: std_logic;
	signal addsub_sig		: std_logic;
	signal dataa_sub_sig	: std_logic_vector(63 DOWNTO 0);
	signal datab_sub_sig	: std_logic_vector(63 DOWNTO 0);
	signal result_sub_sig	: std_logic_vector(63 DOWNTO 0);
	component sub port(
		aclr	 : in std_logic;
		clock	 : in std_logic;
		add_sub  : in std_logic;
		dataa	 : in std_logic_vector(63 DOWNTO 0);
		datab	 : in std_logic_vector(63 DOWNTO 0);
		result	 : out std_logic_vector(63 DOWNTO 0)
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
		
		variable	res		: std_logic_vector(39 DOWNTO 0);
		variable	res2	: std_logic_vector(15 DOWNTO 0);
		variable	sum		: std_logic_vector(39 DOWNTO 0);
		
		constant mult_clk : integer := 5;
		variable yuz : integer := 100;
		constant sub_clk : integer := 7;
		type 		integer_array	is array (natural range<>) of integer ;
		variable 	input_vals : integer_array(9 downto 0) ;
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
						yuz:=100;
						
						
						output_ready<='0';
						input_vals(0):=(conv_integer(inputs(0)));
						input_vals(1):=(conv_integer(inputs(1)));
						input_vals(2):=(conv_integer(inputs(2)));
						input_vals(3):=(conv_integer(inputs(3)));
						input_vals(4):=(conv_integer(inputs(4)));
						input_vals(5):=(conv_integer(inputs(5)));
						input_vals(6):=(conv_integer(inputs(6)));
						input_vals(7):=(conv_integer(inputs(7)));
						input_vals(8):=(conv_integer(inputs(8)));
						input_vals(9):=(conv_integer(inputs(9)));
					end if;
	  ---------------------------------------------------------------------------  
				when PROC_INPUTS =>
					if( iter_cntr<9 )then
						res:=(inputs(iter_cntr+1)-(inputs(iter_cntr)*inputs(iter_cntr)))*(inputs(iter_cntr+1)-(inputs(iter_cntr)*inputs(iter_cntr)))* x"64";
						res2:=(1-inputs(iter_cntr))*(1-inputs(iter_cntr));
						sum:=sum+res2+res;
						iter_cntr:=iter_cntr+1;
					else
						state:=SEND_OUTPUT;
					end if;
	  ---------------------------------------------------------------------------    
				when SEND_OUTPUT =>
					output<=sum;--conv_std_logic_vector(sum,fitness_bit_width);
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
