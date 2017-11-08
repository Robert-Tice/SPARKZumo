pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;

--  with Geo_Filter;
with Sparkduino; use Sparkduino;

package body Line_Finder is

   Noise_Threshold : constant := Timeout / 10;
   Line_Threshold  : constant := Timeout / 2;

   Fast_Speed      : constant := Motor_Speed'Last - 150;
   Slow_Speed      : constant := Fast_Speed;

   procedure LineFinder (ReadMode : Sensor_Read_Mode)
   is
      Error    : Robot_Position;
      Line_State : LineState;
   begin
      ReadLine (WhiteLine  => True,
                ReadMode   => ReadMode,
                Line_State => Line_State,
                Bot_Pos    => Error);

--      Geo_Filter.FilterState (State => Line_State);

      DecisionMatrix (State     => Line_State,
                      Pos       => Error);
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
      LineDetect : Byte := 0;
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
            LineDetect := LineDetect + 2 ** (I - Sensor_Values'First);
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

            Line_State := LineStateLookup (Integer (LineDetect));
         else
            Bot_Pos := Robot_Position'First;
            Line_State := Lost;
         end if;
      end if;

   end ReadLine;

   procedure DecisionMatrix (State : LineState;
                             Pos   : Robot_Position)
   is
      LeftSpeed : Motor_Speed;
      RightSpeed : Motor_Speed;
   begin
      case State is
         when BranchLeft =>
            Zumo_LED.Yellow_Led (On => False);

            Zumo_Motors.SetSpeed (LeftVelocity  => 0,
                                  RightVelocity => Slow_Speed);
         when BranchRight =>
            Zumo_LED.Yellow_Led (On => False);

            Zumo_Motors.SetSpeed (LeftVelocity  => Slow_Speed,
                                  RightVelocity => 0);
         when Perp | Fork =>
            case BotState.OrientationHistory is
               when Left | Center =>
                  LeftSpeed := 0;
                  RightSpeed := Slow_Speed;
               when Right =>
                  LeftSpeed := Slow_Speed;
                  RightSpeed := 0;
            end case;

            Zumo_LED.Yellow_Led (On => False);

            Zumo_Motors.SetSpeed (LeftVelocity  => LeftSpeed,
                                  RightVelocity => RightSpeed);
         when Lost =>
            case BotState.OrientationHistory is
               when Left | Center =>
                  LeftSpeed := (-1) * Fast_Speed;
                  RightSpeed := Fast_Speed;
               when Right =>
                  LeftSpeed := Fast_Speed;
                  RightSpeed := (-1) * Fast_Speed;
            end case;

            Zumo_LED.Yellow_Led (On => False);

            Zumo_Motors.SetSpeed (LeftVelocity  => LeftSpeed,
                                  RightVelocity => RightSpeed);
         when Online =>
            Zumo_LED.Yellow_Led (On => True);

            Error_Correct (Error         => Pos,
                           Current_Speed => Fast_Speed,
                           LeftSpeed     => LeftSpeed,
                           RightSpeed    => RightSpeed);

            Zumo_Motors.SetSpeed (LeftVelocity  => LeftSpeed,
                                  RightVelocity => RightSpeed);
         when Unknown =>
            null;
      end case;

      if State /= BotState.LineHistory then
         Serial_Print (Msg => LineStateStr (State));
      end if;

      BotState.LineHistory := State;
   end DecisionMatrix;

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

end Line_Finder;
