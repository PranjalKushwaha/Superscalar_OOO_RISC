library ieee;
use ieee.std_logic_1164.all;
entity reg is 
	port(
		rst, write_reg : in std_logic;
		in_data : in std_logic_vector(15 DOWNTO 0);
		out_data : out std_logic_vector(15 DOWNTO 0)
	);
end reg;

architecture arc_reg of reg is

begin

	process(rst,in_data,write_reg)
	begin
	
		if rst='1' then		-- to prevent uninitialized output (red lines in simulation)
			out_data <= "0000000000000000";
		
		else
			if write_reg='1' then
					out_data <= in_data;
			end if;
		end if;

	end process;
	 
end arc_reg;