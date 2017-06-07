pragma SPARK_Mode;

with Types; use Types;

package Zumo_QTR is

   type Calibration is private;

   type Calibration_Array is array (1 .. 6) of Calibration;

   Initd : Boolean := False;

   procedure Init
     with Pre => not Initd,
     Post => Initd;

   procedure Read_Sensors (Sensor_Values : in out Sensor_Array;
                           ReadMode      : in Sensor_Read_Mode);

   procedure ChangeEmitters (On : Boolean);

   procedure Calibrate (ReadMode : Sensor_Read_Mode := Emitters_On);

   procedure ResetCalibration;

   procedure ReadCalibrated (Sensor_Values : out Sensor_Array;
                             ReadMode      : in Sensor_Read_Mode);

   function ReadLine (Sensor_Values : Sensor_Array;
                      ReadMode      : Sensor_Read_Mode;
                      WhiteLine     : Boolean)
                      return Integer;
private

   type Calibration is record
      Min : Sensor_Value := Sensor_Value'Last;
      Max : Sensor_Value := Sensor_Value'First;
   end record;

   Cal_Vals : Calibration_Array;

end Zumo_QTR;
