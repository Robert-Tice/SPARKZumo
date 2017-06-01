pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;

with Sparkduino; use Sparkduino;

package body Zumo_QTR is

   EmitterPin : constant := 2;

   CalibratedMinimumOn : Sensor_Value := Sensor_Value'First;
   CalibratedMaximumOn : Sensor_Value := Sensor_Value'First;
   CalibratedMinimumOff : Sensor_Value := Sensor_Value'First;
   CalibratedMaxiumOff : Sensor_Value := Sensor_Value'First;

   LastValue  : Integer := 0;
   MaxValue : Integer := 2000;

   SensorPins : array (1 .. 6) of unsigned_char := (4, 16#A3#, 11, 16#A0#, 16#A2#, 5);


   procedure Init
   is
   begin
      Initd := True;
   end Init;

   procedure Read_Sensors (Sensor_Values :in out Sensor_Array;
                           ReadMode      : in Sensor_Read_Mode)
   is
      Off_Values : Sensor_Array;
   begin
      case ReadMode is
         when Emitters_On | Emitters_On_Off =>
            ChangeEmitters (On => True);
         when Emitters_Off =>
            ChangeEmitters (On => False);
      end case;

      -- readprivate
      ChangeEmitters (On => False);

      if ReadMode = Emitters_On_Off then
         --readprivate
         for I in Sensor_Values'Range loop
            null;
            --Sensor_Values (I) := Sensor_Values (I) + MaxValue - Off_Values (I);
         end loop;
      end if;
   end Read_Sensors;

   procedure ChangeEmitters (On : Boolean)
   is
   begin
      if On then
         DigitalWrite (Pin => EmitterPin,
                       Val => DigPinValue'Pos(HIGH));
      else
         DigitalWrite (Pin => EmitterPin,
                       Val => DigPinValue'Pos(LOW));
      end if;
      DelayMicroseconds (Time => 200);
   end ChangeEmitters;

   procedure Calibrate (ReadMode : Sensor_Read_Mode := Emitters_On)
   is
   begin
      case ReadMode is
         when Emitters_On =>
            null;
         when Emitters_On_Off =>
            null;
         when Emitters_Off =>
            null;
      end case;
   end Calibrate;

   procedure ResetCalibration
   is
   begin
      null;
   end ResetCalibration;

   procedure ReadCalibrated (Sensor_Values : out Sensor_Array;
                              ReadMode      : in Sensor_Read_Mode)
   is
   begin
      null;
   end ReadCalibrated;

   function ReadLine (Sensor_Values : Sensor_Array;
                      ReadMode : Sensor_Read_Mode;
                      WhiteLine     : Boolean)
                      return Integer
   is
   begin
      return 0;
   end ReadLine;



end Zumo_QTR;
