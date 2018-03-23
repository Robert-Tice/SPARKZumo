--  pragma SPARK_Mode;

with Types; use Types;
with Interfaces.C; use Interfaces.C;

--  @summary
--  Interface for the LSM303 accelerometer and magnetometer
--
--  @description
--  This is the interface to the 3D accelerometer and 3D magnetometer
--

package Zumo_LSM303 is

   --  Gain to be applied to magnetometer
   M_Sensitivity : constant Float := 0.000080;   --  gauss/LSB
   --  Gain to be applied to accelerometer
   A_Sensitivity : constant Float := 0.000061;   --  g/LSB

   --  True if package is init'd
   Initd : Boolean := False;

   --  Inits the package.
   procedure Init
     with Pre => not Initd,
     Post => Initd;

   --  Read the temperature from the sensor
   --  @return a 16 bit temperature value
   function Read_Temp return short
     with Pre => Initd;

   --  Read the status of the magnetometer
   --  @return the status of the magnetometer
   function Read_M_Status return Byte
     with Pre => Initd;

   --  Read the status of the accelerometer
   --  @return the status of the accelerometer
   function Read_A_Status return Byte
     with Pre => Initd;

   --  Read the magnetic reading from the sensor
   --  @param Data the data read from the sensor
   procedure Read_Mag (Data : out Axis_Data)
     with Pre => Initd;

   --  Read the acceleration from the sensor
   --  @param Data the acceleration reading from the sensor
   procedure Read_Acc (Data : out Axis_Data)
     with Pre => Initd;

   LSM303_Exception : exception;

private

   --  Read the WHOAMI register in the sensor and check against known value
   procedure Check_WHOAMI;

   --  The mapping of registers in the sensor
   --  @value TEMP_OUT_L The low register of the sensors temperature
   --  @value TEMP_OUT_H the high register of the sensors temperature
   --  @value STATUS_M the status of the magnetometer
   --  @value OUT_X_L_M the low register of the x axis of the magnetometer
   --  @value OUT_X_H_M the high register of the x axis of the magnetometer
   --  @value OUT_Y_L_M the low register of the Y axis of the magnetometer
   --  @value OUT_Y_H_M the high register of the Y axis of the magnetometer
   --  @value OUT_Z_L_M the low register of the Z axis of the magnetometer
   --  @value OUT_Z_H_M the high register of the Z axis of the magnetometer
   --  @value WHO_AM_I the who am i register
   --  @value STATUS_A the status of the accelerometer
   --  @value OUT_X_L_A the low register of the x axis of the accelerometer
   --  @value OUT_X_H_A the high register of the x axis of the accelerometer
   --  @value OUT_Y_L_A the low register of the Y axis of the accelerometer
   --  @value OUT_Y_H_A the high register of the Y axis of the accelerometer
   --  @value OUT_Z_L_A the low register of the Z axis of the accelerometer
   --  @value OUT_Z_H_A the high register of the Z axis of the accelerometer
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

   --  The mapping of the enum to the actual register addresses
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
