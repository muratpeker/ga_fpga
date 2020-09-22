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
	-- purpose: ext_crossover calculator modulefor TSP
	-- inputs : clk, rst
	-- outputs: 
	main : process (clk, rst)
		type states is (GET_INPUT,PROC,PROC2,SEND_OUTPUT);
		variable state : states :=GET_INPUT;

		subtype  type_pool			is integer range 0 to gene_length+1;
		type     type_pool_array	is array (natural range<>) of type_pool;

		variable cross_gene_cntr 	: integer range 0 to gene_length+1 :=0;
		variable rnd_int 			: integer range 0 to gene_length+1 :=0;
		variable last_ind 			: integer range 0 to gene_length+1 :=0;
		variable pool_val_cntr		: integer range 0 to gene_length+1 :=0;
		variable pool				: std_logic_vector(gene_length-1 downto 0);
		variable pool_val			: type_pool_array(gene_length-1 downto 0);
		variable cross_gene_it		: integer range 0 to gene_length+1 :=0;
	begin  -- process main
		if rst = '1' then                   -- asynchronous reset (active low)
			output_ready <= '0';
			output_ready2 <= '0';
			state:=GET_INPUT;

			cross_gene_cntr:=0;
			parallel_setup : for i in 0 to gene_length-1 loop
				pool(i):='0';
			end loop;
			pool_val_cntr:=0;
		-----------------------------------------------------------------------------
		elsif clk'event and clk='1' then  -- rising clock edge
			output_ready2 <= '0';
			-- Process clocks
			case state is
				when GET_INPUT =>
					if( process_inputs='1' )then
						rnd_int:=conv_integer(rnd_number(gene_bit_width-1 downto 0));
						parallel_copy : for i in 0 to gene_length-1 loop
							if( i<rnd_int )then
								outputs(i)<=input0(i);
								pool(conv_integer(input0(i))):='1';
							end if;
						end loop;
						state:=PROC;
					end if;
				when PROC =>
					pool_val_cntr:=0;
					parallel_copy1 : for i in 0 to gene_length-1 loop
						if( i>=rnd_int )then
							if( pool(conv_integer(input1(i)))='0' )then
								outputs(i)<=input1(i);
								pool(conv_integer(input1(i))):='1';
							else
								pool_val(pool_val_cntr):=i;
								pool_val_cntr:=pool_val_cntr+1;
							end if;
						end if;
					end loop;

					state:=PROC2;
				when PROC2 =>
					pool_val_cntr:=0;
					parallel_copy2 : for i in 0 to gene_length-1 loop
						if( pool(i)='0' )then
							outputs(pool_val(pool_val_cntr))<=conv_std_logic_vector(i,gene_bit_width);
							pool_val_cntr:=pool_val_cntr+1;
						end if;
					end loop;

					cross_gene_it:=0;
					output_ready<='1';
					state:=SEND_OUTPUT;
				---------------------------------------------------------------------------
				when SEND_OUTPUT =>
					output_ready<='0';
					state:=GET_INPUT;
					cross_gene_cntr:=0;
					pool_val_cntr:=0;
					parallel_setup1 : for i in 0 to gene_length-1 loop
						pool(i):='0';
					end loop;
				--------------------------------------------------------------------------- 
				when others => null;
			end case;
		end if;
	end process main;
end beh;
