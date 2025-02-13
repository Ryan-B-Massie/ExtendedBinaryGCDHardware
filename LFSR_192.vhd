----------------------------------------------------------------------------------
-- Engineer: Ryan Massie
-- Design Name: 
-- Module Name: LFSR_192 - Behavioral
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ShiftRegister192 is
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
end ShiftRegister192;

architecture Behavioral of ShiftRegister192 is
    signal shift_reg : STD_LOGIC_VECTOR(191 downto 0) := (others => '0');
begin
    process (CLK)
    begin
        if rising_edge(CLK) then
            if SHIFT = '1' then
                -- Shift right, inserting SERIAL_IN at MSB
                shift_reg <= SERIAL_IN & shift_reg(191 downto 1);
            elsif DONE = '1' then
                -- Load hardware inputs into the shift register
                shift_reg <= HARDWARE_IN_1 & HARDWARE_IN_2 & HARDWARE_IN_3;
            end if;
        end if;
    end process;

    -- Assign outputs
    OUTPUT_1   <= shift_reg(191 downto 128);  -- First 64 bits
    OUTPUT_2   <= shift_reg(127 downto 64);   -- Second 64 bits
    SERIAL_OUT <= shift_reg(0);               -- Least significant bit
end Behavioral;