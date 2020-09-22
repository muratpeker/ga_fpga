library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.types.all;

entity ext_mutation is
port (
	-- input signals to control if the module is ready to process
	input0      	: in ga_type_1d(gene_length-1 downto 0);    -- inputs individual
	input1      	: in ga_type_1d(gene_length-1 downto 0);    -- inputs individual
	rnd_number    	: in std_logic_vector(gene_length-1 downto 0); -- genomes
	process_inputs  : in std_logic;

	-- output signals to 
	output_ready  	: out std_logic;
	outputs     	: out ga_type_1d(gene_length-1 downto 0);      -- output of ext_mutation individual

	-- clk and reset signals
	clk : in std_logic;                 -- clock for ext_mutation module
	rst : in std_logic);                -- reset signal of module
end ext_mutation;

architecture beh of ext_mutation is
begin  
	-- beh
	-- purpose: ext_mutation calculator module
	-- inputs : clk, rst
	-- outputs: 
	main : process (clk, rst)
		type states is (GET_INPUT,SEND_OUTPUT);
		variable state : states :=GET_INPUT;

		variable rnd_int 			: integer range 0 to gene_length+1 :=0;
		variable rnd_int2 			: integer range 0 to gene_length+1 :=0;
	begin  -- process main
		if rst = '1' then                   -- asynchronous reset (active low)
			output_ready <= '0';
			state := GET_INPUT;
			-----------------------------------------------------------------------------
		elsif clk'event and clk = '1' then  -- rising clock edge
			-- Process clocks
			case state is
				when GET_INPUT =>
				if( process_inputs='1' )then
					rnd_int:=conv_integer(rnd_number(gene_bit_width-1 downto 0));
					rnd_int2:=conv_integer(rnd_number(gene_bit_width*2-1 downto gene_bit_width));
					if(rnd_int/=rnd_int2)then
						parallel_copy : for i in 0 to gene_length-1 loop
							outputs(i)<=input0(i);
						end loop;
						outputs(rnd_int2)<=input0(rnd_int);
						outputs(rnd_int)<=input0(rnd_int2);
						-----------------------------------------------------------------------
						state:=SEND_OUTPUT;
						output_ready<='1';
					end if;
				end if;
				---------------------------------------------------------------------------
				when SEND_OUTPUT =>
					output_ready<='0';
					state:=GET_INPUT;
				--------------------------------------------------------------------------- 
				when others => null;
			end case;
		end if;
	end process main;
end beh;
