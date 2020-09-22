library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.types.all;

entity ext_crossover is
port (
	-- input signals to control if the module is ready to process
	input0			: in ga_type_1d(gene_length-1 downto 0);    -- inputs individual
	input1			: in ga_type_1d(gene_length-1 downto 0);    -- inputs individual
	rnd_number		: in std_logic_vector(gene_length-1 downto 0); -- genomes
	process_inputs	: in std_logic;

	-- output signals to 
	output_ready	: out std_logic;
	output_ready2	: out std_logic;
	outputs			: out ga_type_1d(gene_length-1 downto 0);      -- output of ext_crossover individual
	outputs2		: out ga_type_1d(gene_length-1 downto 0);      -- output of ext_crossover individual

	-- clk and reset signals
	clk : in std_logic;                 -- clock for ext_crossover module
	rst : in std_logic);                -- reset signal of module
end ext_crossover;

architecture beh of ext_crossover is
begin  
	-- beh
	-- purpose: ext_crossover calculator module
	-- inputs : clk, rst
	-- outputs: 
	main : process (clk, rst)
		type states is (GET_INPUT,SEND_OUTPUT);
		variable state : states :=GET_INPUT;
	begin  -- process main
		if rst = '1' then                   -- asynchronous reset (active low)
			output_ready <= '0';
			output_ready2 <= '0';
			state := GET_INPUT;
		-----------------------------------------------------------------------------
		elsif clk'event and clk = '1' then  -- rising clock edge
			-- Process clocks
			case state is
				when GET_INPUT =>
					if( process_inputs='1' )then
						-- apply one point ext_crossover
						parallel_op_ext_crossover0 : for i in 0 to gene_length-1 loop
							if conv_integer(rnd_number(random_numbit_gene-1 downto 0))=i then
								outputs(i)<=input0(i);
								outputs2(i)<=input1(i);
							else
								outputs(i)<=input1(i);
								outputs2(i)<=input0(i);
							end if;
						end loop ; -- parallel one point ext_crossover
					-----------------------------------------------------------------------
						state:=SEND_OUTPUT;
						output_ready<='1';
						output_ready2<='1';
					end if;
				---------------------------------------------------------------------------
				when SEND_OUTPUT =>
					output_ready<='0';
					output_ready2<='0';
					state:=GET_INPUT;
				--------------------------------------------------------------------------- 
				when others => null;
			end case;
		end if;
	end process main;
end beh;
