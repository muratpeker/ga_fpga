library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.lfsr_pkg.all;
use work.types.all;

-- this module generates -single precision values between -50 and 50
entity RandNumbGenFloat is
  generic (
    method        : method_types := LFSR;  -- select the random number generation type
    -- pseudo random sequence generator (PRSG)
    -- linear feedback shift register (LFSR)
    exponent_width:integer:=5;
	output_number_bits : integer := 32);  --output-number-bit-width
	
  port (
    clk  : in  std_logic;  -- clock for random number generator module
    rst  : in  std_logic;               -- reset signal
    seed : in  std_logic_vector(output_number_bits-1 downto 0);    -- seed value
    res  : out std_logic_vector(output_number_bits-1 downto 0));  -- output generated random value
end RandNumbGenFloat;


architecture behaviour of RandNumbGenFloat is
begin  -- arch
  -- purpose: main process controls flow of module
  -- type   : sequential
  -- inputs : clk, rst
  -- outputs: res
  main_proc : process (clk, rst)
	constant e_bit:integer:=4;
	variable rand_temp_exponent : std_logic_vector(e_bit-1 downto 0) := (e_bit-1 => '1', others => '0');
	variable rand_temp_exponent_01 : std_logic_vector(6-1 downto 0) := (6-1 => '1', others => '0');
	variable rand_temp_mantissa : std_logic_vector(22 downto 0) := (22 => '1', others => '0');
    --variable rand_temp : std_logic_vector(output_number_bits-1 downto 0) := (output_number_bits-1 => '1', others => '0');
    variable temp      : std_logic                                       := '0';
  begin  -- process main_proc
    if rst = '1' then                   -- asynchronous reset (active low)
      --rand_temp := seed;
	  rand_temp_exponent:="0101";
	  rand_temp_exponent_01:="101110";
	  rand_temp_mantissa:=seed(22 downto 0);
      temp      := '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
		if method = PRSG then
			--temp                                  := rand_temp(output_number_bits-1) xor rand_temp(output_number_bits-2);
			temp                                    := rand_temp_exponent(e_bit-1) xor rand_temp_exponent(e_bit-2);
			rand_temp_exponent(e_bit-1 downto 1)			:= rand_temp_exponent(e_bit-2 downto 0);
			rand_temp_exponent(0)					:= temp;
			
			temp                                    := rand_temp_exponent_01(6-1) xor rand_temp_exponent_01(6-2);
			rand_temp_exponent_01(6-1 downto 1)		:= rand_temp_exponent_01(6-2 downto 0);
			rand_temp_exponent_01(0)				:= temp;
		
		
			temp                                    := rand_temp_mantissa(22) xor rand_temp_mantissa(21);
			rand_temp_mantissa(22 downto 1)			:= rand_temp_mantissa(21 downto 0);
			rand_temp_mantissa(0)					:= temp;
		
			res(22 downto 0) <= rand_temp_mantissa;
		elsif method = LFSR then
			temp                                    := xor_gates(rand_temp_exponent);
			rand_temp_exponent(e_bit-1 downto 1) 		:= rand_temp_exponent(e_bit-2 downto 0);
			rand_temp_exponent(0)					:= temp;
		
			temp                                    := xor_gates(rand_temp_exponent_01);
			rand_temp_exponent_01(6-1 downto 1) 	:= rand_temp_exponent_01(6-2 downto 0);
			rand_temp_exponent_01(0)				:= temp;
		
			temp                                    := xor_gates(rand_temp_mantissa);
			rand_temp_mantissa(22 downto 1) 		:= rand_temp_mantissa(21 downto 0);
			rand_temp_mantissa(0)					:= temp;
			res(22 downto 0) <= rand_temp_mantissa;
		end if;
		if( rand_temp_exponent(e_bit-1)='0' )then
			if( conv_integer(rand_temp_exponent(e_bit-2 downto 0))=0 )then
				res(31 downto 23)	<= "000000000";--0
			elsif( conv_integer(rand_temp_exponent(e_bit-2 downto 0))=1 )then
				res(31 downto 23)	<= "001" & rand_temp_exponent_01;--0-1
			elsif( conv_integer(rand_temp_exponent(e_bit-2 downto 0))=2 )then
				res(31 downto 23)	<= "001111111";--1.2
			elsif( conv_integer(rand_temp_exponent(e_bit-2 downto 0))=3 )then
				res(31 downto 23)	<= "010000000";--2-5
			elsif( conv_integer(rand_temp_exponent(e_bit-2 downto 0))>=4 and conv_integer(rand_temp_exponent(e_bit-2 downto 0))<=7 )then
				res(31 downto 23)	<= "010000001";--5.10
			--elsif( conv_integer(rand_temp_exponent(e_bit-2 downto 0))>=8 and conv_integer(rand_temp_exponent(e_bit-2 downto 0))<=15 )then
			--	res(31 downto 23)	<= "010000010";--10-20
			--elsif( conv_integer(rand_temp_exponent(e_bit-2 downto 0))>=16 and conv_integer(rand_temp_exponent(e_bit-2 downto 0))<=31 )then
			--	res(31 downto 23)	<= "010000011";--20.35
			end if;
		elsif( rand_temp_exponent(e_bit-1)='1' )then
			if( conv_integer(rand_temp_exponent(e_bit-2 downto 0))=0 )then
				res(31 downto 23)	<= "100000000";--0
			elsif( conv_integer(rand_temp_exponent(e_bit-2 downto 0))=1 )then
				res(31 downto 23)	<= "101" & rand_temp_exponent_01;--0-1
			elsif( conv_integer(rand_temp_exponent(e_bit-2 downto 0))=2 )then
				res(31 downto 23)	<= "101111111";--1.2
			elsif( conv_integer(rand_temp_exponent(e_bit-2 downto 0))=3 )then
				res(31 downto 23)	<= "110000000";--2-5
			elsif( conv_integer(rand_temp_exponent(e_bit-2 downto 0))>=4 and conv_integer(rand_temp_exponent(e_bit-2 downto 0))<=7 )then
				res(31 downto 23)	<= "110000001";--5.10
			--elsif( conv_integer(rand_temp_exponent(e_bit-2 downto 0))>=8 and conv_integer(rand_temp_exponent(e_bit-2 downto 0))<=15 )then
			--	res(31 downto 23)	<= "110000010";--10-20
			--elsif( conv_integer(rand_temp_exponent(e_bit-2 downto 0))>=16 and conv_integer(rand_temp_exponent(e_bit-2 downto 0))<=31 )then
			--	res(31 downto 23)	<= "110000011";--20.35
			end if;
		end if;
    end if;
  end process main_proc;
  
end behaviour;
