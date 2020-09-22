library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library work;
use work.lfsr_pkg.all;
use work.types.all;


entity RandNumbGen is
  generic (
    method        : method_types := LFSR;  -- select the random number generation type
    -- pseudo random sequence generator (PRSG)
    -- linear feedback shift register (LFSR)
    output_number_bits : integer := 8);  --output-number-bit-width
  port (
    clk  : in  std_logic;  -- clock for random number generator module
    rst  : in  std_logic;               -- reset signal
    seed : in  std_logic_vector(output_number_bits-1 downto 0);    -- seed value
    res  : out std_logic_vector(output_number_bits-1 downto 0));  -- output generated random value
end RandNumbGen;


architecture behaviour of RandNumbGen is
begin  -- arch
  -- purpose: main process controls flow of module
  -- type   : sequential
  -- inputs : clk, rst
  -- outputs: res
  main_proc : process (clk, rst)
    variable rand_temp : std_logic_vector(output_number_bits-1 downto 0) := (output_number_bits-1 => '1', others => '0');
    variable temp      : std_logic                                       := '0';
  begin  -- process main_proc
    if rst = '1' then                   -- asynchronous reset (active low)
      rand_temp := seed;
      temp      := '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      if method = PRSG then
        temp                                     := rand_temp(output_number_bits-1) xor rand_temp(output_number_bits-2);
        rand_temp(output_number_bits-1 downto 1) := rand_temp(output_number_bits-2 downto 0);
        rand_temp(0)                             := temp;
        res                                      <= rand_temp;
      elsif method = LFSR then
        temp                                     := xor_gates(rand_temp);
        rand_temp(output_number_bits-1 downto 1) := rand_temp(output_number_bits-2 downto 0);
        rand_temp(0)                             := temp;
        res                                      <= rand_temp;
      end if;
    end if;
  end process main_proc;
  
end behaviour;
