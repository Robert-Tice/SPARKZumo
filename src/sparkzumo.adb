with Sparkduino; use Sparkduino;
with Zumo_LED;
with Zumo_Motion;
with Zumo_Pushbutton;
with Zumo_Motors;
with Zumo_QTR;

with Interfaces.C; use Interfaces.C;

package body SPARKZumo is

   Default_Speed : constant Motor_Speed := Motor_Speed'Last;
   Stop  : constant := 0;

   LastError : Integer := 0;

   ReadMode : constant Sensor_Read_Mode := Emitters_On;

   Offline_Offset : Natural := 0;

   LastValue      : Integer := 0;

   procedure Setup
   is
   begin
      Zumo_LED.Init;
      Zumo_Pushbutton.Init;
      Zumo_Motors.Init;

      Zumo_QTR.Init;

      Zumo_Motion.Init;

      Zumo_LED.Yellow_Led (On => True);
      Zumo_Pushbutton.WaitForButton;
      Zumo_LED.Yellow_Led (On => False);

      for I in 1 .. 240 loop
         case I is
            when 1 | 161 =>
               Zumo_Motors.SetSpeed (LeftVelocity  => Motor_Speed'First / 2,
                                     RightVelocity => Motor_Speed'Last / 2);
            when 81 =>
               Zumo_Motors.SetSpeed (LeftVelocity  => Motor_Speed'Last / 2,
                                     RightVelocity => Motor_Speed'First / 2);
            when others =>
               null;
         end case;

         Zumo_QTR.Calibrate (ReadMode => ReadMode);
         SysDelay (20);
      end loop;

      Zumo_Motors.SetSpeed (LeftVelocity  => Stop,
                            RightVelocity => Stop);

      Zumo_LED.Yellow_Led (On => True);
      Zumo_Pushbutton.WaitForButton;
   end Setup;

   procedure ReadLine (Sensor_Values : out Sensor_Array;
                       ReadMode      : Sensor_Read_Mode;
                       WhiteLine     : Boolean;
                       On_Line       : out Boolean;
                       Bot_Pos       : out Natural)
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
            Bot_Pos := 0;
            return;
         else
            Bot_Pos := Integer ((Sensor_Values'Length - 1) *
                                  Sensor_Value'Last);
            return;
         end if;
      end if;

      LastValue := Integer (Avg / Sum);

      Bot_Pos := Natural (LastValue);

   end ReadLine;

   procedure LineFinder
   is
      Position : Natural;
      QTR      : Sensor_Array;

      Error    : Integer;

      SpeedDifference : Integer;

      LeftSpeed, RightSpeed : Motor_Speed := Default_Speed;
      Inv_Prop              : constant := 8;
      Deriv                 : constant := 2;
      On_Line               : Boolean;

      Offline_Inc           : constant := 1;
   begin
      ReadLine (Sensor_Values => QTR,
                ReadMode      => ReadMode,
                WhiteLine     => True,
                On_Line       => On_Line,
                Bot_Pos       => Position);

      Error := Position - Integer (((QTR'Length - 1) * Sensor_Value'Last) / 2);

      if not On_Line then
         if Error < 0 then
            Error := Error + Offline_Offset;
         else
            Error := Error - Offline_Offset;
         end if;

         Offline_Offset := Offline_Offset + Offline_Inc;
      else
         Offline_Offset := Natural'First;
      end if;

      SpeedDifference := Error / Inv_Prop + Deriv * (Error - LastError);

      LastError := Error;

      if SpeedDifference > Motor_Speed'Last then
         SpeedDifference := Default_Speed;
      elsif SpeedDifference < Motor_Speed'First then
         SpeedDifference := Default_Speed;
      end if;

      if SpeedDifference < 0 then
         LeftSpeed := Default_Speed + Motor_Speed (SpeedDifference);
      else
         RightSpeed := Default_Speed - Motor_Speed (SpeedDifference);
      end if;

      Zumo_Motors.SetSpeed (LeftVelocity  => LeftSpeed,
                            RightVelocity => RightSpeed);
   end LineFinder;

   procedure WorkLoop
   is
   begin

      LineFinder;

   end WorkLoop;

end SPARKZumo;
