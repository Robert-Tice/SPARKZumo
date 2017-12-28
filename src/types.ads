pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;

package Types is

   type Byte is mod 2 ** 8
     with Size => 8;

   subtype Byte_Array_Index_Type is Byte range Byte'First .. Byte'Last - 1;

   type Word is mod 65536
     with Size => 16;

   type Byte_Array is array (Byte_Array_Index_Type range <>) of Byte
     with Pack;

   type Axises is (X, Y, Z);

   type Axis_Data is array (Axises) of short;

   type PinMode is
     (INPUT,
      OUTPUT,
      INPUT_PULLUP);

   type DigPinValue is
     (LOW,
      HIGH);

   type PinPullUpState is
     (Disabled,
      Enabled);

   type PinDefaultState is
     (DefaultStateLow,
      DefaultStateHigh);

   type Frequency is new Natural range 40 .. 10_000;
   type Volume is new Natural range 0 .. 15
     with Size => 8;
   type Duration is new Natural;

   Timeout : constant := 1000;
   Num_Sensors : constant := 6;

   type Sensor_Value is new Natural range 0 .. Timeout;
   type Sensor_Array is array (1 .. Num_Sensors) of Sensor_Value;

   Robot_Scale : constant := (Num_Sensors - 1) * Timeout / 2;

   subtype Robot_Position is Integer range (-1) * Robot_Scale .. Robot_Scale;

   subtype Sensor_Value_Scaled is Float range 0.0 .. 1.0;
   type Sensor_Scaled_Array is array (1 .. 6) of Sensor_Value_Scaled;

   type Sensor_Read_Mode is
     (Emitters_Off,
      Emitters_On,
      Emitters_On_Off);

   PWM_Max : constant := 400;

   subtype Motor_Speed is Integer range (-1) * PWM_Max .. PWM_Max;

   subtype Degrees is Float;

   type Degree_Axis is array (Axises) of Degrees;

   type Boolean_Array is array (Integer range <>) of Boolean;

end Types;
