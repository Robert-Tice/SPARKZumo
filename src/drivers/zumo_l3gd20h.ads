pragma SPARK_Mode;

with Types; use Types;
with Interfaces.C; use Interfaces.C;

package Zumo_L3gd20h is

   Gain : constant := 0.07;  -- degrees/s/digit

   Initd : Boolean := False;

   procedure Init
     with Pre => not Initd,
     Post => Initd;

   function Read_Temp return Signed_Char
     with Pre => Initd;
   function Read_Status return Byte
     with Pre => Initd;

   procedure Read_Gyro (Data : out Axis_Data)
     with Pre => Initd;

   L3GD20H_Exception : exception;

private

   procedure Check_WHOAMI;

   type Reg_Index is
     (WHO_AM_I,
      CTRL1,
      CTRL2,
      CTRL3,
      CTRL4,
      CTRL5,
      REFERENCE,
      OUT_TEMP,
      STATUS,
      OUT_X_L,
      OUT_X_H,
      OUT_Y_L,
      OUT_Y_H,
      OUT_Z_L,
      OUT_Z_H,
      FIFO_CTRL,
      FIFO_SRC,
      IG_CFG,
      IG_SRC,
      IG_THS_XH,
      IG_THS_XL,
      IG_THS_YH,
      IG_THS_YL,
      IG_THS_ZH,
      IG_THS_ZL,
      IG_DURATION,
      LOW_ODR);

   Regs : array (Reg_Index) of Byte := (WHO_AM_I    => 16#0F#,
                                        CTRL1       => 16#20#,
                                        CTRL2       => 16#21#,
                                        CTRL3       => 16#22#,
                                        CTRL4       => 16#23#,
                                        CTRL5       => 16#24#,
                                        REFERENCE   => 16#25#,
                                        OUT_TEMP    => 16#26#,
                                        STATUS      => 16#27#,
                                        OUT_X_L     => 16#28#,
                                        OUT_X_H     => 16#29#,
                                        OUT_Y_L     => 16#2A#,
                                        OUT_Y_H     => 16#2B#,
                                        OUT_Z_L     => 16#2C#,
                                        OUT_Z_H     => 16#2D#,
                                        FIFO_CTRL   => 16#2E#,
                                        FIFO_SRC    => 16#2F#,
                                        IG_CFG      => 16#30#,
                                        IG_SRC      => 16#31#,
                                        IG_THS_XH   => 16#32#,
                                        IG_THS_XL   => 16#33#,
                                        IG_THS_YH   => 16#34#,
                                        IG_THS_YL   => 16#35#,
                                        IG_THS_ZH   => 16#36#,
                                        IG_THS_ZL   => 16#37#,
                                        IG_DURATION => 16#38#,
                                        LOW_ODR     => 16#39#);

end Zumo_L3gd20h;
