library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package input_array is
        constant N : integer := 64;
        constant NUM_WRITES : integer := 10;
        type INPUT_ARRAY_T is array (natural range <>) of STD_LOGIC_VECTOR(N-1 downto 0);
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.input_array.ALL;

entity ESRegisterFile is
    Generic (
        N : integer := 64;
        NUM_REG : integer := 8
    );
    
    Port (
        -- Control
        CLK   : in STD_LOGIC;
        RESET : in STD_LOGIC;
        -- Inputs
        W_ENABLE_IN : in STD_LOGIC_VECTOR(9 downto 0);
        W_REG_IN    : in STD_LOGIC_VECTOR(23 downto 0);
        W_INPUTS_IN : in INPUT_ARRAY_T(0 to NUM_WRITES-1);
        READ_IN : in STD_LOGIC_VECTOR(32 downto 0);
        -- Outputs
        REG_OBITS_OUT : out STD_LOGIC_VECTOR(5 downto 0);
        X_OUT         : out STD_LOGIC_VECTOR(N-1 downto 0);
        Xp_OUT        : out STD_LOGIC_VECTOR(N-1 downto 0);
        Xq_OUT        : out STD_LOGIC_VECTOR(N-1 downto 0);
        Y_OUT         : out STD_LOGIC_VECTOR(N-1 downto 0);
        Yp_OUT        : out STD_LOGIC_VECTOR(N-1 downto 0);
        Yq_OUT        : out STD_LOGIC_VECTOR(N-1 downto 0);
        RS1_READ_OUT  : out STD_LOGIC_VECTOR(N-1 downto 0);
        RS2_READ_OUT  : out STD_LOGIC_VECTOR(N-1 downto 0);
        RS3_READ_OUT  : out STD_LOGIC_VECTOR(N-1 downto 0);
        LS1_READ_OUT  : out STD_LOGIC_VECTOR(N-1 downto 0);
        LS2_READ_OUT  : out STD_LOGIC_VECTOR(N-1 downto 0);
        A11_READ_OUT  : out STD_LOGIC_VECTOR(N-1 downto 0);
        A12_READ_OUT  : out STD_LOGIC_VECTOR(N-1 downto 0);
        S11_READ_OUT  : out STD_LOGIC_VECTOR(N-1 downto 0);
        S12_READ_OUT  : out STD_LOGIC_VECTOR(N-1 downto 0);
        S21_READ_OUT  : out STD_LOGIC_VECTOR(N-1 downto 0);
        S22_READ_OUT  : out STD_LOGIC_VECTOR(N-1 downto 0)
    );
    
end ESRegisterFile;

architecture Behavioral of ESRegisterFile is
    -- Register Definition
    -- 0 : X
    -- 1 : Xp
    -- 2 : Xq
    -- 3 : X0
    -- 4 : Y
    -- 5 : Yp
    -- 6 : Yq
    -- 7 : Y0
    type REG_ARRAY is array (0 to NUM_REG-1) of std_logic_vector(N-1 downto 0);
    signal REGISTERS : REG_ARRAY := (others => (others => '0'));
    
begin
    -- Synchronous Write Process
    process(CLK)
    begin
        if rising_edge(clk) then -- Handle Updates
            if RESET = '1' then
                -- Handle Reset
                REGISTERS <= (others => (others => '0')); -- Clear all registers on reset
                REGISTERS(0) <= W_INPUTS_IN(0); -- Load P/Q into registers
                REGISTERS(1)(0) <= '1';
                REGISTERS(2)(0) <= '0';
                REGISTERS(3) <= W_INPUTS_IN(0);
                REGISTERS(4) <= W_INPUTS_IN(1);
                REGISTERS(5)(0) <= '0';
                REGISTERS(6)(0) <= '1';
                REGISTERS(7) <= W_INPUTS_IN(1);
            else
                -- loop through all writes
                for i in W_ENABLE_IN'range loop -- Loop through writes
                    if W_ENABLE_IN(i) = '1' then
                        if i <= 7 then -- Adressable writes
                            REGISTERS(TO_INTEGER(unsigned(W_REG_IN((i * 3) + 2 downto (i * 3))))) <= W_INPUTS_IN(i);
                        elsif i = 8 then -- XY input
                            REGISTERS(0) <= W_INPUTS_IN(8); -- Write to X
                        else -- i = 9 -- YX input
                            REGISTERS(4) <= W_INPUTS_IN(9); -- Write to Y
                        end if;
                    end if;
                end loop;    
            end if;
        end if;
    end process;
    
    -- Asynchronous Read Process
    process(CLK, RESET, W_ENABLE_IN, W_REG_IN, W_INPUTS_IN, READ_IN)
    begin
        -- Update OBits
        REG_OBITS_OUT <= REGISTERS(6)(0)& REGISTERS(5)(0)& REGISTERS(4)(0)& REGISTERS(2)(0)& REGISTERS(1)(0)& REGISTERS(0)(0);
        -- loop through all reads
        X_OUT         <= REGISTERS(0);
        Xp_OUT        <= REGISTERS(1);
        Xq_OUT        <= REGISTERS(2);
        Y_OUT         <= REGISTERS(4);
        Yp_OUT        <= REGISTERS(5);
        Yq_OUT        <= REGISTERS(6);
        RS1_READ_OUT  <= REGISTERS(TO_INTEGER(unsigned(READ_IN(2 downto 0))));
        RS2_READ_OUT  <= REGISTERS(TO_INTEGER(unsigned(READ_IN(5 downto 3))));
        RS3_READ_OUT  <= REGISTERS(TO_INTEGER(unsigned(READ_IN(8 downto 6))));
        LS1_READ_OUT  <= REGISTERS(TO_INTEGER(unsigned(READ_IN(11 downto 9))));
        LS2_READ_OUT  <= REGISTERS(TO_INTEGER(unsigned(READ_IN(14 downto 12))));
        A11_READ_OUT  <= REGISTERS(TO_INTEGER(unsigned(READ_IN(17 downto 15))));
        A12_READ_OUT  <= REGISTERS(TO_INTEGER(unsigned(READ_IN(20 downto 18))));
        S11_READ_OUT  <= REGISTERS(TO_INTEGER(unsigned(READ_IN(23 downto 21))));
        S12_READ_OUT  <= REGISTERS(TO_INTEGER(unsigned(READ_IN(26 downto 24))));
        S21_READ_OUT  <= REGISTERS(TO_INTEGER(unsigned(READ_IN(29 downto 27))));
        S22_READ_OUT  <= REGISTERS(TO_INTEGER(unsigned(READ_IN(32 downto 30))));
        
    end process;
end Behavioral;