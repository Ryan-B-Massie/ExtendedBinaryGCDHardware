library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ESteinsController is
    Generic (
        N       : integer := 64;
        N_WIDTH : integer := 6 -- Number of bits required to represent N width
    );
    
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
        -- Data Out
        LOAD_SELECT_OUT : out STD_LOGIC;
        RESET_REG_OUT   : out STD_LOGIC;
        DONE_OUT        : out STD_LOGIC_VECTOR(1 downto 0);
        X_CHECK_AHEAD   : out STD_LOGIC;
        Y_CHECK_AHEAD   : out STD_LOGIC;
        REG_READ_OUT    : out STD_LOGIC_VECTOR(32 downto 0);
        REG_WRITE_OUT   : out STD_LOGIC_VECTOR(23 downto 0);
        REG_WRITE_EN    : out STD_LOGIC_VECTOR(9 downto 0)
    );
end ESteinsController;

architecture Behavioral of EsteinsController is
    -- Define the state type
    type state_type is (
        SM_LOAD,
        SM_SHRINK,
        SM_ADJUST_X,
        SM_SHIFT_X,
        SM_REDUCE_X,
        SM_ADJUST_Y,
        SM_SHIFT_Y,
        SM_REDUCE_Y,
        SM_INFLATE,
        SM_DONE_X,
        SM_DONE_Y
    );
    -- Signals for the current state and next state
    signal CURRENT_STATE : state_type := SM_LOAD;
    signal NEXT_STATE : state_type := SM_LOAD;
    -- Internal Signals
    signal K : STD_LOGIC_VECTOR(N_WIDTH-1 downto 0) := (others => '0');
    
begin
    -- Clock Logic
    process(CLK, ENABLE_IN)
        begin
        if ENABLE_IN = '1' then
            if rising_edge(CLK) then
                CURRENT_STATE <= NEXT_STATE;
                -- Check K
                if CURRENT_STATE = SM_SHRINK then
                    K <= std_logic_vector(unsigned(K) + 1);
                elsif CURRENT_STATE = SM_INFLATE then
                    K <= std_logic_vector(unsigned(K) - 1);
                elsif CURRENT_STATE = SM_LOAD then
                    K <= (others => '0'); 
                end if;
            end if;
        else
            CURRENT_STATE <= SM_LOAD;
        end if;
    end process;
    
    -- Next state logic process, updates with any relevant input signal change
    process(CURRENT_STATE, XY_SIGN_IN, YX_SIGN_IN, RS1_OBIT_IN, RS2_OBIT_IN, RS3_OBIT_IN, REG_OBITS_IN, SUB1_OBIT_IN, SUB2_OBIT_IN, K)
        -- Register Addresses
        constant X  : std_logic_vector(2 downto 0) := "000";
        constant Xp : std_logic_vector(2 downto 0) := "001";
        constant Xq : std_logic_vector(2 downto 0) := "010";
        constant X0 : std_logic_vector(2 downto 0) := "011";
        constant Y  : std_logic_vector(2 downto 0) := "100";
        constant Yp : std_logic_vector(2 downto 0) := "101";
        constant Yq : std_logic_vector(2 downto 0) := "110";
        constant Y0 : std_logic_vector(2 downto 0) := "111";
    begin 
        case CURRENT_STATE is
            when SM_LOAD =>
                -- Output
                LOAD_SELECT_OUT <= '1';
                RESET_REG_OUT   <= '1';
                DONE_OUT        <= "00";
                X_CHECK_AHEAD   <= '0';
                Y_CHECK_AHEAD   <= '0';
                REG_READ_OUT    <= "000000000000000000000000000000000"; -- Don't Care
                REG_WRITE_OUT   <= "000000000000000000000000"; -- Don't Care
                REG_WRITE_EN    <= "0000000000"; -- Don't Care
                -- Next State
                if REG_OBITS_IN(0) = '0' AND REG_OBITS_IN(3) = '0' then -- New X & Y are Even
                    if YX_SIGN_IN = '0' AND XY_SIGN_IN = '0' then -- Both Inputs are equal
                        NEXT_STATE <= SM_DONE_X;
                    else
                        NEXT_STATE <= SM_SHRINK;
                    end if;
                elsif REG_OBITS_IN(0) = '0' then -- X is even
                    if REG_OBITS_IN(2) = '1' OR REG_OBITS_IN(1) = '1' then -- Xp or Xq are odd
                        NEXT_STATE <= SM_ADJUST_X;
                    else
                        NEXT_STATE <= SM_SHIFT_X;
                    end if;
                elsif REG_OBITS_IN(3) = '0' then -- Y is even
                    if REG_OBITS_IN(5) = '1' OR REG_OBITS_IN(4) = '1' then -- Yp or Yq are odd
                        NEXT_STATE <= SM_ADJUST_Y;
                    else
                        NEXT_STATE <= SM_SHIFT_Y;
                    end if;
                elsif YX_SIGN_IN = '1' then -- X > Y
                    NEXT_STATE <= SM_REDUCE_X;
                elsif XY_SIGN_IN = '1' then -- Y > X
                    NEXT_STATE <= SM_REDUCE_Y;
                end if;
         
            when SM_SHRINK =>
                -- Output
                LOAD_SELECT_OUT <= '0';
                RESET_REG_OUT   <= '1';
                DONE_OUT        <= "00";    
                X_CHECK_AHEAD   <= '0';
                Y_CHECK_AHEAD   <= '0';
                REG_READ_OUT    <= "000000000000000000000000000" & Y & X;
                REG_WRITE_OUT   <= "000000000000000000000000"; -- Don't Care
                REG_WRITE_EN    <= "0000000000"; -- Don't Care
                -- Next State
                if RS1_OBIT_IN = '0' AND RS2_OBIT_IN = '0' then -- New X & Y are Even
                    NEXT_STATE <= SM_SHRINK;
                elsif RS1_OBIT_IN = '0' then -- X is even
                    if REG_OBITS_IN(2) = '1' OR REG_OBITS_IN(1) = '1' then -- Xp or Xq are odd
                        NEXT_STATE <= SM_ADJUST_X;
                    else
                        NEXT_STATE <= SM_SHIFT_X;
                    end if;
                elsif RS2_OBIT_IN = '0' then -- Y is even
                    if REG_OBITS_IN(5) = '1' OR REG_OBITS_IN(4) = '1' then -- Yp or Yq are odd
                        NEXT_STATE <= SM_ADJUST_Y;
                    else
                        NEXT_STATE <= SM_SHIFT_Y;
                    end if;
                elsif YX_SIGN_IN = '1' then -- X > Y
                    NEXT_STATE <= SM_REDUCE_X;
                elsif XY_SIGN_IN = '1' then -- Y > X
                    NEXT_STATE <= SM_REDUCE_Y;
                end if;
                
            when SM_ADJUST_X =>    
                -- Output
                LOAD_SELECT_OUT <= '0';
                RESET_REG_OUT   <= '0';
                DONE_OUT        <= "00"; 
                X_CHECK_AHEAD   <= '0';
                Y_CHECK_AHEAD   <= '0';  
                REG_READ_OUT    <= "000000" & Y0 & Xp & X0 & Xq & "000000000000000";
                REG_WRITE_OUT   <= "000" & Xp & Xq & "000000000000000";
                REG_WRITE_EN    <= "0001100000";
                -- Next State
                NEXT_STATE <= SM_SHIFT_X;
                
            when SM_SHIFT_X =>
                -- Output
                LOAD_SELECT_OUT <= '0';
                RESET_REG_OUT   <= '0';
                DONE_OUT        <= "00"; 
                X_CHECK_AHEAD   <= '1';
                Y_CHECK_AHEAD   <= '0';  
                REG_READ_OUT    <= "000000000000000000000000" & Xq & Xp & X;
                REG_WRITE_OUT   <= "000000000000000" & Xq & Xp & X;
                REG_WRITE_EN    <= "0000000111";
                -- Next State
                if RS1_OBIT_IN = '0' then -- New X is even
                    if RS2_OBIT_IN = '1' OR RS3_OBIT_IN = '1' then -- new Xp or Xq are odd
                        NEXT_STATE <= SM_ADJUST_X; 
                    else 
                        NEXT_STATE <= SM_SHIFT_X; 
                    end if;
                else
                    if XY_SIGN_IN = '0' then -- Work on X
                        NEXT_STATE <= SM_REDUCE_X; 
                    else
                        NEXT_STATE <= SM_REDUCE_Y; 
                    end if;
                end if;
                
            when SM_REDUCE_X =>           
                -- Output
                LOAD_SELECT_OUT <= '0';
                RESET_REG_OUT   <= '0';
                DONE_OUT        <= "00";
                X_CHECK_AHEAD   <= '0';
                Y_CHECK_AHEAD   <= '0';   
                REG_READ_OUT    <= Yq & Xq & Yp & Xp & "000000000000000000000";
                REG_WRITE_OUT   <= Xq & Xp & "000000000000000000";
                REG_WRITE_EN    <= "0111000000";
                -- Next State
                if XY_SIGN_IN = '0' AND YX_SIGN_IN = '0' then
                    if unsigned(K) > 0 then
                        NEXT_STATE <= SM_INFLATE;
                    else
                        NEXT_STATE <= SM_DONE_Y;
                    end if;
                elsif SUB1_OBIT_IN = '1' OR SUB2_OBIT_IN = '1' then -- Xp or Xq are odd
                    NEXT_STATE <= SM_ADJUST_X;
                else
                    NEXT_STATE <= SM_SHIFT_X;
                end if;
                
            when SM_ADJUST_Y =>         
                -- Output
                LOAD_SELECT_OUT <= '0';
                RESET_REG_OUT   <= '0';
                DONE_OUT        <= "00";
                X_CHECK_AHEAD   <= '0';
                Y_CHECK_AHEAD   <= '0';   
                REG_READ_OUT    <= "000000" & Y0 & Yp & X0 & Yq & "000000000000000";
                REG_WRITE_OUT   <= "000" & Yp & Yq & "000000000000000";
                REG_WRITE_EN    <= "0001100000";                
                -- Next State
                NEXT_STATE <= SM_SHIFT_Y;
                
            when SM_SHIFT_Y =>         
                -- Output
                LOAD_SELECT_OUT <= '0';
                RESET_REG_OUT   <= '0';
                DONE_OUT        <= "00";    
                X_CHECK_AHEAD   <= '0';
                Y_CHECK_AHEAD   <= '1';
                REG_READ_OUT    <= "000000000000000000000000" & Yq & Yp & Y;
                REG_WRITE_OUT   <= "000000000000000" & Yq & Yp & Y;
                REG_WRITE_EN    <= "0000000111";
                -- Next State
                if RS1_OBIT_IN = '0' then -- New Y is even
                    if RS2_OBIT_IN = '1' OR RS3_OBIT_IN = '1' then -- new Yp or Yq are odd
                        NEXT_STATE <= SM_ADJUST_Y; 
                    else 
                        NEXT_STATE <= SM_SHIFT_Y; 
                    end if;
                else
                    if XY_SIGN_IN = '1' then
                        NEXT_STATE <= SM_REDUCE_Y; 
                    else
                        NEXT_STATE <= SM_REDUCE_X; 
                    end if;
                end if;
                
            when SM_REDUCE_Y =>                       
                -- Output
                LOAD_SELECT_OUT <= '0';
                RESET_REG_OUT   <= '0';
                DONE_OUT        <= "00"; 
                X_CHECK_AHEAD   <= '0';
                Y_CHECK_AHEAD   <= '0';
                REG_READ_OUT    <= Xq & Yq & Xp & Yp & "000000000000000000000";
                REG_WRITE_OUT   <= Yq & Yp & "000000000000000000";
                REG_WRITE_EN    <= "1011000000";          
                -- Next State
                if XY_SIGN_IN = '0' AND YX_SIGN_IN = '0' then
                    if unsigned(K) > 0 then
                        NEXT_STATE <= SM_INFLATE;
                    else
                        NEXT_STATE <= SM_DONE_X;
                    end if;
                elsif  SUB1_OBIT_IN = '1' OR SUB2_OBIT_IN = '1' then -- Xp or Xq are odd
                    NEXT_STATE <= SM_ADJUST_Y;
                else
                    NEXT_STATE <= SM_SHIFT_Y;
                end if;
                
            when SM_INFLATE =>
                -- Output
                LOAD_SELECT_OUT <= '0';
                RESET_REG_OUT   <= '0';
                DONE_OUT        <= "00";  
                X_CHECK_AHEAD   <= '0';
                Y_CHECK_AHEAD   <= '0';  
                REG_READ_OUT    <= "000000000000000000" & Y & X & "000000000";
                REG_WRITE_OUT   <= "000000000" & Y & X & "000000000";
                REG_WRITE_EN    <= "0000011000";
                -- Next State
                if unsigned(K) > 1 then
                    NEXT_STATE <= SM_INFLATE; 
                else -- K = 0
                    if XY_SIGN_IN = '0' then --X > 0 & Y = 0
                        NEXT_STATE <= SM_DONE_X;    
                    else --Y > 0 & X = 0
                        NEXT_STATE <= SM_DONE_Y;
                    end if; 
                end if;
                
            when SM_DONE_X =>          
                -- Output
                LOAD_SELECT_OUT <= '0';
                RESET_REG_OUT   <= '0';
                DONE_OUT        <= "10";   
                X_CHECK_AHEAD   <= '0';
                Y_CHECK_AHEAD   <= '0';
                REG_READ_OUT    <= "000000000000000000000000000000000";
                REG_WRITE_OUT   <= "000000000000000000000000";
                REG_WRITE_EN    <= "0000000000";
                -- Next State
                NEXT_STATE <= SM_DONE_X;
  
            when SM_DONE_Y =>        
                -- Output
                LOAD_SELECT_OUT <= '0';
                DONE_OUT        <= "11";   
                X_CHECK_AHEAD   <= '0';
                Y_CHECK_AHEAD   <= '0';
                REG_READ_OUT    <= "000000000000000000000000000000000";
                REG_WRITE_OUT   <= "000000000000000000000000";
                REG_WRITE_EN    <= "0000000000";
                -- Next State
                NEXT_STATE <= SM_DONE_Y;
 
        end case;
    end process;
end Behavioral;