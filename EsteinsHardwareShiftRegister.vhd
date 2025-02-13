----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/07/2025 10:10:46 AM
-- Design Name: 
-- Module Name: ESTEINS_SHIFT_REGESTER_TOP - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity EsteinsHardwareShiftRegister is
    Port (
        CLK         : in  STD_LOGIC;
        ENABLE_H    : in  STD_LOGIC;
        SHIFT       : in  STD_LOGIC;
        SERIAL_IN   : in  STD_LOGIC;
        DONE        : out  STD_LOGIC;
        SERIAL_OUT  : out STD_LOGIC
    );
end EsteinsHardwareShiftRegister;

architecture Behavioral of EsteinsHardwareShiftRegister is

signal DONE_LINE : STD_LOGIC;
signal IN1_LINE  : STD_LOGIC_VECTOR(63 downto 0);
signal IN2_LINE  : STD_LOGIC_VECTOR(63 downto 0);
signal OUT1_LINE : STD_LOGIC_VECTOR(63 downto 0);
signal OUT2_LINE : STD_LOGIC_VECTOR(63 downto 0);
signal OUT3_LINE : STD_LOGIC_VECTOR(63 downto 0);


component ExtendedSteinsHardware is
    Generic (
        N : integer := 64;
        NUM_REG : integer := 8
    );
    
    Port (
        -- Control
        CLK           : in STD_LOGIC;
        ENABLE        : in STD_LOGIC;
        -- Logic
        INPUT_1       : in STD_LOGIC_VECTOR(N-1 downto 0);
        INPUT_2       : in STD_LOGIC_VECTOR(N-1 downto 0);
        GCD_OUT       : out STD_LOGIC_VECTOR(N-1 downto 0);
        COEFFICIENT_1 : out STD_LOGIC_VECTOR(N-1 downto 0);
        COEFFICIENT_2 : out STD_LOGIC_VECTOR(N-1 downto 0);
        DONE_OUT      : out STD_LOGIC
    );
end component;

component ShiftRegister192 is
    Port (
        CLK          : in  STD_LOGIC;
        SHIFT        : in  STD_LOGIC;
        SERIAL_IN    : in  STD_LOGIC;
        DONE         : in  STD_LOGIC;
        HARDWARE_IN_1 : in  STD_LOGIC_VECTOR(63 downto 0);
        HARDWARE_IN_2 : in  STD_LOGIC_VECTOR(63 downto 0);
        HARDWARE_IN_3 : in  STD_LOGIC_VECTOR(63 downto 0);
        OUTPUT_1     : out STD_LOGIC_VECTOR(63 downto 0);
        OUTPUT_2     : out STD_LOGIC_VECTOR(63 downto 0);
        SERIAL_OUT   : out STD_LOGIC
    );
end component;

begin
    Hardware : ExtendedSteinsHardware
        port map (
        CLK => CLK,       
        ENABLE => ENABLE_H, 
        INPUT_1 => IN1_LINE,   
        INPUT_2 => IN2_LINE,
        GCD_OUT => OUT1_LINE,  
        COEFFICIENT_1 => OUT2_LINE,
        COEFFICIENT_2 => OUT3_LINE,
        DONE_OUT => DONE_LINE
        );

    SR: ShiftRegister192
        port map(
        CLK => CLK,         
        SHIFT => SHIFT,  
        SERIAL_IN => SERIAL_IN,
        DONE => DONE_LINE,
        HARDWARE_IN_1 => OUT1_LINE,
        HARDWARE_IN_2 => OUT2_LINE,
        HARDWARE_IN_3 => OUT3_LINE,
        OUTPUT_1 => IN1_LINE,
        OUTPUT_2 => IN2_LINE,
        SERIAL_OUT => SERIAL_OUT
        );
    
    DONE <= DONE_LINE;

end Behavioral;
