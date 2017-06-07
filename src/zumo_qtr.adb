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

   SensorPins : array (1 .. 6) of unsigned_char := (4, 16#A3#, 11, 16#A0#, 16#A2#, 5);


   procedure Init
   is
   begin
      Initd := True;
   end Init;

   procedure Read_Private (Sensor_Values : in out Sensor_Array)
   is
      StartTime : Unsigned_Long;
      ElapsedTime : Unsigned_Long := 0;
   begin
      for I in Sensor_Values'Range loop
         Sensor_Values (I) := Sensor_Value'Last;
         SetPinMode (Pin  => SensorPins (I),
                     Mode => PinMode'Pos (OUTPUT));
         DigitalWrite (Pin => SensorPins (I),
                       Val => DigPinValue'Pos(HIGH));
      end loop;

      DelayMicroseconds (Time => 10);

      for I in Sensor_Values'Range loop
         SetPinMode (Pin  => SensorPins (I),
                     Mode => PinMode'Pos(INPUT));
         DigitalWrite (Pin => SensorPins (I),
                       Val => DigPinValue'Pos(LOW));
      end loop;

      StartTime := Micros;

      while ElapsedTime < Unsigned_Long(Sensor_Value'Last) loop
         ElapsedTime := Micros - StartTime;
         for I in Sensor_Values'Range loop
            if DigitalRead (Pin => SensorPins (I)) = DigPinValue'Pos(LOW) and
              ElapsedTime < Unsigned_Long(Sensor_Values (I)) then
               Sensor_Values (I) := Sensor_Value(ElapsedTime);
            end if;
         end loop;
      end loop;

   end Read_Private;


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

      Read_Private (Sensor_Values => Sensor_Values);
      ChangeEmitters (On => False);

      if ReadMode = Emitters_On_Off then
      Read_Private (Sensor_Values => Off_Values);
         for I in Sensor_Values'Range loop
            Sensor_Values (I) := Sensor_Values (I) + Sensor_Value'Last - Off_Values (I);
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
      Vals : Sensor_Array;
   begin
      ResetCalibration;

      for I in 1 .. 10 loop
         Read_Sensors (Sensor_Values => Vals,
                       ReadMode      => ReadMode);
         if I = 0 or Cal_Val (I).Max < Vals (I) then
            Cal_Vals (I).Max := Vals (I);
         end if;

         if I = 0 or Cal_Vals (I).Min > Vals (I) then
            Cal_Vals (I).Min := Vals (I);
         end if;
      end loop;
   end Calibrate;

   procedure ResetCalibration
   is
   begin
      for I in Cal_Vals'Range loop
         Cal_Vals(I) := Calibration'(Min => Sensor_Value'Last,
                                     Max => Sensor_Value'First);
      end loop;
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
