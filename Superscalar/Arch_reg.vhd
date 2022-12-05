library ieee;
use ieee.std_logic_1164.all;
entity arch_reg is 
	port(
		rst, write_reg : in std_logic;
		in_data : in std_logic_vector(15 DOWNTO 0);
		reg_map : in std_logic_vector(23 downto 0); --if any bit set to 1 => that Phy_reg maps to this reg
		out_data : out std_logic_vector(15 DOWNTO 0);
		out_map : out std_logic_vector(23 downto 0)
	);
end arch_reg;

architecture arc_arch_reg of arch_reg is
begin

	process(rst,in_data,write_reg)
	begin
	
		if rst='1' then		-- to prevent uninitialized output (red lines in simulation)
			out_data <= "0000000000000000";
			out_map <= "00000000000000000000000";
		else
			if write_reg='1' then
					out_data <= in_data;
					out_map <= reg_map;
			end if;
		end if;

	end process;
	 
end arc_arch_reg;