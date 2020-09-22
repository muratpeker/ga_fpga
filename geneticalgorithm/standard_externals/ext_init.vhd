library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library work;
use work.types.all;

entity ext_init is
port (
	-- input signals to control if the module is ready to process
	rnd_number	 	: in 	std_logic_vector(gene_bit_width-1 downto 0);
	process_inputs 	: in 	std_logic;
	imin_vals 		: in	ga_type_1d(gene_length-1 downto 0);
	imax_vals 		: in	ga_type_1d(gene_length-1 downto 0);

	-- output signals to 
	output_ready 	: out 	std_logic;
	outputs       	: out 	ga_type_1d(gene_length-1 downto 0);      -- output of ext_init individual

	-- clk and reset signals
	clk : in std_logic;                 -- clock for ext_init module
	rst : in std_logic);                -- reset signal of module
end ext_init;

architecture beh of ext_init is
begin  -- beh
	-- purpose: ext_init calculator module
	-- inputs : clk, rst
	-- outputs: 
	main : process (clk, rst)
		type states is (GET_INPUT,SEND_OUTPUT);
		variable state : states :=GET_INPUT;
		variable init_gene_cntr : integer range 0 to gene_length+1 :=0;
	begin  -- process main
		if rst = '1' then                   -- asynchronous reset (active low)
			output_ready <= '0';
			state := GET_INPUT;
			init_gene_cntr:=0;
		-----------------------------------------------------------------------------
		elsif clk'event and clk = '1' then  -- rising clock edge
			-- Process clocks
			case state is
				when GET_INPUT =>
					if( process_inputs='1' )then
		    			if init_gene_cntr<gene_length then -- yeni gen oluştur
		    				output_ready<='0';
							-- taşma kontrol ediliyor floating point  için geçici olarak kaldırdım
							--if rnd_number>=imin_vals(init_gene_cntr) and rnd_number<=imax_vals(init_gene_cntr) then
								-- yeni değeri ata
								outputs(init_gene_cntr)<=rnd_number;
								init_gene_cntr:=init_gene_cntr+1;
							--end if ;
						else -- gen oluşturma bitti ise fitness hesaplamak için queue'ya ekle
							state:=SEND_OUTPUT;
		    				output_ready<='1';
						end if ;		    			
		    		end if;
		    	---------------------------------------------------------------------------
				when SEND_OUTPUT =>
					output_ready<='1';
			        --if( process_inputs='0' )then
			        	output_ready<='0';
						state:=GET_INPUT;
						init_gene_cntr:=0;
					--end if;
				--------------------------------------------------------------------------- 
				when others => null;
			end case;
		end if;
	end process main;
end beh;
