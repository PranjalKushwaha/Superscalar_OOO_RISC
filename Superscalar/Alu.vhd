library ieee;
use ieee.std_logic_1164.all;

entity ALU is
   port(alu_a,alu_b: in std_logic_vector(15 downto 0);
		  sel: in std_logic_vector(1 downto 0);
		alu_c: out std_logic_vector(15 downto 0);
      c_flag, z_flag: out std_logic);
end entity;

architecture ALU_arch of ALU is 
component FullAdder16 is
   port(a,b: in std_logic_vector(15 downto 0);
		 sum: out std_logic_vector(15 downto 0) ;
       c_out: out std_logic);
end component;

signal sum : std_logic_vector(15 downto 0);
signal output : std_logic_vector(15 downto 0);
begin
    Add_out : FullAdder16
	 port map(a=>alu_a, b=>alu_b,sum=>sum,c_out =>c_flag);
	 
	 process(sel,alu_a,alu_b,sum)
	 begin
	    if sel = "00" then
	      output <= sum ;
		 elsif sel = "01" then
		   output <= alu_a nand alu_b ;
		 elsif sel <= "10" then 
		   output <= alu_a xor alu_b ;
		 end if ;
	 end process;
	 
	 process(output)
	 begin
	    alu_c <= output ;
	    if output = "0000000000000000" then
		   z_flag <= '1' ;
		 else
		   z_flag <= '0' ;
		 end if;	
	 end process;
end architecture ;