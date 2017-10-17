with Interfaces.C; use Interfaces.C;

with Zumo_Motors;
with Zumo_QTR;

package body Line_Finder is

   procedure LineFinder (ReadMode : Sensor_Read_Mode)
   is
      QTR      : Sensor_Array;
      Error    : Robot_Position;

      LeftSpeed, RightSpeed : Motor_Speed;
      On_Line               : Boolean;
   begin
      ReadLine (Sensor_Values => QTR,
                WhiteLine     => True,
                ReadMode      => ReadMode,
                On_Line       => On_Line,
                Bot_Pos       => Error);

      if not On_Line then
         Offline_Correction (Error => Error);
      else
         Offline_Offset := 0;
      end if;

      Error_Correct (Error      => Error,
                     LeftSpeed  => LeftSpeed,
                     RightSpeed => RightSpeed);

      Zumo_Motors.SetSpeed (LeftVelocity  => LeftSpeed,
                            RightVelocity => RightSpeed);
   end LineFinder;

   procedure ReadLine (Sensor_Values : out Sensor_Array;
                       WhiteLine     : Boolean;
                       ReadMode      : Sensor_Read_Mode;
                       On_Line       : out Boolean;
                       Bot_Pos       : out Robot_Position)
   is
      Avg     : long := 0;
      Sum     : long := 0;
      Value   : Sensor_Value;

      Noise_Threshold : constant := Timeout / 10;
      Line_Threshold : constant := Timeout / 2;
   begin
      Zumo_QTR.ReadCalibrated (Sensor_Values => Sensor_Values,
                               ReadMode      => ReadMode);

      On_Line := False;

      for I in Sensor_Values'Range loop
         Value := Sensor_Values (I);
         if WhiteLine then
            Value := Sensor_Value'Last - Value;
         end if;

         --  keep track of whether we see the line at all
         if Value > Line_Threshold then
            On_Line := True;
         end if;

         --  only average in values that are above the noise threshold
         if Value > Noise_Threshold then
            Avg := Avg + long (Value) * (long (I - 1) *
                                           long (Sensor_Value'Last));
            Sum := Sum + long (Value);
         end if;
      end loop;

      if not On_Line then
         if LastValue < Integer ((Sensor_Values'Length - 1) *
                                   Sensor_Value'Last / 2)
         then
            Bot_Pos := Robot_Position'First;
            return;
         else
            Bot_Pos := Robot_Position'Last;
            return;
         end if;
      end if;

      if Sum /= 0 then
         LastValue := Integer (Avg / Sum);

         if LastValue > Robot_Position'Last * 2 then
            LastValue := Robot_Position'Last * 2;
         end if;

         Bot_Pos := Natural (LastValue) - Robot_Position'Last;
      else
         Bot_Pos := Robot_Position'First;
      end if;

   end ReadLine;

   procedure Offline_Correction (Error : in out Robot_Position)
   is
   begin

      if Error = Robot_Position'First then
         Error := Error + Offline_Offset;
      elsif Error = Robot_Position'Last then
         Error := Error - Offline_Offset;
      end if;

      if Offline_Offset = (Robot_Position'Last * 2) then
         Offline_Offset := 0;
      else
         Offline_Offset := Offline_Offset + Offline_Inc;
      end if;
   end Offline_Correction;

   procedure Error_Correct (Error : Robot_Position;
                            LeftSpeed : out Motor_Speed;
                            RightSpeed : out Motor_Speed)
   is
      Inv_Prop              : constant := 8;
      Deriv                 : constant := 2;

      SpeedDifference : Integer;
   begin
      SpeedDifference := Error / Inv_Prop + Deriv * (Error - LastError);

      LastError := Error;

      if SpeedDifference > Motor_Speed'Last then
         SpeedDifference := Default_Speed;
      elsif SpeedDifference < Motor_Speed'First then
         SpeedDifference := Default_Speed;
      end if;

      if SpeedDifference < 0 then
         LeftSpeed := Default_Speed + Motor_Speed (SpeedDifference);
         RightSpeed := Default_Speed;
      else
         LeftSpeed := Default_Speed;
         RightSpeed := Default_Speed - Motor_Speed (SpeedDifference);
      end if;

   end Error_Correct;

end Line_Finder;
