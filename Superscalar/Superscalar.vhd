library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity Superscalar is
  Port(	clk,rst : in std_logic;

		data_loading: in std_logic; -- load into data memory on startup
		data_mem_address : in std_logic_vector(5 downto 0);
		data: in std_logic_vector(15 downto 0)
		);  
end Superscalar;

architecture Superscalar_arch of Superscalar is

	component memory is
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
	end component;
	
	component regFile is
		generic(num_reg: integer := 32);
		port(
			rst : in std_logic;
			write_regFile : in std_logic;		-- control signal for writing into RF  , if 0  read value from  reg_num register
			reg_num1 : in integer; -- Register to write/read value 
			reg_num2 : in integer;
			read_1 : in integer;
			read_2 : in integer;
			read_3 : in integer;
			read_4 : in integer;
			wf1,wf2 : in std_logic;
			write_val1 : in std_logic_vector(15 downto 0); -- Value to be written
			write_val2 : in  std_logic_vector(15 downto 0);
			create_reg_map : in std_logic; -- if 1 => search for free phy_regs, create a reg_map from reg_num and return mapped reg number
			free_reg : in std_logic; -- if 1=> free reg and clear maps  also commits the reg value to its arch register
			reg_val_1 : out std_logic_vector(15 downto 0); -- value read from reg_num
			reg_val_2 : out std_logic_vector(15 downto 0);
			reg_val_3 : out std_logic_vector(15 downto 0); -- value read from reg_num
			reg_val_4 : out std_logic_vector(15 downto 0);
			mapped_reg1 : out integer; -- mapped address
			mapped_reg2 : out integer;
			reg_mapout :out std_logic_vector(119 downto 0);--for renaming
			reg_latest : out std_logic_vector(39 downto 0)
		);
	end component;

	component Fetch is
		Port(	clk,rst : in std_logic;
				if_freeze : in std_logic;  -- freeze if set to 1, only ex modifiable.
				pc_overwrite : in std_logic; -- overwrites the internal pc with pc_inp if set to 1(for jump instructions), only ex modifiable.
				ins_loading: in std_logic;
				pc_inp : in std_logic_vector(5 downto 0);
				ins_mem_out1 : in std_logic_vector(15 downto 0);
				ins_mem_out2 : in std_logic_vector(15 downto 0);
				mem_address : out std_logic_vector(5 downto 0);
				pipe_reg1 : out std_logic_vector(15 downto 0);
				pipe_reg2 : out std_logic_vector(15 downto 0);
				ins_pc1 : out std_logic_vector(5 downto 0);
				ins_pc2 : out std_logic_vector(5 downto 0);
				mem_mode : out std_logic
			);
	end component;

	
	component Decode is
		port(
			clk: in std_logic;
			rst: in std_logic;
			loading_mem : in std_logic; -- 1 if memory loading is in progress
			id_freeze : in std_logic ;
			
			instruction_1 : in std_logic_vector(15 downto 0) ;
			instruction_2 : in std_logic_vector(15 downto 0) ;
			ins_1_pc : in std_logic_vector(5 downto 0);
			ins_2_pc : in std_logic_vector(5 downto 0);
			ins_1 : out integer;
			ins_2 : out integer;
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
	end component ;
	component  Res is
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
	end component;

	component rob is
			port(rst,clk,zero,carry,zero2,carry2 : in std_logic; --2(suffix) are used for lw instr type
	           exec_phy_reg,exec_phy_reg2 : in integer;	
				  data,data_2 : in  std_logic_vector(15 downto 0);
				  rwn_flag: in std_logic_vector(2 downto 0);-- read write nothin flag
				  loc_rwn : in  std_logic_vector(5 downto 0);--from where read write nothin 
			     output_reg1 : in std_logic_vector(2 downto 0); --where we need to write result(destination reg)
				  prf_output_reg1 :in integer; --the phy reg which contains value
				  output_reg2 : in std_logic_vector(2 downto 0); --where we need to write result(destination reg)
				  prf_output_reg2 :in integer; --the phy reg which contains value
				  pc_ins_1 : in std_logic_vector(5 downto 0); -- to keep track of instr order
		        pc_ins_2 : in std_logic_vector(5 downto 0) ; -- to keep track of instr order
				  spec_instr_pc: in std_logic_vector(5 downto 0); --speculated pc
				  speculation_not_valid : in std_logic; --flushes instrs if =1 from spec_instr_pc
				  --out
				  reg1,reg2 :out std_logic_vector(2 downto 0);
				  data1,data2 :out std_logic_vector(15 downto 0);
				  z1,z2,c1,c2 :out std_logic --z and c flags
				  
				  
			    );
		end component;

	component Write_back is
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
	end component;

	--Fetch external signals
	signal if_freeze,id_freeze : std_logic := '0';  --use only in ex
	signal pc_overwrite : std_logic := '0'; --use only in ex
	signal pc_inp : std_logic_vector(5 downto 0) := "000000"; --use only in ex
	signal mem_address : std_logic_vector(5 downto 0):= (others=>'0');
	signal ins_pc_1 : std_logic_vector(5 downto 0):= (others=>'0');
	signal ins_pc_2 : std_logic_vector(5 downto 0):= (others=>'0');
	signal pipe_reg1 : std_logic_vector(15 downto 0):= (others=>'0');
	signal pipe_reg2 : std_logic_vector(15 downto 0):= (others=>'0');

	--Memory external signals
	signal mem_mode : std_logic := '0';
	signal mem_store_data : std_logic_vector(15 downto 0):= (others=>'0');
	signal mem_out1: std_logic_vector(15 downto 0):= (others=>'0');
	signal mem_out2: std_logic_vector(15 downto 0):= (others=>'0');

	--Regfile External signals
	signal write_regFile :  std_logic := '0';		-- control signal for writing into RF  , if 0  read value from  reg_num register
	signal reg_num1 :  integer := 0; -- Register to write/read value 
	signal reg_num2 : integer:=0;
	signal read_1 : integer:=0;
	signal read_2 : integer:=0;
	signal read_3 : integer:=0;
	signal read_4 : integer:=0;
	signal wf1,wf2 : std_logic:='0';
	signal write_val1 :  std_logic_vector(15 downto 0):=(others=>'0'); -- Value to be written 
	signal write_val2 :  std_logic_vector(15 downto 0):=(others=>'0');
	signal create_reg_map :  std_logic:='0'; -- if 1 => search for free phy_regs, create a reg_map from reg_num and return mapped reg number
	signal free_reg :  std_logic:='0'; -- if 1=> free reg and clear maps  also commits the reg value to its arch register
	signal reg_val_1 : std_logic_vector(15 downto 0):=(others=>'0'); -- value read from read_1
	signal reg_val_2 : std_logic_vector(15 downto 0):=(others=>'0');-- value read from read_2
	signal reg_val_3 : std_logic_vector(15 downto 0):=(others=>'0'); -- value read from read_1
	signal reg_val_4 : std_logic_vector(15 downto 0):=(others=>'0');-- value read from read_2
	signal mapped_reg1 : integer:=0; -- mapped address
	signal mapped_reg2 : integer:=0;
	signal reg_mapout : std_logic_vector(119 downto 0):=(others=>'0');--for renaming
	signal reg_latest : std_logic_vector(39 downto 0):=(others=>'0');

	-- Decode Signals
	signal ins_1 : integer := 0;
	signal ins_2 : integer:=0;
	signal r1_ins_1 : integer:=0; -- Dest reg. for ins1 ,specified by  reg number
	signal r2_ins_1 : integer:=0; -- Value read from r2
	signal r3_ins_1 : integer:=0; --value read from r3
	signal Imm_6_ins_1: std_logic_vector(15 downto 0):=(others=>'0'); -- Immediate 6 value (used in ADI, LW,SW etc.), sign extended to 16 bits
	signal Imm_9_ins_1: std_logic_vector(15 downto 0); --Immediate 9 (LHI, JAL), sign extended to 16 bits
	signal Imm_8_ins_1: std_logic_vector(7 downto 0);  --Immediate 8 (LM and SM)

	signal r1_ins_2 : integer;  -- Same as ins_1
	signal r2_ins_2 : integer;
	signal r3_ins_2 : integer;
	signal Imm_6_ins_2: std_logic_vector(15 downto 0);
	signal Imm_9_ins_2: std_logic_vector(15 downto 0);
	signal Imm_8_ins_2: std_logic_vector(7 downto 0);

	signal pc_ins_1 : std_logic_vector(5 downto 0);
	signal pc_ins_2 : std_logic_vector(5 downto 0);
	signal num_reg_1 : integer:=0;
	signal num_reg_2 : integer:=0;
	-- Reservation Station external signals
	signal cdb1 ,cdb2: integer;  --Common Data Bus to recieve info from commit stage
	signal cdb_data1 ,cdb_data2: std_logic_vector(15 downto 0);
	signal cdb_pc1, cdb_pc2 : std_logic_vector(6 downto 0);
	signal cdb_z1,cdb_z2,cdb_c1,cdb_c2 : std_logic;
	
	signal pc_alu , pc_mem: std_logic_vector(5 downto 0);
	signal ins_alu , ins_mem : integer;
	signal r1_alu, r1_mem : integer;
	signal r2_alu, r3_alu, r2_mem, r3_mem : std_logic_vector(15 downto 0);
	signal Imm6_alu, Imm6_mem : std_logic_vector(15 downto 0); --Sign extended
	signal Imm9_alu, Imm9_mem : std_logic_vector(15 downto 0); --Sign extended
	signal Imm8_alu, Imm8_mem : std_logic_vector(7 downto 0);
	signal z1,z2,c1,c2 : std_logic;
begin
	mem_inst: memory
		port map (clk, mem_address, data_mem_address, data_loading, mem_mode, mem_store_data ,data,mem_out1,mem_out2);
	
	fetch_Component : Fetch
      port map(clk, rst, if_freeze, pc_overwrite,data_loading, pc_inp, mem_out1,mem_out2, mem_address, pipe_reg1,pipe_reg2,ins_pc_1,ins_pc_2, mem_mode);
	
	RF_component : regFile
		port map(rst,write_regfile,reg_num1, reg_num2,read_1, read_2, read_3, read_4,wf1,wf2,write_val1,write_val2,create_reg_map,free_reg,reg_val_1, reg_val_2,reg_val_3,reg_val_4,mapped_reg1,mapped_reg2,reg_mapout,reg_latest);
	
	Decode_comp : Decode
		port map(clk,rst, data_loading, id_freeze,pipe_reg1,pipe_reg2,ins_pc_1, ins_pc_2,ins_1, ins_2,r1_ins_1,r2_ins_1,r3_ins_1,Imm_6_ins_1,
					Imm_9_ins_1, Imm_8_ins_1,r1_ins_2,r2_ins_2,r3_ins_2,Imm_6_ins_2, Imm_9_ins_2, Imm_8_ins_2,pc_ins_1, pc_ins_2,num_reg_1,num_reg_2);

	RS_comp : res
		port map(clk,rst,write_regFile,create_reg_map, free_reg, reg_num1, reg_num2,read_1,read_2,read_3,read_4, reg_val_1, reg_val_2,
					reg_val_3, reg_val_4,mapped_reg1,mapped_reg2,reg_latest,cdb1,cdb2,cdb_data1,cdb_data2,cdb_pc1,cdb_pc2,cdb_z1,cdb_z2,
					cdb_c1, cdb_c2,pc_ins_1,pc_ins_2,ins_1,ins_2,r1_ins_1 ,r2_ins_1,r3_ins_1,r1_ins_2,r2_ins_2,r3_ins_2,Imm_6_ins_1,
					Imm_9_ins_1,Imm_6_ins_2,Imm_9_ins_2,Imm_8_ins_1,Imm_8_ins_2,num_reg_1 ,num_reg_2,pc_alu , pc_mem,ins_alu , ins_mem,
					r1_alu, r1_mem,r2_alu, r3_alu, r2_mem, r3_mem,Imm6_alu, Imm6_mem,Imm9_alu, Imm9_mem ,Imm8_alu, Imm8_mem,z1,z2,c1,c2);

	--ROB_comp : rob
	--	port map(rst,clk,
	
end architecture;
