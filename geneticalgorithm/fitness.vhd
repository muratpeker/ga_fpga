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
	signal lut_in	: std_logic_vector(15 downto 0);
	signal lut_out	: std_logic_vector(15 downto 0);
	component LUT port (
		inputs		: in std_logic_vector(15 downto 0);    
		output		: out std_logic_vector(15 downto 0);   
		clk			: in std_logic);
	end component;

begin  -- beh

	-- purpose: Fitness function calculator module
	-- type   : sequential
	-- inputs : clk, rst
	-- outputs: 
	main : process (clk, rst)
		type		states	is (GET_INPUT,PROC_INPUTS,PROC_INPUTS1,SEND_OUTPUT);
		variable	state	: states :=GET_INPUT;

		
		variable input_0    : std_logic_vector(gene_length-1 downto 0);
		variable input_val  : integer;
	begin  -- process main
		if rst = '1' then                   -- asynchronous reset (active low)
			output_ready 	<= '0';
			state	:= GET_INPUT;
			lut_in<=(others=>'0');
		-----------------------------------------------------------------------------
		elsif clk'event and clk = '1' then  -- rising clock edge
			-- Process clocks
			case state is
				when GET_INPUT =>
					if( process_inputs='1' )then
						--state:=SEND_OUTPUT;
						state:=PROC_INPUTS;
						output_ready<='0';
						parallel_copy : for i in 0 to gene_length-1 loop
							input_0(i):=inputs(i)(0);
						end loop ; -- parallel one point mutation
						
						lut_in<=input_0;
						--output<=(input_0*input_0);
						--input_val:=conv_integer(input_0);
						--input_val:=(input_val*input_val);
						--output<=conv_std_logic_vector(input_val,output'length);
					end if;
	  ---------------------------------------------------------------------------  
				when PROC_INPUTS =>
					output<=lut_out;
					state:=PROC_INPUTS1;
				when PROC_INPUTS1 =>
					output<=lut_out;
					state:=SEND_OUTPUT;
	  ---------------------------------------------------------------------------    
				when SEND_OUTPUT =>
					output<=lut_out;
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
	
	
	lut_fitness: lut port map(
		inputs => lut_in,
		output => lut_out,
		clk => clk
	);
	
	
	
	
end beh;
