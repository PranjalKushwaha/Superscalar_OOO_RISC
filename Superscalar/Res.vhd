library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity Res is
	port(
		clk ,rst:in std_logic;
		write_regFile,create_reg_map,free_reg : out std_logic;
		reg_num1 , reg_num2, read_1,read_2,read_3,read_4: out integer; -- Register to write/read value 
	
		reg_val_1, reg_val_2, reg_val_3, reg_val_4 : in std_logic_vector(15 downto 0); -- value read from reg_num
		mapped_reg1,mapped_reg2: in integer; -- mapped address
		reg_latest : in std_logic_vector(39 downto 0);
		cdb1 ,cdb2: in integer;  --Common Data Bus to recieve info from commit stage
		cdb_data1 ,cdb_data2: in std_logic_vector(15 downto 0);
		cdb_pc1, cdb_pc2 : in std_logic_vector(6 downto 0);
		cdb_z1,cdb_z2,cdb_c1,cdb_c2 : in std_logic;

		pc_ins_1 ,pc_ins_2: in std_logic_vector(5 downto 0);

		ins_1 ,ins_2: in integer;
		r1_ins_1 ,r2_ins_1,r3_ins_1,r1_ins_2,r2_ins_2,r3_ins_2: in integer; 
		Imm_6_ins_1,Imm_9_ins_1,Imm_6_ins_2,Imm_9_ins_2: in std_logic_vector(15 downto 0); 
		Imm_8_ins_1,Imm_8_ins_2: in std_logic_vector(7 downto 0);  
		num_reg_1 ,num_reg_2: in integer;
		
		pc_alu , pc_mem: out std_logic_vector(5 downto 0);
		ins_alu , ins_mem : out integer;
		r1_alu, r1_mem : out integer;
		r2_alu, r3_alu, r2_mem, r3_mem : out std_logic_vector(15 downto 0);
		Imm6_alu, Imm6_mem : out std_logic_vector(15 downto 0); --Sign extended
		Imm9_alu, Imm9_mem : out std_logic_vector(15 downto 0); --Sign extended
		Imm8_alu, Imm8_mem : out std_logic_vector(7 downto 0);
		z1,z2,c1,c2 : out std_logic
	);

end entity;

architecture res_arch of Res is
type buff_type is array  (0 to 16) of std_logic_vector(0 to 77); -- 1 bit exec tag,6 bits pc, 5 bit ins, 5bit reg1,2*17 reg nums, 6 imm,9imm,8imm , 2 bit z, 2 bit c
shared variable ins_buff : buff_type;
type reg_map_latest is array (0 to 23) of std_logic_vector(4 downto 0);  -- map data for phy regs, if bit num 0=1=> reg is mapped
signal reg_lat : reg_map_latest;
signal cdb_pc1_old, cdb_pc2_old : std_logic_vector(6 downto 0):="0000000";
signal cdb1_old,cdb2_old : integer;

begin

process (pc_ins_1,pc_ins_2)  -- When new instructions are recieved, push them into queue.
begin
	
end process;


process(clk, cdb_pc1, cdb_pc2,cdb1,cdb2)
begin
	if cdb_pc1 /= cdb_pc1_old then
		cdb_pc1_old <= cdb_pc1;
		if cdb_pc1(0) = '0' then
			for i in 16 downto 0 loop
				if to_integer(unsigned(cdb_pc1(6 downto 1))) = to_integer(unsigned(ins_buff(i)(1 to 6))) and ins_buff(i)(0) = '0' then
					ins_buff(i)(74) := '1';
					ins_buff(i)(75) := cdb_z1;
					ins_buff(i)(76) := '1';
					ins_buff(i)(77) := cdb_c1;
				end if;
			end loop;
		end if;
	end if;
	if cdb_pc2 /= cdb_pc2_old then
		cdb_pc2_old <= cdb_pc2;
		if cdb_pc2(0) = '0' then
			for i in 16 downto 0 loop
				if to_integer(unsigned(cdb_pc2(6 downto 1))) = to_integer(unsigned(ins_buff(i)(1 to 6))) and ins_buff(i)(0) = '0' then
					ins_buff(i)(74) := '1';
					ins_buff(i)(75) := cdb_z2;
					ins_buff(i)(76) := '1';
					ins_buff(i)(77) := cdb_c2;
				end if;
			end loop;
		end if;
	end if;
	if cdb1 /= cdb1_old then
		cdb1_old <= cdb1;
		for i in 16 downto 0 loop
			if ins_buff(i)(0) = '0' then
				if ins_buff(i)(17) = '0' and to_integer(unsigned(ins_buff(i)(18 to 22))) = cdb1 then
					ins_buff(i)(17) := '1';
					ins_buff(i)(18 to 33) := cdb_data1;
				end if;
				if ins_buff(i)(33) = '0' and to_integer(unsigned(ins_buff(i)(34 to 38))) = cdb1 then
					ins_buff(i)(33) := '1';
					ins_buff(i)(34 to 49) := cdb_data1;
				end if;
			end if;
		end loop;
	end if;
	if cdb2 /= cdb2_old then
		cdb2_old <= cdb2;
		for i in 16 downto 0 loop
			if ins_buff(i)(0) = '0' then
				if ins_buff(i)(17) = '0' and to_integer(unsigned(ins_buff(i)(18 to 22))) = cdb2 then
					ins_buff(i)(17) := '1';
					ins_buff(i)(18 to 33) := cdb_data2;
				end if;
				if ins_buff(i)(34) = '0' and to_integer(unsigned(ins_buff(i)(35 to 39))) = cdb2 then
					ins_buff(i)(34) := '1';
					ins_buff(i)(35 to 50) := cdb_data2;
				end if;
			end if;
		end loop;
	end if;
	if clk = '0' then
		for i in 0 to 39 loop
		reg_lat(i/5)(i mod 5)<=reg_latest(i);
		end loop;
	create_reg_map <= '1';
	free_reg  <= '0';
	write_regFile <= '0';
	reg_num1 <= to_integer(unsigned(reg_lat(r1_ins_1))); -- rename reg r1 and fetch r2 and r3 values if they are not mapped. 
	reg_num2 <= to_integer(unsigned(reg_lat(r1_ins_2)));
	read_1 <= to_integer(unsigned(reg_lat(r2_ins_1)));
	read_2 <= to_integer(unsigned(reg_lat(r3_ins_1)));
	read_3 <= to_integer(unsigned(reg_lat(r2_ins_2)));
	read_4 <= to_integer(unsigned(reg_lat(r3_ins_2)));
	for i in 16 downto 0 loop -- Store ins1
		if ins_1 = 17 then
			exit;
		end if;
		if ins_buff(i)(0) = '1' then
		else
			ins_buff(i)(0) := '0';
			ins_buff(i)(1 to 6) := pc_ins_1;
			ins_buff(i)(7 to 11) := std_logic_vector(to_unsigned(ins_1, 5));
			ins_buff(i)(12 to 16) := std_logic_vector(to_unsigned(mapped_reg1,5));
			if to_integer(unsigned(reg_lat(r2_ins_1))) < 8 and num_reg_1 > 1 then
				ins_buff(i)(17) := '1' ;
				ins_buff(i)(18 to 33) :=  reg_val_1;  -- if r2 not mapped, store its value
			elsif to_integer(unsigned(reg_lat(r2_ins_1))) > 7 then
				ins_buff(i)(17) := '0';
				ins_buff(i)(18 to 22) := std_logic_vector(to_unsigned(r2_ins_1,5)); --else put num of r2 to wait on the CDB
			else
				ins_buff(i)(17) := '1';
			end if;
			if to_integer(unsigned(reg_lat(r3_ins_1))) < 8 and num_reg_1 > 2 then
				ins_buff(i)(34) := '1' ;
				ins_buff(i)(35 to 50) :=  reg_val_2;
			elsif to_integer(unsigned(reg_lat(r3_ins_1))) > 7 then
				ins_buff(i)(34) := '0';
				ins_buff(i)(35 to 39) := std_logic_vector(to_unsigned(r3_ins_1,5));
			else
				ins_buff(i)(34) := '1';
			end if;
			ins_buff(i)(51 to 56) := std_logic_vector(resize(unsigned(Imm_6_ins_1),6));
			ins_buff(i)(57 to 65) := std_logic_vector(resize(unsigned(Imm_9_ins_1),9));
			ins_buff(i)(66 to 73) := Imm_8_ins_1;
			exit;
		end if;
	end loop;

	for i in 16 downto 0 loop -- store ins2
		if ins_2 = 17 then
			exit;
		end if;
		if ins_buff(i)(0) = '1' then
		else
			ins_buff(i)(0) := '0';
			ins_buff(i)(1 to 6) := pc_ins_2;
			ins_buff(i)(7 to 11) := std_logic_vector(to_unsigned(ins_2, 5));
			ins_buff(i)(12 to 16) := std_logic_vector(to_unsigned(mapped_reg2,5));
			if to_integer(unsigned(reg_lat(r2_ins_2))) < 8 and num_reg_2 > 1 then
				ins_buff(i)(17) := '1' ;
				ins_buff(i)(18 to 33) :=  reg_val_3;  -- if r2 not mapped, store its value
			elsif to_integer(unsigned(reg_lat(r2_ins_2))) > 7 then
				ins_buff(i)(17) := '0';
				ins_buff(i)(18 to 22) := std_logic_vector(to_unsigned(r2_ins_2,5)); --else put num of r2 to wait on the CDB
			else
				ins_buff(i)(17) := '1';
			end if;
			if to_integer(unsigned(reg_lat(r3_ins_2))) < 8 and num_reg_2 > 1 then
				ins_buff(i)(34) := '1' ;
				ins_buff(i)(35 to 50) :=  reg_val_4;
			elsif to_integer(unsigned(reg_lat(r3_ins_2))) > 7 then
				ins_buff(i)(34) := '0';
				ins_buff(i)(35 to 39) := std_logic_vector(to_unsigned(r3_ins_2,5));
			else
				ins_buff(i)(34) := '1';
			end if;
			ins_buff(i)(51 to 56) := std_logic_vector(resize(unsigned(Imm_6_ins_2),6));
			ins_buff(i)(57 to 65) := std_logic_vector(resize(unsigned(Imm_9_ins_2),9));
			ins_buff(i)(66 to 73) := Imm_8_ins_2;
			exit;
		end if;
	end loop;
		for i in 16 downto 0 loop
			if ins_buff(i)(0) = '0'  and ins_buff(i)(17) = '1' and ins_buff(i)(34) = '1' and ins_buff(i)(74) = '1' and ins_buff(i)(76) = '1' then
				if to_integer(unsigned(ins_buff(i)(7 to 11))) < 9 or to_integer(unsigned(ins_buff(i)(7 to 11))) > 12 then
					ins_buff(i)(0) := '1';
					pc_alu <=ins_buff(i)(1 to 6);
					ins_alu <= to_integer(unsigned(ins_buff(i)(7 to 11)));
					r1_alu <= to_integer(unsigned(ins_buff(i)(12 to 16)));
					r2_alu <= ins_buff(i)(18 to 33);
					r3_alu <= ins_buff(i)(35 to 50);
					Imm6_alu <= std_logic_vector(resize(unsigned(ins_buff(i)(51 to 56)),16));
					Imm9_alu <= std_logic_vector(resize(unsigned(ins_buff(i)(57 to 65)),16));
					Imm8_alu <= ins_buff(i)(66 to 73);
					z1 <= ins_buff(i)(75);
					c1 <= ins_buff(i)(77);
				else 
					ins_alu <= 17; 
				end if;
			else
				ins_alu <= 17;	
			end if;
		end loop;

		for i in 16 downto 0 loop
			if ins_buff(i)(0) = '0'  and ins_buff(i)(17) = '1' and ins_buff(i)(34) = '1' and ins_buff(i)(74) = '1' and ins_buff(i)(76) = '1' then
				if to_integer(unsigned(ins_buff(i)(7 to 11))) >= 9 and to_integer(unsigned(ins_buff(i)(7 to 11))) <= 12 then
					ins_buff(i)(0) := '1';
					pc_mem <=ins_buff(i)(1 to 6);
					ins_mem <= to_integer(unsigned(ins_buff(i)(7 to 11)));
					r1_mem <= to_integer(unsigned(ins_buff(i)(12 to 16)));
					r2_mem <= ins_buff(i)(18 to 33);
					r3_mem <= ins_buff(i)(35 to 50);
					Imm6_mem <= std_logic_vector(resize(unsigned(ins_buff(i)(51 to 56)),16));
					Imm9_mem <= std_logic_vector(resize(unsigned(ins_buff(i)(57 to 65)),16));
					Imm8_mem <= ins_buff(i)(66 to 73);
					z2 <= ins_buff(i)(75);
					c2 <= ins_buff(i)(77);
				else 
					ins_mem <= 17; 
				end if;
			else
				ins_mem <= 17;	
			end if;
		end loop;
	end if; 
end process;
end architecture;
