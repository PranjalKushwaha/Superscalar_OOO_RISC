library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity regFile is
generic(num_reg: integer := 32);
	port(
		rst : in std_logic;
		write_regFile : in std_logic;		-- control signal for writing into RF  , if 0  read value from  reg_num register
		reg_num : in integer; -- Register to write/read value 
		read_1 : in integer;
		read_2 : in integer;
		read_3 : in integer;
		read_4 : in integer;
		write_val : in std_logic_vector(15 downto 0); -- Value to be written
	
		create_reg_map : in std_logic; -- if 1 => search for free phy_regs, create a reg_map from reg_num and return mapped reg number
		free_reg : in std_logic; -- if 1=> free reg and clear maps  also commits the reg value to its arch register
		reg_val_1 : out std_logic_vector(15 downto 0); -- value read from reg_num
		reg_val_2 : out std_logic_vector(15 downto 0);
		reg_val_3 : out std_logic_vector(15 downto 0);
		reg_val_4 : out std_logic_vector(15 downto 0);
		mapped_reg : out integer; -- mapped address
		reg_mapout :out std_logic_vector(119 downto 0)--for renaming
	);

end entity;

--

architecture arcRF of regFile is

	component reg is
		port(
			rst, write_reg : in std_logic;
			in_data : in std_logic_vector(15 DOWNTO 0);
			out_data : out std_logic_vector(15 DOWNTO 0)
		);
	end component;


type reg_map_vec is array (0 to 23) of std_logic_vector(5 downto 0);  -- map data for phy regs, if bit num 0=1=> reg is mapped
	signal reg_map : reg_map_vec;

type regArr is array(0 to 31) of std_logic_vector(15 downto 0);
	signal regs: regArr;
	
	
	-- below 2 are for allowing/disallowing writing into any of the 7 registers (R0 to R6)
	-- (1 bit for each register)
	signal write_reg: std_logic_vector(0 to 31);
	shared variable write1: std_logic_vector(0 to 31) := (others=>'0');
	signal write_value : std_logic_vector(15 downto 0);
begin

	make_regs : for i in 0 to 31 generate
	R: reg
		port map ( rst, write_reg(i), write_val, regs(i));
	end generate make_regs;

	process (rst,write_regFile,reg_num,write_val, create_reg_map,free_reg ,read_1,read_2,read_3,read_4)
	begin
	if create_reg_map = '0' and free_reg = '0' then
		-- NOTE: reading, writing in "if-else" (only 1 at a time)
	
		if write_regFile ='1' then		-- write into some register
			write1 := (others=>'0');
			write1(reg_num) := '1';
		
		else
			write1 := (others=>'0');
			reg_val_1 <=regs(read_1);
			reg_val_2 <=regs(read_2);
			reg_val_3 <=regs(read_3);
			reg_val_4 <=regs(read_4);
		end if;
		write_reg <= write1;

	elsif create_reg_map = '1' then
		for i in 0 to 23 loop
			if reg_map(i)(0) = '0' then  -- found reg, create map 
				reg_map(i)(0)<= '1';
				reg_map(i)(5 downto 1)<=std_logic_vector(to_unsigned(reg_num, 5));
				mapped_reg <= (i+8);
				exit;
			end if;
		end loop;
		if write_regfile = '0' then
			write1 := (others=>'0');
			reg_val_1 <=regs(read_1);
			reg_val_2 <=regs(read_2);
			reg_val_3 <=regs(read_3);
			reg_val_4 <=regs(read_4);
			write_reg <= write1;
		end if;
	elsif free_reg = '1' then
		reg_map(reg_num -8)(0)<='0';
		write1 := (others=>'0');
		write_value <=regs(reg_num);
		write_reg <= write1;
		write1 := (others=>'0');
		write1(to_integer(unsigned(reg_map(reg_num-8)(3 downto 1)))) := '1';
		write_reg <= write1;

	end if;
	  for i in 0 to 119 loop
			reg_mapout(i)<=reg_map(i/5)((i mod 5)+1);
		end loop;
	end process;


end architecture;