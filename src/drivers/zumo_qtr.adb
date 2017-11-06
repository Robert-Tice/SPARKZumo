pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;

with Sparkduino; use Sparkduino;

package body Zumo_QTR is

   EmitterPin : constant := 2;

   SensorPins : constant array (1 .. 6) of unsigned_char :=
                  (4, A3, 11, A0, A2, 5);

   Capacitor_Charge : constant := 5;

   procedure Init
   is
   begin
      Initd := True;

      SetPinMode (Pin  => EmitterPin,
                  Mode => PinMode'Pos (OUTPUT));
      DigitalWrite (Pin => EmitterPin,
                    Val => DigPinValue'Pos (LOW));
   end Init;

   procedure Read_Private (Sensor_Values : out Sensor_Array)
   is
      StartTime : unsigned_long;
      ElapsedTime : unsigned_long := 0;

      Pin_Sense   : array (Sensor_Array'Range) of Boolean := (others => False);
      All_Complete : Boolean := False;
   begin
      --  Set I/O line high to charge capacitor node
      for I in Sensor_Values'Range loop
         Sensor_Values (I) := Sensor_Value'Last;

         SetPinMode (Pin  => SensorPins (I),
                     Mode => PinMode'Pos (OUTPUT));
         DigitalWrite (Pin => SensorPins (I),
                       Val => DigPinValue'Pos (HIGH));
      end loop;

      --  delay to wait for charge
      DelayMicroseconds (Time => Capacitor_Charge);

      --  Set I/O lines back to inputs
      for I in Sensor_Values'Range loop
         SetPinMode (Pin  => SensorPins (I),
                     Mode => PinMode'Pos (INPUT));

         --  disable the internal pullup
         DigitalWrite (Pin => SensorPins (I),
                       Val => DigPinValue'Pos (LOW));
      end loop;

      --  measure the time for the voltage to decay
      StartTime := Micros;

      while ElapsedTime < unsigned_long (Sensor_Value'Last) and not
        All_Complete loop
         All_Complete := True;

         for I in Sensor_Values'Range loop

            if not Pin_Sense (I) then

               if DigitalRead (Pin => SensorPins (I)) = DigPinValue'Pos (LOW)
               then
                  Sensor_Values (I) := Sensor_Value (ElapsedTime);
                  Pin_Sense (I) := True;
               else
                  All_Complete := False;
               end if;
            end if;
         end loop;

         DelayMicroseconds (Time => 100);
         ElapsedTime := Micros - StartTime;

      end loop;

   end Read_Private;

   procedure Read_Sensors (Sensor_Values : out Sensor_Array;
                           ReadMode      : Sensor_Read_Mode)
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
            Sensor_Values (I) := (Sensor_Values (I) + Off_Values (I)) / 2;
         end loop;
      end if;
   end Read_Sensors;

   procedure ChangeEmitters (On : Boolean)
   is
   begin
      if On then
         DigitalWrite (Pin => EmitterPin,
                       Val => DigPinValue'Pos (HIGH));
      else
         DigitalWrite (Pin => EmitterPin,
                       Val => DigPinValue'Pos (LOW));
      end if;

      DelayMicroseconds (Time => 200);
   end ChangeEmitters;

   procedure Calibrate_Private (Cal_Vals : in out Calibration_Array;
                                ReadMode : Sensor_Read_Mode)
   is
      Vals : Sensor_Array;
   begin
      for J in 1 .. 10 loop
         Read_Sensors (Sensor_Values => Vals,
                       ReadMode      => ReadMode);

         for I in Vals'Range loop
            if Cal_Vals (I).Max < Vals (I) then
               Cal_Vals (I).Max := Vals (I);
            end if;

            if Cal_Vals (I).Min > Vals (I) then
               Cal_Vals (I).Min := Vals (I);
            end if;
         end loop;
      end loop;

   end Calibrate_Private;

   procedure Calibrate (ReadMode : Sensor_Read_Mode := Emitters_On)
   is
   begin
      case ReadMode is
         when Emitters_On =>
            Calibrate_Private (Cal_Vals => Cal_Vals_On,
                               ReadMode => ReadMode);
            Cal_Vals_Off := (others =>
                                Calibration'(Min => Sensor_Value'Last,
                                             Max => Sensor_Value'First));
            Calibrated_On := True;
            Calibrated_Off := False;
         when Emitters_Off =>
            Calibrate_Private (Cal_Vals => Cal_Vals_Off,
                               ReadMode => ReadMode);

            Cal_Vals_On := (others => Calibration'(Min => Sensor_Value'Last,
                                                   Max => Sensor_Value'First));
            Calibrated_Off := True;
            Calibrated_On := False;
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
                             ReadMode      : Sensor_Read_Mode)
   is
      CalMin : Sensor_Value;
      CalMax : Sensor_Value;
      Denom  : Sensor_Value;
      X      : long;
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
               if Sensor_Values (I) > Cal_Vals_On (I).Max then
                  Cal_Vals_On (I).Max := Sensor_Values (I);
               end if;
               if Sensor_Values (I) < Cal_Vals_On (I).Min then
                  Cal_Vals_On (I).Min := Sensor_Values (I);
               end if;

               CalMax := Cal_Vals_On (I).Max;
               CalMin := Cal_Vals_On (I).Min;
            when Emitters_Off =>
               if Sensor_Values (I) > Cal_Vals_Off (I).Max then
                  Cal_Vals_Off (I).Max := Sensor_Values (I);
               end if;
               if Sensor_Values (I) < Cal_Vals_Off (I).Min then
                  Cal_Vals_Off (I).Min := Sensor_Values (I);
               end if;

               CalMax := Cal_Vals_Off (I).Max;
               CalMin := Cal_Vals_Off (I).Min;
            when Emitters_On_Off =>
               --  TODO: handle case where current sensor value is outside of
               --  calibration range
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

         if CalMin < CalMax then
            Denom := CalMax - CalMin;

            X := long (Sensor_Values (I) - CalMin) *
                            long (Sensor_Value'Last) / long (Denom);

            if X < long (Sensor_Value'First) then
               Sensor_Values (I) := Sensor_Value'First;
            elsif X > long (Sensor_Value'Last) then
               Sensor_Values (I) := Sensor_Value'Last;
            else
               Sensor_Values (I) := Sensor_Value (X);
            end if;

         end if;
      end loop;
   end ReadCalibrated;

end Zumo_QTR;
