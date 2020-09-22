library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library work;
use work.types.all;

entity crossover is
  port (
      -- input signals to control if the module is ready to process
      input0         : in ga_type_1d(gene_length-1 downto 0);    -- inputs individual
	  input1         : in ga_type_1d(gene_length-1 downto 0);    -- inputs individual
	  crossover_type : in crossover_types := one_point;
	  rnd_number	 : in std_logic_vector(gene_length-1 downto 0); -- genomes
      process_inputs : in std_logic;
	  
      -- output signals to 
      output_ready : out std_logic;
      output       : out ga_type_1d(gene_length-1 downto 0);      -- output of crossover individual

      -- clk and reset signals
      clk : in std_logic;                 -- clock for crossover module
      rst : in std_logic);                -- reset signal of module
end crossover;

architecture beh of crossover is
begin  -- beh
  -- purpose: crossover calculator module
  -- inputs : clk, rst
  -- outputs: 
  main : process (clk, rst)
    type states is (GET_INPUT,PROCESS_INPUTS,SEND_OUTPUT);
    variable state : states :=GET_INPUT;
  begin  -- process main
    if rst = '1' then                   -- asynchronous reset (active low)
      output_ready 	<= '0';
      state	:= GET_INPUT;
	-----------------------------------------------------------------------------
    elsif clk'event and clk = '1' then  -- rising clock edge
      -- Process clocks
	  case state is
      when GET_INPUT =>
		if process_inputs='1' then
			state:=PROCESS_INPUTS;
			output_ready<='0';
		end if ;
      ---------------------------------------------------------------------------  
	  when PROCESS_INPUTS =>
		case( crossover_type ) is
            when one_point =>
				-- apply one point crossover
				parallel_op_crossover : for i in 0 to gene_length-1 loop
					if conv_std_logic_vector(i, gene_length)<=rnd_number then
						output(i)<=input0(i);
					else
						output(i)<=input1(i);
					end if;
				end loop ; -- parallel one point crossover
				output_ready<='1';
				state:=GET_INPUT;
            when multiple_point =>
            when others => null;
        end case ;
      ---------------------------------------------------------------------------    
	  when SEND_OUTPUT =>
		--output<=output_value;
		output_ready<='1';
		state:=GET_INPUT;
      --------------------------------------------------------------------------- 
	  when others => null;
      end case;
    end if;
  end process main;
end beh;
