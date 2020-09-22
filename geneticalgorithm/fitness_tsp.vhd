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
  

begin  -- beh

	-- purpose: Fitness function calculator module
	-- type   : sequential
	-- inputs : clk, rst
	-- outputs: 
	main : process (clk, rst)

		type		states	is (GET_INPUT,PROC_INPUTS,SEND_OUTPUT);
		variable	state	: states :=GET_INPUT;

		variable 	input_0    : std_logic_vector(gene_length-1 downto 0);
		type 		integer_array	is array (natural range<>) of integer range 0 to 8;
		variable 	input_vals : integer_array(7 downto 0) ;

		-- 1  16.47       96.10
		-- 2  16.47       94.44
		-- 3  20.09       92.54
		-- 4  22.39       93.37
		-- 5  25.23       97.24
		-- 6  22.00       96.05
		-- 7  20.47       97.02
		-- 8  17.20       96.29
		subtype 	location	is integer range 0 to 655535;
		type		city_record is record
					x 				: location;
					y  				: location;
		end record;
		type 		city_array	is array (natural range<>) of city_record;
		variable 	cities		: city_array(7 downto 0);
		variable	dist		: std_logic_vector(31 downto 0);

	begin  -- process main
		if rst = '1' then                   -- asynchronous reset (active low)
			output_ready 	<= '0';
			state	:= GET_INPUT;

			-- 1  16.47       96.10
			cities(0).x:=1647;
			cities(0).y:=9610;
			-- 2  16.47       94.44
			cities(1).x:=1647;
			cities(1).y:=9444;
			-- 3  20.09       92.54
			cities(2).x:=2009;
			cities(2).y:=9254;
			-- 4  22.39       93.37
			cities(3).x:=2239;
			cities(3).y:=9337;
			-- 5  25.23       97.24
			cities(4).x:=2523;
			cities(4).y:=9724;
			-- 6  22.00       96.05
			cities(5).x:=2200;
			cities(5).y:=9605;
			-- 7  20.47       97.02
			cities(6).x:=2047;
			cities(6).y:=9702;
			-- 8  17.20       96.29
			cities(7).x:=1720;
			cities(7).y:=9629;
			
			dist:=(others=>'0');
		-----------------------------------------------------------------------------
		elsif clk'event and clk = '1' then  -- rising clock edge
			-- Process clocks
			case state is
				when GET_INPUT =>
					if( process_inputs='1' )then
						dist:=(others=>'0');
						input_vals(0):=(conv_integer(inputs(0)));
						input_vals(1):=(conv_integer(inputs(1)));
						input_vals(2):=(conv_integer(inputs(2)));
						input_vals(3):=(conv_integer(inputs(3)));
						input_vals(4):=(conv_integer(inputs(4)));
						input_vals(5):=(conv_integer(inputs(5)));
						input_vals(6):=(conv_integer(inputs(6)));
						input_vals(7):=(conv_integer(inputs(7)));

						dist:=dist+(cities(input_vals(0)).x-cities(input_vals(1)).x)*(cities(input_vals(0)).x-cities(input_vals(1)).x)+ (cities(input_vals(0)).y-cities(input_vals(1)).y)*(cities(input_vals(0)).y-cities(input_vals(1)).y);
						dist:=dist+(cities(input_vals(1)).x-cities(input_vals(2)).x)*(cities(input_vals(1)).x-cities(input_vals(2)).x)+ (cities(input_vals(1)).y-cities(input_vals(2)).y)*(cities(input_vals(1)).y-cities(input_vals(2)).y);
						dist:=dist+(cities(input_vals(2)).x-cities(input_vals(3)).x)*(cities(input_vals(2)).x-cities(input_vals(3)).x)+ (cities(input_vals(2)).y-cities(input_vals(3)).y)*(cities(input_vals(2)).y-cities(input_vals(3)).y);
						dist:=dist+(cities(input_vals(3)).x-cities(input_vals(4)).x)*(cities(input_vals(3)).x-cities(input_vals(4)).x)+ (cities(input_vals(3)).y-cities(input_vals(4)).y)*(cities(input_vals(3)).y-cities(input_vals(4)).y);
						dist:=dist+(cities(input_vals(4)).x-cities(input_vals(5)).x)*(cities(input_vals(4)).x-cities(input_vals(5)).x)+ (cities(input_vals(4)).y-cities(input_vals(5)).y)*(cities(input_vals(4)).y-cities(input_vals(5)).y);
						dist:=dist+(cities(input_vals(5)).x-cities(input_vals(6)).x)*(cities(input_vals(5)).x-cities(input_vals(6)).x)+ (cities(input_vals(5)).y-cities(input_vals(6)).y)*(cities(input_vals(5)).y-cities(input_vals(6)).y);
						dist:=dist+(cities(input_vals(6)).x-cities(input_vals(7)).x)*(cities(input_vals(6)).x-cities(input_vals(7)).x)+ (cities(input_vals(6)).y-cities(input_vals(7)).y)*(cities(input_vals(6)).y-cities(input_vals(7)).y);
						dist:=dist+(cities(input_vals(7)).x-cities(input_vals(0)).x)*(cities(input_vals(7)).x-cities(input_vals(0)).x)+ (cities(input_vals(7)).y-cities(input_vals(0)).y)*(cities(input_vals(7)).y-cities(input_vals(0)).y);

						state:=SEND_OUTPUT;
						output_ready<='1';
						
						output<=dist;
					end if;
	  ---------------------------------------------------------------------------  
				when PROC_INPUTS =>
					state:=SEND_OUTPUT;
	  ---------------------------------------------------------------------------    
				when SEND_OUTPUT =>
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
end beh;
