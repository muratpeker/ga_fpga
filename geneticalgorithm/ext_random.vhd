library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.types.all;

entity ext_random is
port (
	-- input signals to control if the module is ready to process
	rnd_number	 	: in 	std_logic_vector(gene_bit_width-1 downto 0);
	process_inputs 	: in 	std_logic;
	imin_vals 		: in	ga_type_1d(gene_length-1 downto 0);
	imax_vals 		: in	ga_type_1d(gene_length-1 downto 0);

	-- output signals to 
	output_ready 	: out 	std_logic;
	outputs       	: out 	ga_type_1d(gene_length-1 downto 0);      -- output of ext_random individual

	-- clk and reset signals
	clk : in std_logic;                 -- clock for ext_random module
	rst : in std_logic);                -- reset signal of module
end ext_random;

architecture beh of ext_random is
begin  -- beh
	-- purpose: ext_random calculator module
	-- inputs : clk, rst
	-- outputs: 
	main : process (clk, rst)
		type states is (GET_INPUT,SEND_OUTPUT);
		variable state : states :=GET_INPUT;
		variable random_gene_cntr : integer range 0 to gene_length+1 :=0;
		variable rnd_int 		: integer range 0 to gene_length+1 :=0;
		variable last_ind 		: integer range 0 to gene_length+1 :=0;
		variable pool			: std_logic_vector(gene_length-1 downto 0);
	begin  -- process main
		if rst = '1' then                   -- asynchronous reset (active low)
			output_ready <= '0';
			state := GET_INPUT;
			random_gene_cntr:=0;
			parallel_setup : for i in 0 to gene_length-1 loop
				pool(i):='0';
			end loop;
		-----------------------------------------------------------------------------
		elsif clk'event and clk = '1' then  -- rising clock edge
			-- Process clocks
			case state is
				when GET_INPUT =>
					if( process_inputs='1' )then
						if( random_gene_cntr<gene_length )then
							rnd_int:=conv_integer(rnd_number);
							if( pool(rnd_int)='0' )then
								outputs(random_gene_cntr)<=rnd_number;
								random_gene_cntr:=random_gene_cntr+1;
								pool(rnd_int):='1';
							elsif( random_gene_cntr=gene_length-1 )then
								last_ind:=0;
								parallel_setup0 : for i in 0 to gene_length-1 loop
									if( pool(i)='0' )then
										last_ind:=i;
									end if;
								end loop;
								outputs(random_gene_cntr)<=conv_std_logic_vector(last_ind,gene_bit_width);
								random_gene_cntr:=random_gene_cntr+1;
								pool(last_ind):='1';
							end if;
						else
							state:=SEND_OUTPUT;
		    				output_ready<='1';
						end if;
		    		end if;
		    	---------------------------------------------------------------------------
				when SEND_OUTPUT =>
			       	output_ready<='0';
					state:=GET_INPUT;
					random_gene_cntr:=0;
					parallel_setup1 : for i in 0 to gene_length-1 loop
						pool(i):='0';
					end loop;
				--------------------------------------------------------------------------- 
				when others => null;
			end case;
		end if;
	end process main;
end beh;
