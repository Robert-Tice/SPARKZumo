pragma SPARK_Mode;

with Types; use Types;

--  @summary
--  Interface for reading infrared sensors
--
--  @description
--  This package exposes the interface used to read values from the IR sensors
--

package Zumo_QTR is

   --  Represents the maximum and minimum values found by a sensor during
   --    a calibration sequence
   --  @field Min the minimum value found during a calibration sequence
   --  @field Max the maximum value found during a calibration sequence
   type Calibration is record
      Min : Sensor_Value := Sensor_Value'Last;
      Max : Sensor_Value := Sensor_Value'First;
   end record;

   type Calibration_Array is array (1 .. 6) of Calibration;

   --  The list of calibrationm values with the IR leds on
   Cal_Vals_On : Calibration_Array;

   --  The list of calibration values with the IR leds off
   Cal_Vals_Off : Calibration_Array;

   --  True if a calibration was performed with the IR Leds on
   Calibrated_On : Boolean := False;

   --  True if a calibration was performed with the IR Leds off
   Calibrated_Off : Boolean := False;

   --  True if the init was called
   Initd : Boolean := False;

   --  Inits the package by muxing pins and whatnot
   procedure Init
     with Pre => not Initd,
     Post => Initd;

   --  Reads values from the sensors
   --  @param Sensor_Values the array of values read from sensors
   --  @param ReadMode the mode to read the sensors in (LEDs on or off)
   procedure Read_Sensors (Sensor_Values : out Sensor_Array;
                           ReadMode      : Sensor_Read_Mode)
     with Pre => Initd;

   --  Turns the IR leds on or off
   --  @param On True to turn on the IR leds, False to turn off
   procedure ChangeEmitters (On : Boolean)
     with Global => null;

   --  Performs a calibration routine with the sensors
   --  @param ReadMode emitters on or off during calibration
   procedure Calibrate (ReadMode : Sensor_Read_Mode := Emitters_On)
     with Global => (Input  => Initd,
                     In_Out => (Cal_Vals_On,
                                Cal_Vals_Off),
                     Output => (Calibrated_On,
                                Calibrated_Off)),
     Pre => Initd;

   --  Resets the stored calibration data
   --  @param ReadMode which calibration data to reset
   procedure ResetCalibration (ReadMode : Sensor_Read_Mode);

   --  Reads the sensors and offsets using the calibrated values
   --  @param Sensor_Values values read from sensors are returned here
   --  @param ReadMode whether to read with emitters on or off
   procedure ReadCalibrated (Sensor_Values : out Sensor_Array;
                             ReadMode      : Sensor_Read_Mode)
     with Pre => Initd;

private

   --  The actual read work is done here
   --  @param Sensor_Values the sensor values are returned here
   procedure Read_Private (Sensor_Values : out Sensor_Array)
     with Pre => Initd;

   --  The actual calibration work is done here
   --  @param Cal_Vals the calibration array to modify
   --  @param ReadMode calibrate with emitters on or off
   procedure Calibrate_Private (Cal_Vals : in out Calibration_Array;
                                ReadMode : Sensor_Read_Mode)
     with Global => Initd,
     Pre => Initd;

end Zumo_QTR;
