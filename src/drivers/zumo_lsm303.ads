pragma SPARK_Mode;

with Types; use Types;
with Interfaces.C; use Interfaces.C;

package Zumo_LSM303 is

   M_Sensitivity : constant Float := 0.000080;   --  gauss/LSB
   A_Sensitivity : constant Float := 0.000061;   --  g/LSB

   Initd : Boolean := False;

   procedure Init
     with Pre => not Initd,
     Post => Initd;

   function Read_Temp return short
     with Pre => Initd;
   function Read_M_Status return Byte
     with Pre => Initd;
   function Read_A_Status return Byte
     with Pre => Initd;

   procedure Read_Mag (Data : out Axis_Data)
     with Pre => Initd;
   procedure Read_Acc (Data : out Axis_Data)
     with Pre => Initd;

   LSM303_Exception : exception;

private

   procedure Check_WHOAMI;

   type Reg_Index is
     (TEMP_OUT_L,
      TEMP_OUT_H,
      STATUS_M,
      OUT_X_L_M,
      OUT_X_H_M,
      OUT_Y_L_M,
      OUT_Y_H_M,
      OUT_Z_L_M,
      OUT_Z_H_M,
      WHO_AM_I,
      INT_CTRL_M,
      INT_SRC_M,
      INT_THS_L_M,
      INT_THS_H_M,
      OFFSET_X_L_M,
      OFFSET_X_H_M,
      OFFSET_Y_L_M,
      OFFSET_Y_H_M,
      OFFSET_Z_L_M,
      OFFSET_Z_H_M,
      REFERENCE_X,
      REFERENCE_Y,
      REFERENCE_Z,
      CTRL0,
      CTRL1,
      CTRL2,
      CTRL3,
      CTRL4,
      CTRL5,
      CTRL6,
      CTRL7,
      STATUS_A,
      OUT_X_L_A,
      OUT_X_H_A,
      OUT_Y_L_A,
      OUT_Y_H_A,
      OUT_Z_L_A,
      OUT_Z_H_A,
      FIFO_CTRL,
      FIFO_SRC,
      IG_CFG1,
      IG_SRC1,
      IG_THS1,
      IG_DUR1,
      IG_CFG2,
      IG_SRC2,
      IG_THS2,
      IG_DUR2,
      CLICK_CFG,
      CLICK_SRC,
      CLICK_THS,
      TIME_LIMIT,
      TIME_LATENCY,
      TIME_WINDOW,
      ACT_THS,
      ACT_DUR);

   Regs : array (Reg_Index) of Byte := (TEMP_OUT_L   => 16#05#,
                                        TEMP_OUT_H   => 16#06#,
                                        STATUS_M     => 16#07#,
                                        OUT_X_L_M    => 16#08#,
                                        OUT_X_H_M    => 16#09#,
                                        OUT_Y_L_M    => 16#0A#,
                                        OUT_Y_H_M    => 16#0B#,
                                        OUT_Z_L_M    => 16#0C#,
                                        OUT_Z_H_M    => 16#0D#,
                                        WHO_AM_I     => 16#0F#,
                                        INT_CTRL_M   => 16#12#,
                                        INT_SRC_M    => 16#13#,
                                        INT_THS_L_M  => 16#14#,
                                        INT_THS_H_M  => 16#15#,
                                        OFFSET_X_L_M => 16#16#,
                                        OFFSET_X_H_M => 16#17#,
                                        OFFSET_Y_L_M => 16#18#,
                                        OFFSET_Y_H_M => 16#19#,
                                        OFFSET_Z_L_M => 16#1A#,
                                        OFFSET_Z_H_M => 16#1B#,
                                        REFERENCE_X  => 16#1C#,
                                        REFERENCE_Y  => 16#1D#,
                                        REFERENCE_Z  => 16#1E#,
                                        CTRL0        => 16#1F#,
                                        CTRL1        => 16#20#,
                                        CTRL2        => 16#21#,
                                        CTRL3        => 16#22#,
                                        CTRL4        => 16#23#,
                                        CTRL5        => 16#24#,
                                        CTRL6        => 16#25#,
                                        CTRL7        => 16#26#,
                                        STATUS_A     => 16#27#,
                                        OUT_X_L_A    => 16#28#,
                                        OUT_X_H_A    => 16#29#,
                                        OUT_Y_L_A    => 16#2A#,
                                        OUT_Y_H_A    => 16#2B#,
                                        OUT_Z_L_A    => 16#2C#,
                                        OUT_Z_H_A    => 16#2D#,
                                        FIFO_CTRL    => 16#2E#,
                                        FIFO_SRC     => 16#2F#,
                                        IG_CFG1      => 16#30#,
                                        IG_SRC1      => 16#31#,
                                        IG_THS1      => 16#32#,
                                        IG_DUR1      => 16#33#,
                                        IG_CFG2      => 16#34#,
                                        IG_SRC2      => 16#35#,
                                        IG_THS2      => 16#36#,
                                        IG_DUR2      => 16#37#,
                                        CLICK_CFG    => 16#38#,
                                        CLICK_SRC    => 16#39#,
                                        CLICK_THS    => 16#3A#,
                                        TIME_LIMIT   => 16#3B#,
                                        TIME_LATENCY => 16#3C#,
                                        TIME_WINDOW  => 16#3D#,
                                        ACT_THS      => 16#3E#,
                                        ACT_DUR      => 16#3F#);

end Zumo_LSM303;
