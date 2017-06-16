pragma SPARK_Mode;

with Types; use Types;

package Zumo_QTR is

   type Calibration is record
      Min : Sensor_Value := Sensor_Value'Last;
      Max : Sensor_Value := Sensor_Value'First;
   end record;

   type Calibration_Array is array (1 .. 6) of Calibration;

   Initd : Boolean := False;

   procedure Init
     with Pre => not Initd,
     Post => Initd;

   procedure Read_Sensors (Sensor_Values : out Sensor_Array;
                           ReadMode      : in Sensor_Read_Mode);

   procedure ChangeEmitters (On : Boolean);

   procedure Calibrate (ReadMode : Sensor_Read_Mode := Emitters_On);

   procedure ResetCalibration (ReadMode : Sensor_Read_Mode);

   procedure ReadCalibrated (Sensor_Values : out Sensor_Array;
                             ReadMode      : in Sensor_Read_Mode);

   procedure ReadLine (Sensor_Values : out Sensor_Array;
                      ReadMode      : Sensor_Read_Mode;
                      WhiteLine     : Boolean;
                      Bot_Pos       : out Natural);

   Cal_Vals_On : Calibration_Array;
   Cal_Vals_Off : Calibration_Array;

end Zumo_QTR;
