library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Decode is
   port(
		clk: in std_logic;
		rst: in std_logic;
		loading_mem : in std_logic; -- 1 if memory loading is in progress
		id_freeze : in std_logic ;

		write_regFile : out std_logic;	
		read_1 : out integer;
		read_2 : out integer;
		read_3 : out integer;
		read_4 : out integer;
		create_reg_map : out std_logic; -- if 1 => search for free phy_regs, create a reg_map from reg_num and return mapped reg number
		free_reg : out std_logic; -- if 1=> free reg and clear maps  also commits the reg value to its arch register
		reg_val_1 : in std_logic_vector(15 downto 0); 
		reg_val_2 : in std_logic_vector(15 downto 0);
		reg_val_3 : in std_logic_vector(15 downto 0); 
		reg_val_4 : in std_logic_vector(15 downto 0);
		
		instruction_1 : in std_logic_vector(15 downto 0) ;
		instruction_2 : in std_logic_vector(15 downto 0) ;


-- Each instruction gets an integer assigned, numbering 0 to 17  in order(page 3, encoding table order)
		ins_1 : out integer;
		ins_2 : out integer;


-- Each instruction is decoded in all possible ways(eg. ADD is also decoded into imm6, imm8 and imm9 along with the registers)
-- The signals to be used will be decided by exec stage based on the ins number.(eg. exec will use only r1, r2 and r3 for ADD )
-- The remaining signals should be ignored.
		r1_ins_1 : out integer; -- Dest reg. for ins1 ,specified by  reg number
		r2_ins_1 : out std_logic_vector(15 downto 0); -- Value read from r2
		r3_ins_1 : out std_logic_vector(15 downto 0); --value read from r3
		Imm_6_ins_1: out std_logic_vector(15 downto 0); -- Immediate 6 value (used in ADI, LW,SW etc.), sign extended to 16 bits
		Imm_9_ins_1: out std_logic_vector(15 downto 0); --Immediate 9 (LHI, JAL), sign extended to 16 bits
		Imm_8_ins_1: out std_logic_vector(7 downto 0);  --Immediate 8 (LM and SM)


		r1_ins_2 : out integer;  -- Same as ins_1
		r2_ins_2 : out std_logic_vector(15 downto 0);
		r3_ins_2 : out std_logic_vector(15 downto 0);
		Imm_6_ins_2: out std_logic_vector(15 downto 0);
		Imm_9_ins_2: out std_logic_vector(15 downto 0);
		Imm_8_ins_2: out std_logic_vector(7 downto 0);

		pc_ins_1 : out std_logic_vector(5 downto 0);
		pc_ins_2 : out std_logic_vector(5 downto 0)
	  ) ;
end entity ;

architecture id_arch of Decode is
begin
	process (clk)
	begin
		if loading_mem = '1' then
		else
			if rising_edge(clk) then
				r1_ins_1 <= to_integer(unsigned(instruction_1(11 downto 9)));
				Imm_6_ins_1 <= std_logic_vector(resize(unsigned(instruction_1(5 downto 0)),16));
				Imm_9_ins_1 <= std_logic_vector(resize(unsigned(instruction_1(8 downto 0)),16));
				Imm_8_ins_1 <= instruction_1(8 downto 1);

				r1_ins_2 <= to_integer(unsigned(instruction_2(11 downto 9)));
				Imm_6_ins_2 <= std_logic_vector(resize(unsigned(instruction_2(5 downto 0)),16));
				Imm_9_ins_2 <= std_logic_vector(resize(unsigned(instruction_2(8 downto 0)),16));
				Imm_8_ins_2 <= instruction_2(8 downto 1);
				write_regfile <='0';
				create_reg_map <= '0';
				free_reg <='0';
				read_1 <=to_integer(unsigned(instruction_1(8 downto 6)));
				read_2 <=to_integer(unsigned(instruction_1(5 downto 3)));
				read_3 <=to_integer(unsigned(instruction_2(8 downto 6)));
				read_4 <=to_integer(unsigned(instruction_2(5 downto 3)));
			end if;
			if falling_edge(clk) then 
				r2_ins_1 <= reg_val_1;
				r3_ins_1 <= reg_val_2;
				r2_ins_2 <= reg_val_3;
				r3_ins_2 <= reg_val_4;
			
			end if;
		end if;
	end process;
end architecture;



