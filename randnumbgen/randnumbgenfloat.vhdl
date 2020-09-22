library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library work;
use work.lfsr_pkg.all;
use work.types.all;

-- this module generates -double precision values between -50 and 50
entity RandNumbGenFloat is
  generic (
    method        : method_types := LFSR;  -- select the random number generation type
    -- pseudo random sequence generator (PRSG)
    -- linear feedback shift register (LFSR)
    exponent_width:integer:=4;
	output_number_bits : integer := 64);  --output-number-bit-width
	
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
	variable rand_temp_exponent : std_logic_vector(4-1 downto 0) := (4-1 => '1', others => '0');
	variable rand_temp_mantissa : std_logic_vector(51 downto 0) := (51 => '1', others => '0');
    --variable rand_temp : std_logic_vector(output_number_bits-1 downto 0) := (output_number_bits-1 => '1', others => '0');
    variable temp      : std_logic                                       := '0';
  begin  -- process main_proc
    if rst = '1' then                   -- asynchronous reset (active low)
      --rand_temp := seed;
	  rand_temp_exponent:="0110";
	  rand_temp_mantissa:=seed(51 downto 0);
      temp      := '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      if method = PRSG then
        --temp                                  := rand_temp(output_number_bits-1) xor rand_temp(output_number_bits-2);
		temp                                    := rand_temp_exponent(4-1) xor rand_temp_exponent(4-2);
        rand_temp_exponent(4-1 downto 1)			:= rand_temp_exponent(4-2 downto 0);
        rand_temp_exponent(0)					:= temp;
		
		
		temp                                    := rand_temp_mantissa(51) xor rand_temp_mantissa(50);
        rand_temp_mantissa(51 downto 1)			:= rand_temp_mantissa(50 downto 0);
        rand_temp_mantissa(0)					:= temp;
		
		res(51 downto 0) <= rand_temp_mantissa;
      elsif method = LFSR then
		temp                                     := xor_gates(rand_temp_exponent);
        rand_temp_exponent(4-1 downto 1) := rand_temp_exponent(4-2 downto 0);
        rand_temp_exponent(0)                         := temp;
		
		temp                                     := xor_gates(rand_temp_mantissa);
        rand_temp_mantissa(51 downto 1) := rand_temp_mantissa(50 downto 0);
        rand_temp_mantissa(0)                         := temp;
        res(51 downto 0) <= rand_temp_mantissa;
      end if;
	  case(rand_temp_exponent)is
		when "0001"=>
			res(63 downto 52)	<= "001111111111";--1.2
		when "0010"=>
			res(63 downto 52)	<= "010000000000";--2-5
		when "0011"=>
			res(63 downto 52)	<= "010000000001";--5.10
		when "0100"=>
			res(63 downto 52)	<= "010000000010";--10-20
		when "0101"=>
			res(63 downto 52)	<= "010000000011";--20.35
		when "0110"=>
			res(63 downto 52)	<= "010000000100";--35.63
		when "0111"=>
			res(63 downto 52)	<= "101111111111";--1.2
		when "1000"=>
			res(63 downto 52)	<= "110000000000";--2-5
		when "1001"=>
			res(63 downto 52)	<= "110000000001";--5.10
		when "1010"=>
			res(63 downto 52)	<= "110000000010";--10-20
		when "1011"=>
			res(63 downto 52)	<= "110000000011";--20.35
		when "1100"=>
			res(63 downto 52)	<= "110000000100";--35.63
		when "1101"=>
			res(63 downto 52)	<= "001111111111";--1.2
		when "1110"=>
			res(63 downto 52)	<= "010000000000";--2-5
		when "1111"=>
			res(63 downto 52)	<= "000000000000";--0
		when others =>
			res(63 downto 52)	<= "110000000010";--10-20
		end case ;
    end if;
  end process main_proc;
  
end behaviour;
