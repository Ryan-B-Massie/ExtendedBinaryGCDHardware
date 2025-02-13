----------------------------------------------------------------------------------
-- Engineer: Ryan Massie
-- Module Name: ExtendedSteinsHardware - Behavioral
-- Project Name: Extended Steins Hardware: 
-- Description: 
----------------------------------------------------------------------------------

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

entity ExtendedSteinsHardware is
    Generic (
        N : integer := 64;
        NUM_REG : integer := 8
    );
    
    Port (
        -- Control
        CLK    : in STD_LOGIC;
        ENABLE : in STD_LOGIC;
        -- Logic
        INPUT_1       : in STD_LOGIC_VECTOR(N-1 downto 0);
        INPUT_2       : in STD_LOGIC_VECTOR(N-1 downto 0);
        GCD_OUT       : out STD_LOGIC_VECTOR(N-1 downto 0);
        COEFFICIENT_1 : out STD_LOGIC_VECTOR(N-1 downto 0);
        COEFFICIENT_2 : out STD_LOGIC_VECTOR(N-1 downto 0);
        DONE_OUT      : out STD_LOGIC
    );
  
end ExtendedSteinsHardware;

architecture Behavioral of ExtendedSteinsHardware is

component ESteinsController is
    Port (
        -- External Control Signals
        CLK       : in STD_LOGIC;
        ENABLE_IN : in STD_LOGIC;
        -- Data In Signals
        XY_SIGN_IN   : in STD_LOGIC; 
        YX_SIGN_IN   : in STD_LOGIC;
        RS1_OBIT_IN  : in STD_LOGIC;
        RS2_OBIT_IN  : in STD_LOGIC;
        RS3_OBIT_IN  : in STD_LOGIC;
        SUB1_OBIT_IN : in STD_LOGIC;
        SUB2_OBIT_IN : in STD_LOGIC;
        REG_OBITS_IN : in STD_LOGIC_VECTOR(5 downto 0); -- (Y, Yp, Yq, X, Xp, Xq)  
        -- Data Out register
        LOAD_SELECT_OUT : out STD_LOGIC;
        RESET_REG_OUT   : out STD_LOGIC;
        DONE_OUT        : out STD_LOGIC_VECTOR(1 downto 0);
        X_CHECK_AHEAD   : out STD_LOGIC;
        Y_CHECK_AHEAD   : out STD_LOGIC;
        REG_READ_OUT    : out STD_LOGIC_VECTOR(32 downto 0);
        REG_WRITE_OUT   : out STD_LOGIC_VECTOR(23 downto 0);
        REG_WRITE_EN    : out STD_LOGIC_VECTOR(9 downto 0)
    );
end component;

component ESRegisterFile is
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
end component;
-- Controller => Something
signal LOAD_SELECT : STD_LOGIC;
signal RESET_REG : STD_LOGIC;
signal DONE : STD_LOGIC_VECTOR(1 downto 0);
signal X_CHECK_AHEAD : STD_LOGIC;
signal Y_CHECK_AHEAD : STD_LOGIC;
signal REG_OBITS : STD_LOGIC_VECTOR(5 downto 0);
signal R_REG_SELECT : STD_LOGIC_VECTOR(32 downto 0);
signal W_REG_SELECT : STD_LOGIC_VECTOR(23 downto 0);
signal W_ENABLE : STD_LOGIC_VECTOR(9 downto 0);
-- RF => Component 
signal X : STD_LOGIC_VECTOR(N-1 downto 0);
signal Y : STD_LOGIC_VECTOR(N-1 downto 0);
signal Xp : STD_LOGIC_VECTOR(N-1 downto 0);
signal Xq : STD_LOGIC_VECTOR(N-1 downto 0);
signal Yp : STD_LOGIC_VECTOR(N-1 downto 0);
signal Yq : STD_LOGIC_VECTOR(N-1 downto 0);
signal RS1 : STD_LOGIC_VECTOR(N-1 downto 0);
signal RS2 : STD_LOGIC_VECTOR(N-1 downto 0);
signal RS3 : STD_LOGIC_VECTOR(N-1 downto 0);
signal LS1 : STD_LOGIC_VECTOR(N-1 downto 0);
signal LS2 : STD_LOGIC_VECTOR(N-1 downto 0);
signal ADD11 : STD_LOGIC_VECTOR(N-1 downto 0);
signal ADD12 : STD_LOGIC_VECTOR(N-1 downto 0);
signal SUB11 : STD_LOGIC_VECTOR(N-1 downto 0);
signal SUB12 : STD_LOGIC_VECTOR(N-1 downto 0);
signal SUB21 : STD_LOGIC_VECTOR(N-1 downto 0);
signal SUB22 : STD_LOGIC_VECTOR(N-1 downto 0);
-- Component => RF 
signal RS1_RESULT : STD_LOGIC_VECTOR(N-1 downto 0);
signal RS2_RESULT : STD_LOGIC_VECTOR(N-1 downto 0);
signal RS3_RESULT : STD_LOGIC_VECTOR(N-1 downto 0);
signal LS1_RESULT : STD_LOGIC_VECTOR(N-1 downto 0);
signal LS2_RESULT : STD_LOGIC_VECTOR(N-1 downto 0);
signal ADD_RESULT : STD_LOGIC_VECTOR(N-1 downto 0);
signal SUB1_RESULT : STD_LOGIC_VECTOR(N-1 downto 0);
signal SUB2_RESULT : STD_LOGIC_VECTOR(N-1 downto 0);
signal XY_RESULT : STD_LOGIC_VECTOR(N-1 downto 0);
signal YX_RESULT : STD_LOGIC_VECTOR(N-1 downto 0);

-- Load Select Mux => RF
signal LSMUX1 : STD_LOGIC_VECTOR(N-1 downto 0);
signal LSMUX2 : STD_LOGIC_VECTOR(N-1 downto 0);

-- Check Ahead Mux => SUB
signal X_SUB : STD_LOGIC_VECTOR(N-1 downto 0);
signal Y_SUB : STD_LOGIC_VECTOR(N-1 downto 0);

begin
    -- Component instantiation
    Controller: ESteinsController
        port map (
        CLK => CLK,
        ENABLE_IN => ENABLE,
        XY_SIGN_IN => XY_RESULT(N-1),
        YX_SIGN_IN => YX_RESULT(N-1),
        RS1_OBIT_IN => RS1_RESULT(0),
        RS2_OBIT_IN => RS2_RESULT(0),
        RS3_OBIT_IN => RS3_RESULT(0),
        SUB1_OBIT_IN => SUB1_RESULT(0),
        SUB2_OBIT_IN => SUB2_RESULT(0),
        REG_OBITS_IN => REG_OBITS,
        LOAD_SELECT_OUT => LOAD_SELECT,
        RESET_REG_OUT => RESET_REG,
        DONE_OUT => DONE,
        X_CHECK_AHEAD => X_CHECK_AHEAD,
        Y_CHECK_AHEAD => Y_CHECK_AHEAD,
        REG_READ_OUT => R_REG_SELECT,
        REG_WRITE_OUT => W_REG_SELECT,
        REG_WRITE_EN => W_ENABLE
    );

    RegisterFile: ESRegisterFile
        port map(
        -- Control
        CLK => CLK,
        RESET => RESET_REG,
        -- Inputs
        W_ENABLE_IN    => W_ENABLE,
        W_REG_IN       => W_REG_SELECT,
        W_INPUTS_IN(0) => LSMUX1,
        W_INPUTS_IN(1) => LSMUX2,
        W_INPUTS_IN(2) => RS3_RESULT,
        W_INPUTS_IN(3) => LS1_RESULT,
        W_INPUTS_IN(4) => LS2_RESULT,
        W_INPUTS_IN(5) => ADD_RESULT,
        W_INPUTS_IN(6) => SUB1_RESULT,
        W_INPUTS_IN(7) => SUB2_RESULT,
        W_INPUTS_IN(8) => XY_RESULT,
        W_INPUTS_IN(9) => YX_RESULT,
        READ_IN        => R_REG_SELECT,
        -- Outputs
        REG_OBITS_OUT => REG_OBITS,
        X_OUT => X,        
        Xp_OUT => Xp,       
        Xq_OUT => Xq,       
        Y_OUT => Y,        
        Yp_OUT => Yp,       
        Yq_OUT => Yq,       
        RS1_READ_OUT => RS1, 
        RS2_READ_OUT => RS2, 
        RS3_READ_OUT => RS3, 
        LS1_READ_OUT => LS1, 
        LS2_READ_OUT => LS2, 
        A11_READ_OUT => ADD11, 
        A12_READ_OUT => ADD12, 
        S11_READ_OUT => SUB11, 
        S12_READ_OUT => SUB12, 
        S21_READ_OUT => SUB21, 
        S22_READ_OUT => SUB22 
    );
    
    -- Update on all signals and 
    process(CLK, ENABLE, INPUT_1, INPUT_2, LOAD_SELECT, DONE, REG_OBITS, R_REG_SELECT, W_REG_SELECT, W_ENABLE, X, Y, Xp, Xq, 
            Yp, Yq, RS1, RS2, RS3, LS1, LS2, ADD11, ADD12, SUB11, SUB12, SUB21, SUB22, RS1_RESULT, RS2_RESULT, RS3_RESULT, 
            LS1_RESULT, LS2_RESULT, ADD_RESULT, SUB1_RESULT, SUB2_RESULT, XY_RESULT, YX_RESULT, LSMUX1, LSMUX2)
    begin
        -- Sub Mux
        if X_CHECK_AHEAD = '1' then
            X_SUB <= X(N-1) & X(N-1 downto 1);
        else 
            X_SUB <= X;
        end if;
        
        if Y_CHECK_AHEAD = '1' then
            Y_SUB <= Y(N-1) & Y(N-1 downto 1);
        else
            Y_SUB <= Y;
        end if;
        
        -- Load Mux
        if LOAD_SELECT = '1' then
            LSMUX1 <= INPUT_1;
            LSMUX2 <= INPUT_2;
        else
            LSMUX1 <= RS1_RESULT;
            LSMUX2 <= RS2_RESULT;
        end if;
        
        -- Done --WIP--
        DONE_OUT <= DONE(1);
        if DONE = "10" then
            GCD_OUT <= X;
            COEFFICIENT_1  <= Xp;
            COEFFICIENT_2  <= Xq;
        elsif DONE = "11" then
            GCD_OUT <= Y;
            COEFFICIENT_1  <= Yp;
            COEFFICIENT_2  <= Yq;
        else
            GCD_OUT <= (others => '0');
            COEFFICIENT_1  <= (others => '0');
            COEFFICIENT_2  <= (others => '0');
        end if;
        
        -- Componants
        RS1_RESULT  <= RS1(N-1) & RS1(N-1 downto 1);
        RS2_RESULT  <= RS2(N-1) & RS2(N-1 downto 1);
        RS3_RESULT  <= RS3(N-1) & RS3(N-1 downto 1);
        LS1_RESULT  <= LS1(N-2 downto 0) & '0';
        LS2_RESULT  <= LS2(N-2 downto 0) & '0';
        ADD_RESULT  <= STD_LOGIC_VECTOR(SIGNED(ADD11) + SIGNED(ADD12));
        SUB1_RESULT <= STD_LOGIC_VECTOR(SIGNED(SUB11) - SIGNED(SUB12));
        SUB2_RESULT <= STD_LOGIC_VECTOR(SIGNED(SUB21) - SIGNED(SUB22));
        XY_RESULT   <= STD_LOGIC_VECTOR(SIGNED(X_SUB) - SIGNED(Y_SUB));
        YX_RESULT   <= STD_LOGIC_VECTOR(SIGNED(Y_SUB) - SIGNED(X_SUB));
       
    end process;

end Behavioral;
