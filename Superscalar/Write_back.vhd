library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity write_back is
port (
	clk,rst, init_store: in std_logic;
	add : in std_logic_vector(5 downto 0);
	data : in std_logic_vector(15 downto 0);
	mem_mode : out std_logic;
	data_out : out std_logic_vector(15 downto 0);
	address_out : out std_logic(5 downto 0);
);
end entity;

architecture write_arch of write_back is
begin
process(clk)
	if falling_edge(clk) then --rising edge used by fetch stage
		if init_store = '1' then
			address_out <= add;
			mem_mode <= '1';
			data_out <= data;
		end if;
	end if
end process;
end architecture;