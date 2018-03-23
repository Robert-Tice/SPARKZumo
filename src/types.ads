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

   --  enum for tracking axises
   --  @value X x axis
   --  @value Y y axis
   --  @value Z z axis
   type Axises is (X, Y, Z);

   type Axis_Data is array (Axises) of short;

   --  Mode for a pin
   --  @value INPUT input mode
   --  @value OUTPUT output mode
   --  @value INPUT_PULLUP input mode with internal pullup
   type PinMode is
     (INPUT,
      OUTPUT,
      INPUT_PULLUP);

   --  Value for pin
   --  @value LOW pin low
   --  @value HIGH pin high
   type DigPinValue is
     (LOW,
      HIGH);

   --  Pull up state for a pin
   --  @value Disabled pullup disabled
   --  @value Enabled pullup enabled
   type PinPullUpState is
     (Disabled,
      Enabled);

   --  Default state for a pin
   --  @value DefaultStateLow set the default value of a pin low
   --  @value DefaultStateHigh set the default value of a pin high
   type PinDefaultState is
     (DefaultStateLow,
      DefaultStateHigh);

   --  Frequency for the buzzer
   type Frequency is new Natural range 40 .. 10_000;

   --  Volume for the buzzer
   type Volume is new Natural range 0 .. 15
     with Size => 8;

   --  Duration for a note on the buzzer
   type Duration is new Natural;

   --  Max value that a sensor will have to decay
   Timeout : constant := 1000;

   --  Number of sensors in the array
   Num_Sensors : constant := 6;

   type Sensor_Value is new Natural range 0 .. Timeout;
   type Sensor_Array is array (1 .. Num_Sensors) of Sensor_Value;

   Robot_Scale : constant := (Num_Sensors - 1) * Timeout / 2;

   --  Type used to determine where with the line is ref to the robot
   subtype Robot_Position is Integer range (-1) * Robot_Scale .. Robot_Scale;

   subtype Sensor_Value_Scaled is Float range 0.0 .. 1.0;
   type Sensor_Scaled_Array is array (1 .. 6) of Sensor_Value_Scaled;

   --  Mode to read sensors with
   --  @value Emitters_Off read sensors with emitters off
   --  @value Emitters_On read sensors with the emitters on
   --  @value Emitters_On_Off read sensors with emitters on then again with off
   type Sensor_Read_Mode is
     (Emitters_Off,
      Emitters_On,
      Emitters_On_Off);

   --  Max value for the motor speed
   PWM_Max : constant := 400;

   subtype Motor_Speed is Integer range (-1) * PWM_Max .. PWM_Max;

   subtype Degrees is Float;

   type Degree_Axis is array (Axises) of Degrees;

   type Boolean_Array is array (Integer range <>) of Boolean;

end Types;
