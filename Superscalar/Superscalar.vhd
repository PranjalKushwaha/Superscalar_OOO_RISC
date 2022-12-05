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
			reg_val_3 : out std_logic_vector(15 downto 0); -- value read from reg_num
			reg_val_4 : out std_logic_vector(15 downto 0);
			mapped_reg : out integer; -- mapped address
			reg_mapout :out std_logic_vector(119 downto 0)--for renaming
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
			ins_1 : out integer;
			ins_2 : out integer;
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
	end component ;

	component rename is 
		port(
			rst : in std_logic;
			reg_mapout :in std_logic_vector(119 downto 0);
			pr_a1 : in std_logic_vector(2 downto 0);--addr of reg in instr
			pr_a2 : in std_logic_vector(2 downto 0);--addr of reg in instr
			create_regmap :out std_logic; --connect to regfile create_reg_map
			prev_rename_addr1 :out integer;	-- rename register addr if its previously renamed (connect to regfile regnum)
			prev_rename_addr2:out integer
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
	signal write_regFile :  std_logic;		-- control signal for writing into RF  , if 0  read value from  reg_num register
	signal reg_num :  integer; -- Register to write/read value 
	signal read_1 : integer;
	signal read_2 : integer;
	signal read_3 : integer;
	signal read_4 : integer;
	signal write_val :  std_logic_vector(15 downto 0); -- Value to be written 
	signal create_reg_map :  std_logic; -- if 1 => search for free phy_regs, create a reg_map from reg_num and return mapped reg number
	signal free_reg :  std_logic; -- if 1=> free reg and clear maps  also commits the reg value to its arch register
	signal reg_val_1 : std_logic_vector(15 downto 0); -- value read from read_1
	signal reg_val_2 : std_logic_vector(15 downto 0);-- value read from read_2
	signal reg_val_3 : std_logic_vector(15 downto 0); -- value read from read_1
	signal reg_val_4 : std_logic_vector(15 downto 0);-- value read from read_2
	signal mapped_reg :  integer; -- mapped address
	signal reg_mapout : std_logic_vector(119 downto 0);--for renaming

	-- Decode Signals
	signal ins_1 : integer;
	signal ins_2 : integer;
	signal r1_ins_1 : integer; -- Dest reg. for ins1 ,specified by  reg number
	signal r2_ins_1 : std_logic_vector(15 downto 0); -- Value read from r2
	signal r3_ins_1 : std_logic_vector(15 downto 0); --value read from r3
	signal Imm_6_ins_1: std_logic_vector(15 downto 0); -- Immediate 6 value (used in ADI, LW,SW etc.), sign extended to 16 bits
	signal Imm_9_ins_1: std_logic_vector(15 downto 0); --Immediate 9 (LHI, JAL), sign extended to 16 bits
	signal Imm_8_ins_1: std_logic_vector(7 downto 0);  --Immediate 8 (LM and SM)

	signal r1_ins_2 : integer;  -- Same as ins_1
	signal r2_ins_2 : std_logic_vector(15 downto 0);
	signal r3_ins_2 : std_logic_vector(15 downto 0);
	signal Imm_6_ins_2: std_logic_vector(15 downto 0);
	signal Imm_9_ins_2: std_logic_vector(15 downto 0);
	signal Imm_8_ins_2: std_logic_vector(7 downto 0);

	signal pc_ins_1 : std_logic_vector(5 downto 0);
	signal pc_ins_2 : std_logic_vector(5 downto 0);


begin
	mem_inst: memory
		port map (clk, mem_address, data_mem_address, data_loading, mem_mode, mem_store_data ,data,mem_out1,mem_out2);
	
	fetch_Component : Fetch
      port map(clk, rst, if_freeze, pc_overwrite,data_loading, pc_inp, mem_out1,mem_out2, mem_address, pipe_reg1,pipe_reg2,ins_pc_1,ins_pc_2, mem_mode);
	
	RF_component : regFile
		port map(rst,write_regfile,reg_num,read_1, read_2, read_3, read_4,write_val,create_reg_map,free_reg,reg_val_1, reg_val_2,reg_val_3,reg_val_4,mapped_reg,reg_mapout);
	
	Decode_comp : Decode
		port map(clk,rst, data_loading, id_freeze,write_regfile,read_1,read_2,read_3,read_4,create_reg_map,free_reg,reg_val_1,reg_val_2,reg_val_3,reg_val_4,pipe_reg1,
			pipe_reg2,ins_1, ins_2,r1_ins_1,r2_ins_1,r3_ins_1,Imm_6_ins_1, Imm_9_ins_1, Imm_8_ins_1,r1_ins_2,r2_ins_2,r3_ins_2,Imm_6_ins_2, 
			Imm_9_ins_2, Imm_8_ins_2,pc_ins_1, pc_ins_2);

	--Rename_comp1 :rename
	--	port map(rst, reg_mapout,
end architecture;
