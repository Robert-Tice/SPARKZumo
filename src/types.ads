pragma SPARK_Mode;



package Types is

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
   type Duration is new Natural range 0 .. 65535;

   type Sensor_Value is new Natural range 0 .. 1000;
   type Sensor_Array is array (1 .. 6) of Sensor_Value;

   type Sensor_Read_Mode is
     (Emitters_Off,
      Emitters_On,
      Emitters_On_Off);

   type Motor_Speed is new Integer range -400 .. 400;

end Types;
