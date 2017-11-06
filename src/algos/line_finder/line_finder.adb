pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;

package body Line_Finder is

   Noise_Threshold : constant := Timeout / 10;
   Line_Threshold  : constant := Timeout / 2;

   Fast_Speed      : constant := Motor_Speed'Last - 150;
   Slow_Speed      : constant := Fast_Speed / 2;

   CorrectedThreshold : constant := 5;

   procedure LineFinder (ReadMode : Sensor_Read_Mode)
   is
      Error    : Robot_Position;

      LeftSpeed, RightSpeed, Current_Speed : Motor_Speed;
      Line_State                            : LineState;
   begin
      ReadLine (WhiteLine  => True,
                ReadMode   => ReadMode,
                Line_State => Line_State,
                Bot_Pos    => Error);

      DecisionMatrix (State     => Line_State,
                      Pos       => Error,
                      BaseSpeed => Current_Speed);

      Error_Correct (Error         => Error,
                     Current_Speed => Current_Speed,
                     LeftSpeed     => LeftSpeed,
                     RightSpeed    => RightSpeed);

      Zumo_Motors.SetSpeed (LeftVelocity  => LeftSpeed,
                            RightVelocity => RightSpeed);
   end LineFinder;

   procedure ReadLine (WhiteLine      : Boolean;
                       ReadMode       : Sensor_Read_Mode;
                       Line_State     : out LineState;
                       Bot_Pos        : out Robot_Position)
   is
      Avg     : long := 0;
      Sum     : long := 0;
      Value   : Sensor_Value;

      Sensor_Values : Sensor_Array;
      LineDetect : Boolean_Array (Sensor_Values'First .. Sensor_Values'Last);
   begin
      Zumo_QTR.ReadCalibrated (Sensor_Values => Sensor_Values,
                               ReadMode      => ReadMode);

      Line_State := Lost;

      for I in Sensor_Values'Range loop
         Value := Sensor_Values (I);
         if WhiteLine then
            Value := Sensor_Value'Last - Value;
         end if;

         --  keep track of whether we see the line at all
         if Value > Line_Threshold then
            Line_State := Online;
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

      if Line_State = Lost then
         case BotState.OrientationHistory is
            when Left | Center =>
               Bot_Pos := Robot_Position'First;
            when Right =>
               Bot_Pos := Robot_Position'Last;
         end case;

      else
         if Sum /= 0 then
            BotState.SensorValueHistory := Integer (Avg / Sum);

            if BotState.SensorValueHistory > Robot_Position'Last * 2 then
               BotState.SensorValueHistory := Robot_Position'Last * 2;
            end if;

            Bot_Pos := Natural (BotState.SensorValueHistory) -
              Robot_Position'Last;

            if Bot_Pos < 0 then
               BotState.OrientationHistory := Left;
            elsif Bot_Pos > 0 then
               BotState.OrientationHistory := Right;
            else
               BotState.OrientationHistory := Center;
            end if;

            BotState.LineHistory := CalculateLineState (D => LineDetect);
         else
            Bot_Pos := Robot_Position'First;
            Line_State := Lost;
         end if;
      end if;

   end ReadLine;

   procedure DecisionMatrix (State : LineState;
                             Pos   : in out Robot_Position;
                             BaseSpeed : out Motor_Speed)
   is
   begin
      case State is
         when Lost =>

            Offline_Correction (Error => Pos);
            BaseSpeed := Fast_Speed;

            Zumo_LED.Yellow_Led (On => False);
            BotState.CorrectionCounter := 0;

         when BranchLeft =>
            Pos := Robot_Position'First;
            BaseSpeed := Slow_Speed;

            Zumo_LED.Yellow_Led (On => False);
            BotState.CorrectionCounter := 0;
         when BranchRight =>
            Pos := Robot_Position'Last;
            BaseSpeed := Slow_Speed;

            Zumo_LED.Yellow_Led (On => False);
            BotState.CorrectionCounter := 0;
         when Perp | Fork =>
            case BotState.OrientationHistory is
               when Left | Center =>
                  Pos := Robot_Position'First;
               when Right =>
                  Pos := Robot_Position'Last;
            end case;

            BaseSpeed := Slow_Speed;
            Zumo_LED.Yellow_Led (On => False);
            BotState.CorrectionCounter := 0;
         when Online =>
            if BotState.CorrectionCounter < CorrectedThreshold then
               BotState.CorrectionCounter := BotState.CorrectionCounter + 1;
               BaseSpeed := Slow_Speed;
            else
               Zumo_LED.Yellow_Led (On => True);
               BaseSpeed := Fast_Speed;
            end if;
      end case;

      BotState.LineHistory := State;
   end DecisionMatrix;

   procedure Offline_Correction (Error : in out Robot_Position)
   is
      Saturate : Integer;
   begin
      if Error = Robot_Position'First then
         Error := Error + 1;
      elsif Error = Robot_Position'Last then
         Error := Error - 1;
      else
         Saturate := BotState.ErrorHistory + 1;

         if Saturate > Robot_Position'Last then
            Error := Robot_Position'First;
         else
            Error := Saturate;
         end if;
      end if;

   end Offline_Correction;

   procedure Error_Correct (Error         : Robot_Position;
                            Current_Speed : Motor_Speed;
                            LeftSpeed     : out Motor_Speed;
                            RightSpeed    : out Motor_Speed)
   is
      Inv_Prop              : constant := 8;
      Deriv                 : constant := 2;

      SpeedDifference : Integer;

      Saturate_Speed : Integer;
   begin
      SpeedDifference := Error / Inv_Prop + Deriv *
        (Error - BotState.ErrorHistory);

      BotState.ErrorHistory := Error;

      if SpeedDifference > Motor_Speed'Last then
         SpeedDifference := Current_Speed;
      elsif SpeedDifference < Motor_Speed'First then
         SpeedDifference := Current_Speed;
      end if;

      if SpeedDifference < 0 then
         Saturate_Speed := Current_Speed + Motor_Speed (SpeedDifference);
         if Saturate_Speed > Motor_Speed'Last then
            LeftSpeed := Motor_Speed'Last;
         elsif Saturate_Speed < Motor_Speed'First then
            LeftSpeed := Motor_Speed'First;
         else
            LeftSpeed := Saturate_Speed;
         end if;
         RightSpeed := Current_Speed;
      else
         LeftSpeed := Current_Speed;

         Saturate_Speed := Current_Speed - Motor_Speed (SpeedDifference);
         if Saturate_Speed > Motor_Speed'Last then
            RightSpeed := Motor_Speed'Last;
         elsif Saturate_Speed < Motor_Speed'First then
            RightSpeed := Motor_Speed'First;
         else
            RightSpeed := Saturate_Speed;
         end if;
      end if;

   end Error_Correct;

   function CalculateLineState (D : Boolean_Array)
                               return LineState
   is
      LB : Boolean := True;
      RB : Boolean := True;

      LL : Boolean := False;
   begin

      for I in 0 .. D'Length / 2 loop
         if not D (D'First + I) then
            LB := False;
         else
            LL := True;
         end if;
      end loop;

      for I in D'Length / 2 .. D'Length - 1 loop
         if not D (D'First + I) then
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
   end CalculateLineState;

end Line_Finder;
