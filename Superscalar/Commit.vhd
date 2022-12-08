library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Commit is
port 
(
	clk,rst : in std_logic;
	reg_1,reg_2 : in integer; -- Reg nums from rob
	data_1,data_2 : in std_logic_vector(15 downto 0); -- values from rob
	z1,z2,c1,c2 : in std_logic; -- Zero and carry flags for 2 instructions passed from exec to rob and then here
	fd1,fd2,fz1,fz2 : in std_logic; -- Flags is: data_1, data_2 ,(z1 and c1) ,(z2 and c2) in that order need to be written (0 for instructions that do not write to reg(no-op) or do not set zero/carry bit);
	pc1,pc2 : in std_logic_vector(5 downto 0); -- pc values of instructions whose  zero and carry are sent
	
	cdb1 ,cdb2: out integer;  --Common Data Bus variables to communicate with reservation
	cdb_data1 ,cdb_data2: out std_logic_vector(15 downto 0);
	cdb_pc1, cdb_pc2 : out std_logic_vector(6 downto 0);
	cdb_z1,cdb_z2,cdb_c1,cdb_c2 : out std_logic;

	wd1,wd2 : out std_logic;
	reg_num1 : out integer; -- Regfile writing variables
	reg_num2 : out integer;
	write_val1 : out std_logic_vector(15 downto 0); 
	write_val2 : out std_logic_vector(15 downto 0);
	create_reg_map : out std_logic; -- if 1 => search for free phy_regs, create a reg_map from reg_num and return mapped reg number
	free_reg : out std_logic
);
end entity;

architecture writeRf of Commit is
begin
process(clk)
begin
	if falling_edge(clk) then
		if fd1 = '1' then
			create_reg_map <= '0';
			free_reg <= '1';
			write_val1 <= data_1;
			wd1 <= '1';
			reg_num1 <= reg_1;
			cdb1 <= reg_1;
			cdb_data1 <= data_1;
		else 
			create_reg_map <= '0';
			free_reg <= '0';
		end if;

		if fd2 = '1' then
			create_reg_map <= '0';
			free_reg <= '1';
			write_val2 <= data_2;
			wd2 <= '1';
			reg_num2 <= reg_2;
			cdb2 <= reg_2;
			cdb_data2 <= data_2;
		else 
			create_reg_map <= '0';
			free_reg <= '0';
		end if;
		if fz1 = '1' then
			cdb_z1 <= z1;
			cdb_c1 <= c1;
			cdb_pc1(0) <= '1';
			cdb_pc1(6 downto 1) <= pc1;
		end if;
		if fz2 = '1' then
			cdb_z2 <= z2;
			cdb_c2 <= c2;
			cdb_pc2(0) <= '1';
			cdb_pc2(6 downto 1) <= pc2;
		end if;

	end if;
end process;
end architecture;