pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;

package Types is

   type Byte is mod 256
     with Size => 8;

   type Word is mod 65536
     with Size => 16;

   type Byte_Array is array (Positive range <>) of Byte
     with Pack;

   type Axises is (X, Y, Z);

   type Axis_Data is array (Axises) of Short;


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

   type Sensor_Value is new Natural range 0 .. 1000;
   type Sensor_Array is array (1 .. 6) of Sensor_Value;

   type Sensor_Read_Mode is
     (Emitters_Off,
      Emitters_On,
      Emitters_On_Off);

   type Motor_Speed is new Integer range -400 .. 400;

end Types;
