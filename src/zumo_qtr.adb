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

   Calibrated_On : Boolean := False;
   Calibrated_Off : Boolean := False;


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

   procedure Calibrate_Private (Cal_Vals : in out Calibration_Array;
                                ReadMode : Sensor_Read_Mode)
   is
      Vals : Sensor_Array;
   begin
      for I in 1 .. 10 loop
         Read_Sensors (Sensor_Values => Vals,
                       ReadMode      => ReadMode);
         if I = 0 or Cal_Vals (I).Max < Vals (I) then
            Cal_Vals (I).Max := Vals (I);
         end if;

         if I = 0 or Cal_Vals (I).Min > Vals (I) then
            Cal_Vals (I).Min := Vals (I);
         end if;
      end loop;


   end Calibrate_Private;

   procedure Calibrate (ReadMode : Sensor_Read_Mode := Emitters_On)
   is
   begin
      ResetCalibration (ReadMode => ReadMode);
      case ReadMode is
         when Emitters_On =>
            Calibrate_Private (Cal_Vals => Cal_Vals_On,
                               ReadMode => ReadMode);
            Calibrated_On := True;
         when Emitters_Off =>
            Calibrate_Private (Cal_Vals => Cal_Vals_Off,
                               ReadMode => ReadMode);
            Calibrated_Off := True;
         when Emitters_On_Off =>
            Calibrate_Private (Cal_Vals => Cal_Vals_On,
                               ReadMode => ReadMode);
            Calibrate_Private (Cal_Vals => Cal_Vals_Off,
                               ReadMode => ReadMode);
            Calibrated_Off := True;
            Calibrated_On := True;
      end case;
   end Calibrate;


   procedure ResetCalibration (ReadMode : Sensor_Read_Mode)
   is
   begin
      case ReadMode is
         when Emitters_On =>
            for I in Cal_Vals_On'Range loop
               Cal_Vals_On (I) := Calibration'(Min => Sensor_Value'Last,
                                               Max => Sensor_Value'First);
            end loop;
            Calibrated_On := False;
         when Emitters_Off =>
            for I in Cal_Vals_Off'Range loop
               Cal_Vals_Off (I) := Calibration'(Min => Sensor_Value'Last,
                                                Max => Sensor_Value'First);
            end loop;
            Calibrated_On := False;
         when Emitters_On_Off =>
            for I in Cal_Vals_On'Range loop
               Cal_Vals_On (I) := Calibration'(Min => Sensor_Value'Last,
                                               Max => Sensor_Value'First);
            end loop;
            for I in Cal_Vals_Off'Range loop
               Cal_Vals_Off (I) := Calibration'(Min => Sensor_Value'Last,
                                                Max => Sensor_Value'First);
            end loop;
            Calibrated_On := False;
            Calibrated_Off := False;
      end case;
   end ResetCalibration;

   procedure ReadCalibrated (Sensor_Values : out Sensor_Array;
                             ReadMode      : in Sensor_Read_Mode)
   is
      CalMin : Sensor_Value;
      CalMax : Sensor_Value;
      Denom  : Sensor_Value;
      X      : Integer;
   begin
      Read_Sensors (Sensor_Values => Sensor_Values,
                    ReadMode      => ReadMode);

      case ReadMode is
         when Emitters_On =>
            if not Calibrated_On then
               return;
            end if;
         when Emitters_Off =>
            if not Calibrated_Off then
               return;
            end if;
         when Emitters_On_Off =>
            if not Calibrated_On and not Calibrated_Off then
               return;
            end if;
      end case;

      for I in Sensor_Values'Range loop
         case ReadMode is
            when Emitters_On =>
               CalMax := Cal_Vals_On (I).Max;
               CalMin := Cal_Vals_On (I).Min;
            when Emitters_Off =>
               CalMax := Cal_Vals_Off (I).Max;
               CalMin := Cal_Vals_Off (I).Min;
            when Emitters_On_Off =>
               if Cal_Vals_Off (I).Min < Cal_Vals_On (I).Min then
                  CalMin := Sensor_Value'Last;
               else
                  CalMin := Cal_Vals_On (I).Min + Sensor_Value'Last -
                    Cal_Vals_Off (I).Min;
               end if;

               if Cal_Vals_Off (I).Max < Cal_Vals_On (I).Max then
                  CalMax := Sensor_Value'Last;
               else
                  CalMax := Cal_Vals_On (I).Max + Sensor_Value'Last -
                    Cal_Vals_Off (I).Max;
               end if;
         end case;

         Denom := CalMax - CalMin;

         if Denom /= 0 then
            X := Integer ((Sensor_Values (I) - CalMin) * 1000 / Denom);
         end if;

         if X < Integer(Sensor_Value'First) then
            X := Integer(Sensor_Value'First);
         elsif X > Integer(Sensor_Value'Last) then
            X := Integer(Sensor_Value'Last);
         end if;

         Sensor_Values (I) := Sensor_Value(X);
      end loop;
   end ReadCalibrated;

   procedure ReadLine (Sensor_Values : out Sensor_Array;
                       ReadMode      : Sensor_Read_Mode;
                       WhiteLine     : Boolean;
                       Bot_Pos       : out Natural)
   is
      On_Line : Boolean := False;
      Avg     : Integer := 0;
      Sum     : Integer := 0;
      Value   : Sensor_Value;
   begin
      ReadCalibrated (Sensor_Values => Sensor_Values,
                      ReadMode      => ReadMode);

      for I in Sensor_Values'Range loop
         Value := Sensor_Values (I);
         if WhiteLine then
            Value := 1000 - Value;
         end if;

         if Value > 200 then
            On_Line := True;
         end if;

         if Value > 50 then
            Avg := Avg + Integer (Value) * (I * 1000);
            Sum := Sum + Integer (Value);
         end if;
      end loop;

      if not On_Line then
         if LastValue < ((Sensor_Values'Length - 1) * 1000 / 2) then
            Bot_Pos := 0;
            return;
         else
            Bot_Pos := ((Sensor_Values'Length - 1) * 1000);
            return;
         end if;
      end if;

      LastValue := Avg / Sum;

      Bot_Pos := LastValue;

   end ReadLine;



end Zumo_QTR;
