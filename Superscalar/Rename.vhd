library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity rename is 
	port(
		rst : in std_logic;
		reg_mapout :in std_logic_vector(119 downto 0);
		pr_a1 : in std_logic_vector(2 downto 0);--addr of reg in instr
		pr_a2 : in std_logic_vector(2 downto 0);--addr of reg in instr
		create_regmap :out std_logic; --connect to regfile create_reg_map
      prev_rename_addr1 :out integer;	-- rename register addr if its previously renamed (connect to regfile regnum)
		prev_rename_addr2:out integer
	   );
end rename;

architecture rename_arch of rename  is
 signal prev_renamereg1 : integer;
 signal prev_renamereg2 : integer;
 signal create_reg_map : std_logic;
 
type reg_map_vec is array (0 to 23) of std_logic_vector(5 downto 0);  -- map data for phy regs, if bit num 0=1=> reg is mapped
signal reg_map : reg_map_vec;
begin

process(pr_a1,pr_a2, rst)
begin 
	if rst = '1' then
		prev_renamereg1 <= 0;
		prev_renamereg2 <= 0;
		create_reg_map <='0';
	else
		for i in 0 to 119 loop
			reg_map(i/5)((i mod 5)+1)<=reg_mapout(i);
		end loop;
	 
		for i in 0 to 23 loop
			if to_integer(unsigned(reg_map(i)(5 downto 1))) = to_integer(unsigned(pr_a1)) then --checking if the register is already renamed
				prev_renamereg1 <= i;
				exit;
			else
				prev_renamereg1 <=to_integer(unsigned(pr_a1)); --if pr_a is not mapped
			end if;
		end loop; 
		prev_rename_addr1 <= prev_renamereg1; 

		for i in 0 to 23 loop
			if to_integer(unsigned(reg_map(i)(5 downto 1))) = to_integer(unsigned(pr_a2)) then --checking if the register is already renamed
				prev_renamereg2 <= i;
				exit;
			else
				prev_renamereg2 <=to_integer(unsigned(pr_a2)); --if pr_a is not mapped
			end if;
		end loop; 
		create_regmap <= '1';
		prev_rename_addr2 <= prev_renamereg2; 
	end if;
end process;

end architecture; 