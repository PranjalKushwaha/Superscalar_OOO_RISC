library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Decode is
   port(
		clk: in std_logic;
		rst: in std_logic;
		loading_mem : in std_logic; -- 1 if memory loading is in progress
		id_freeze : in std_logic ;
		
		instruction_1 : in std_logic_vector(15 downto 0) ;
		instruction_2 : in std_logic_vector(15 downto 0) ;
		ins_1_pc : in std_logic_vector(5 downto 0);
		ins_2_pc : in std_logic_vector(5 downto 0);


-- Each instruction gets an integer assigned, numbering 0 to 17  in order(page 3, encoding table order)
		ins_1 : out integer;
		ins_2 : out integer;


-- Each instruction is decoded in all possible ways(eg. ADD is also decoded into imm6, imm8 and imm9 along with the registers)
-- The signals to be used will be decided by exec stage based on the ins number.(eg. exec will use only r1, r2 and r3 for ADD )
-- The remaining signals should be ignored.
		r1_ins_1 : out integer; -- Dest reg. for ins1 ,specified by  reg number
		r2_ins_1 : out integer; -- Value read from r2
		r3_ins_1 : out integer; --value read from r3
		Imm_6_ins_1: out std_logic_vector(15 downto 0); -- Immediate 6 value (used in ADI, LW,SW etc.), sign extended to 16 bits
		Imm_9_ins_1: out std_logic_vector(15 downto 0); --Immediate 9 (LHI, JAL), sign extended to 16 bits
		Imm_8_ins_1: out std_logic_vector(7 downto 0);  --Immediate 8 (LM and SM)


		r1_ins_2 : out integer;  -- Same as ins_1
		r2_ins_2 : out integer;
		r3_ins_2 : out integer;
		Imm_6_ins_2: out std_logic_vector(15 downto 0);
		Imm_9_ins_2: out std_logic_vector(15 downto 0);
		Imm_8_ins_2: out std_logic_vector(7 downto 0);

		pc_ins_1 : out std_logic_vector(5 downto 0);
		pc_ins_2 : out std_logic_vector(5 downto 0);
		num_reg_1 : out integer;
		num_reg_2 : out integer
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
				
				r2_ins_1 <= to_integer(unsigned(instruction_1(8 downto 6)));
				r3_ins_1 <= to_integer(unsigned(instruction_1(5 downto 3)));
				r2_ins_2 <= to_integer(unsigned(instruction_2(8 downto 6)));
				r3_ins_2 <= to_integer(unsigned(instruction_2(8 downto 6)));
				pc_ins_1 <= ins_1_pc;
				pc_ins_2 <= ins_2_pc;
			end if;
		end if;
	end process;
	process(instruction_1)
	begin
		if instruction_1(15 downto 12) = "0001" then
			if instruction_1(1 downto 0) = "00" then
				ins_1 <= 0;
			elsif instruction_1(1 downto 0) = "10" then
				ins_1 <= 1;
			elsif instruction_1(1 downto 0) = "01" then
				ins_1 <= 2;
			elsif instruction_1(1 downto 0) = "11" then
				ins_1 <= 3;
			end if;
			num_reg_1 <= 3;
		elsif instruction_1(15 downto 12)= "0000" then
			ins_1<= 4;
			num_reg_1 <= 2;
		elsif instruction_1(15 downto 12)= "0010" then
			if instruction_1(1 downto 0) = "00" then
				ins_1 <= 5;
			elsif instruction_1(1 downto 0) = "10" then
				ins_1 <= 6;
			elsif instruction_1(1 downto 0) = "01" then
				ins_1 <= 7;
			end if;
			num_reg_1 <= 3;
		elsif instruction_1(15 downto 12)= "0100" then
			ins_1<= 8;
			num_reg_1 <= 1;
		elsif instruction_1(15 downto 12)= "0101" then
			ins_1<= 9;
			num_reg_1 <= 2;
		elsif instruction_1(15 downto 12)= "0111" then
			ins_1<= 10;
			num_reg_1 <= 2;
		elsif instruction_1(15 downto 12)= "1101" then
			ins_1<= 11;
			num_reg_1 <= 1;
		elsif instruction_1(15 downto 12)= "1100" then
			ins_1<= 12;
			num_reg_1 <= 1;
		elsif instruction_1(15 downto 12)= "1000" then
			ins_1<= 13;
			num_reg_1 <= 2;
		elsif instruction_1(15 downto 12)= "1001" then
			ins_1<= 14;
			num_reg_1 <= 1;
		elsif instruction_1(15 downto 12)= "1010" then
			ins_1<= 15;
			num_reg_1 <= 2;
		elsif instruction_1(15 downto 12)= "1011" then
			ins_1<= 16;
			num_reg_1 <= 1;
		else 
			ins_1<=17; --no-op
		end if;
	end process;

	process(instruction_2)
	begin
		if instruction_2(15 downto 12) = "0001" then
			if instruction_2(1 downto 0) = "00" then
				ins_2 <= 0;
			elsif instruction_2(1 downto 0) = "10" then
				ins_2 <= 1;
			elsif instruction_2(1 downto 0) = "01" then
				ins_2 <= 2;
			elsif instruction_2(1 downto 0) = "11" then
				ins_2 <= 3;
			end if;
			num_reg_2 <= 3;
		elsif instruction_2(15 downto 12)= "0000" then
			ins_2<= 4;
			num_reg_2 <= 2;
		elsif instruction_2(15 downto 12)= "0010" then
			if instruction_2(1 downto 0) = "00" then
				ins_2 <= 5;
			elsif instruction_2(1 downto 0) = "10" then
				ins_2 <= 6;
			elsif instruction_2(1 downto 0) = "01" then
				ins_2 <= 7;
			end if;
			num_reg_2 <= 3;
		elsif instruction_2(15 downto 12)= "0100" then
			ins_2<= 8;
			num_reg_2 <= 1;
		elsif instruction_2(15 downto 12)= "0101" then
			ins_2<= 9;
			num_reg_2 <= 2;
		elsif instruction_2(15 downto 12)= "0111" then
			ins_2<= 10;
			num_reg_2 <= 2;
		elsif instruction_2(15 downto 12)= "1101" then
			ins_2<= 11;
			num_reg_2 <= 1;
		elsif instruction_2(15 downto 12)= "1100" then
			ins_2<= 12;
			num_reg_2 <= 1;
		elsif instruction_2(15 downto 12)= "1000" then
			ins_2<= 13;
			num_reg_2 <= 2;
		elsif instruction_2(15 downto 12)= "1001" then
			ins_2<= 14;
			num_reg_2 <= 1;
		elsif instruction_2(15 downto 12)= "1010" then
			ins_2<= 15;
			num_reg_2 <= 2;
		elsif instruction_2(15 downto 12)= "1011" then
			ins_2<= 16;
			num_reg_2 <= 1;
		else 
			ins_2<=17; --no-op
		end if;
	end process;

end architecture;



