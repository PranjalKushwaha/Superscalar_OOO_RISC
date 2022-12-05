library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity memory is
generic(ram_size: integer := 64);
	port (
		clk : in std_logic;
		address : in std_logic_vector(integer(ceil(log2(real(ram_size))))-1 downto 0); -- For data retrieval
		loading_address : in std_logic_vector(integer(ceil(log2(real(ram_size))))-1 downto 0); -- Used to load program initially
		mem_loading: in std_logic;		-- flag for initial loading
		mode: in std_logic;					-- read/write
		toStore: in std_logic_vector(15 downto 0);   -- Data to be written
		toInitLoad: in std_logic_vector(15 downto 0);-- Data for the initial loading
		mem_out_1 : out std_logic_vector(15 downto 0);
		mem_out_2 : out std_logic_vector(15 downto 0)
	);
end memory;

architecture mem of memory is

type mem_type is array ( 0 to (ram_size-1) ) of std_logic_vector(15 downto 0);
signal ram : mem_type := (others=>(others => '0'));

begin 
	process(address,loading_address,mem_loading,mode,toStore,toInitLoad)
	begin
		if mem_loading = '1' then			-- initial loading of memory, if required
			ram(to_integer(unsigned(loading_address))) <= toInitLoad;
		else                    				-- can't use memory while loading
			if mode='0' then					-- reading from mem
				mem_out_1 <= ram(to_integer(unsigned(address)));
				mem_out_2 <= ram(to_integer(unsigned(address))+1);
			elsif mode='1' then					-- writing to mem
				ram(to_integer(unsigned(address))) <= toStore;
			end if;
		end if;
	end process;

end mem;