--  pragma SPARK_Mode;

with Types; use Types;
with Interfaces.C; use Interfaces.C;

--  @summary
--  Interface to the robots 3-axis gyroscope
--
--  @description
--  This package exposes the interface to the robot's 3 axis gyroscope
--
package Zumo_L3gd20h is

   --  The gain to apply to a sensor reading
   Gain : constant := 0.07;  -- degrees/s/digit

   --  True if package is init'd
   Initd : Boolean := False;

   --  Inits the package. Pin muxing and whatnot.
   procedure Init
     with Global => (In_Out => Initd),
     Pre => not Initd,
     Post => Initd;

   --  Read the temperature of the sensor
   --  @return a byte value with the temperature
   function Read_Temp return signed_char
     with Pre => Initd;

   --  Read the status of the sensor
   --  @return a byte value with the status
   function Read_Status return Byte
     with Pre => Initd;

   --  Read the gyro of the sensor
   --  @param Data the read data from the sensor
   procedure Read_Gyro (Data : out Axis_Data)
     with Pre => Initd;

   L3GD20H_Exception : exception;

private

   --  Reads the WHOAMI register from the sensor and compares it against
   --    the known value
   procedure Check_WHOAMI;

   --  The mapping of registers in the sensor
   --  @value WHO_AM_I Device identification register
   --  @value CTRL1 control 1 register
   --  @value CTRL2 control 2 register
   --  @value CTRL3 control 3 register
   --  @value CTRL4 control 4 register
   --  @value CTRL5 control 5 register
   --  @value REFERENCE Digital high pass filter reference value
   --  @value OUT_TEMP Temperature data (-1LSB/deg with 8 bit resolution).
   --    The value is expressed as two's complement.
   --  @value STATUS sensor status register
   --  @value OUT_X_L X-axis angular rate data low register
   --  @value OUT_X_H X-axis angular rate data high register
   --  @value OUT_Y_L Y-axis angular rate data low register
   --  @value OUT_Y_H Y-axis angular rate data high register
   --  @value OUT_Z_L Z-axis angular rate data low register
   --  @value OUT_Z_H Z-axis angular rate data high register
   --  @value FIFO_CTRL fifo control register
   --  @value FIFO_SRC stored data level in fifo

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

   --  Mapping of register enums to actual register addresses
   Regs : constant array (Reg_Index) of Byte := (WHO_AM_I    => 16#0F#,
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

   type Register_Bytes is record
      Register : Reg_Index;
      Value    : Byte;
   end record;

   type Register_Byte_Array is array (Natural range <>) of Register_Bytes;

end Zumo_L3gd20h;
