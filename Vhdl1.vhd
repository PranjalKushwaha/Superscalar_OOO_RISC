library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all; 

entity InsFetch is
Port(	clk,rst : in std_logic;
		if_freeze : in std_logic;  -- freeze if set to 1, only ex modifiable.
		pc_overwrite : in std_logic; -- overwrites the internal pc with pc_inp if set to 1(for jump instructions), only ex modifiable.
		ins_loading: in std_logic;
		pc_inp : in std_logic_vector(5 downto 0);
		ins_mem_out1 : in std_logic_vector(15 downto 0);
		ins_mem_out2 : in std_logic_vector(15 downto 0);
		--mem_address1 : out std_logic_vector(5 downto 0);
		--mem_address2 : out std_logic_vector(5 downto 0);
		pipe_reg1 : out std_logic_vector(15 downto 0);
		pipe_reg2 : out std_logic_vector(15 downto 0);
		ins_pc1 : out std_logic_vector(5 downto 0));
		ins_pc2 : out std_logic_vector(5 downto 0));
end InsFetch;

architecture load of InsFetch is

signal pc : std_logic_vector(5 downto 0):="000000";

begin 
	process(clk)
		begin
			if rising_edge(clk) then
				if if_freeze = '0' then
					if pc_overwrite = '0' then
						if rst = '1' then
							pc <= "000000";
						else
							if ins_loading = '0' then
								--mem_address1 <= pc;
								ins_pc1 <= pc; --read the program counter
								pc <= pc+'1'; --then update
								pipe_reg1 <= ins_mem_out1;
								--mem_address2 <= pc;
								ins_pc2 <= pc;
								pc <= pc+'1';
								pipe_reg2 <= ins_mem_out2;
							end if;
						end if;
					elsif pc_overwrite = '1' then
							pc <= pc_inp;
					end if;
				end if;
			end if;
	end process;
end load;