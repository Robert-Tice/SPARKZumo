with Interfaces.C; use Interfaces.C;

with Zumo_Motors;
with Zumo_QTR;

package body Line_Finder is

   procedure LineFinder (ReadMode : Sensor_Read_Mode)
   is
      QTR      : Sensor_Array;
      Error    : Robot_Position;

      LeftSpeed, RightSpeed : Motor_Speed;
      Bot_State             : RobotLineState;
   begin
      ReadLine (Sensor_Values => QTR,
                WhiteLine     => True,
                ReadMode      => ReadMode,
                Bot_State     => Bot_State,
                Bot_Pos       => Error);

      case Bot_State is
         when Lost =>
            Offline_Correction (Error => Error);
         when BranchLeft =>
            Offline_Offset := 0;
            Error := Robot_Position'First;
            Default_Speed := Motor_Speed'Last - 50;
         when BranchRight =>
            Offline_Offset := 0;
            Error := Robot_Position'Last;
            Default_Speed := Motor_Speed'Last - 50;
         when Perp | Fork =>
            Offline_Offset := 0;
            if LastValue < Integer ((QTR'Length - 1) *
                                      QTR'Last / 2)
            then
               Error := Robot_Position'First;
            else
               Error := Robot_Position'Last;
            end if;
            Default_Speed := Motor_Speed'Last - 50;
         when Online =>
            Offline_Offset := 0;
            Default_Speed := Motor_Speed'Last;
      end case;

      Error_Correct (Error      => Error,
                     LeftSpeed  => LeftSpeed,
                     RightSpeed => RightSpeed);

      Zumo_Motors.SetSpeed (LeftVelocity  => LeftSpeed,
                            RightVelocity => RightSpeed);
   end LineFinder;

   procedure ReadLine (Sensor_Values : out Sensor_Array;
                       WhiteLine     : Boolean;
                       ReadMode      : Sensor_Read_Mode;
                       Bot_State     : out RobotLineState;
                       Bot_Pos       : out Robot_Position)
   is
      Avg     : long := 0;
      Sum     : long := 0;
      Value   : Sensor_Value;

      LineDetect : Boolean_Array (Sensor_Values'First .. Sensor_Values'Last);
   begin
      Zumo_QTR.ReadCalibrated (Sensor_Values => Sensor_Values,
                               ReadMode      => ReadMode);

      Bot_State := Lost;

      for I in Sensor_Values'Range loop
         Value := Sensor_Values (I);
         if WhiteLine then
            Value := Sensor_Value'Last - Value;
         end if;

         --  keep track of whether we see the line at all
         if Value > Line_Threshold then
            Bot_State := Online;
            LineDetect (I) := True;
         else
            LineDetect (I) := False;
         end if;

         --  only average in values that are above the noise threshold
         if Value > Noise_Threshold then
            Avg := Avg + long (Value) * (long (I - 1) *
                                           long (Sensor_Value'Last));
            Sum := Sum + long (Value);
         end if;
      end loop;

      if Bot_State = Lost then
         if LastValue < Integer ((Sensor_Values'Length - 1) *
                                   Sensor_Value'Last / 2)
         then
            Bot_Pos := Robot_Position'First;
            return;
         else
            Bot_Pos := Robot_Position'Last;
            return;
         end if;

      else
         if Sum /= 0 then
            LastValue := Integer (Avg / Sum);

            if LastValue > Robot_Position'Last * 2 then
               LastValue := Robot_Position'Last * 2;
            end if;

            Bot_Pos := Natural (LastValue) - Robot_Position'Last;
            Bot_State := CalculateBotState (D => LineDetect);
         else
            Bot_Pos := Robot_Position'First;
            Bot_State := Lost;
         end if;
      end if;

   end ReadLine;

   procedure Offline_Correction (Error : in out Robot_Position)
   is
   begin

      if Error < 0 then
         Error := Error + Offline_Offset;
      else
         Error := Error - Offline_Offset;
      end if;

      Offline_Offset := Offline_Offset + Offline_Inc;

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

   function CalculateBotState (D : Boolean_Array)
                               return RobotLineState
   is
      LB : Boolean := True;
      RB : Boolean := True;

      LL : Boolean := False;
   begin
      for I in D'First .. D'Last / 2 loop
         if not D (I) then
            LB := False;
         else
            LL := True;
         end if;
      end loop;

      for I in D'Last / 2 .. D'Last loop
         if not D (I) then
            RB := False;
         else
            LL := True;
         end if;
      end loop;

      if LB and RB then
         return Perp;
      elsif LB then
         return BranchLeft;
      elsif RB then
         return BranchRight;
      end if;

      if D (D'First) and then D (D'Last) then
         return Fork;
      end if;

      if LL then
         return Online;
      end if;

      return Lost;
   end CalculateBotState;

end Line_Finder;
