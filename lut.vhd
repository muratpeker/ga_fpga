library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;


entity LUT is
	port (
		inputs		: in std_logic_vector(15 downto 0);    
		output		: out std_logic_vector(15 downto 0);   
		clk			: in std_logic);
end LUT;

architecture beh of LUT is
	type mem_array is array(0 to 65535) of  std_logic_vector(15 downto 0);

	--f2=mBF6_ 2(x)=4096 + ([(x 2 + x) ∗ cos(x)]/220 ),
		--0 ≤ x ≤ 65535.

	--f3=mBF7_2(x, y)=32768 + (56 ∗ [x ∗ sin(4x) + 1.25 ∗ y ∗ sin(2y)]) ,
		--0 ≤ x, y ≤ 255

	-- function computes contents of cosine lookup ROM
	function init_rom return mem_array is
		variable memx	: mem_array;
		variable fx		: real;
		variable x		: real;
		variable y		: real;
		variable sum1	: real;
		variable sum2	: real;
	begin
		for i in 0 to 255 loop
			j_loop : for j in 0 to 255 loop
				x:=(real(i));
				y:=(real(j));
				sum1:=real(0);
				sum2:=real(0);
				k_loop : for k in 1 to 5 loop
					sum1:=real(k)*cos(real(k)+real(1))*x+real(k);
					sum2:=real(k)*cos(real(k)+real(1))*y+real(k);
				end loop;
				fx:=real(65535)-(real(174)*( real(150)+(sum1*sum2) ));
				memx(integer(x)+integer(y)*256) := conv_std_logic_vector(integer(fx),16);
			end loop ; -- j_loop
		end loop;
		return memx;
	end function init_rom;
 
	constant rom : mem_array := init_rom;
begin
	main : process (clk)
	begin  -- process main
		if clk'event and clk = '1' then  -- rising clock edge
			output<= rom(conv_integer(inputs(15 downto 8))+conv_integer(inputs(7 downto 0))*256);
		end if;
	end process main;
end beh;

