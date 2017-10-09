pragma SPARK_Mode;

with Sparkduino; use Sparkduino;
with Zumo_LED;
with Zumo_Motion;
with Zumo_Pushbutton;
with Zumo_Motors;
with Zumo_QTR;

with Interfaces.C; use Interfaces.C;
with Types; use Types;


package body SPARKZumo is

   Default_Speed : constant Motor_Speed := Motor_Speed'Last;
   Stop  : constant := 0;

   OnTime : constant := 1000;

   LastError : Integer := 0;

   ReadMode : constant Sensor_Read_Mode := Emitters_On;

   Offline_Offset : Integer := -1;

--     procedure Print_Cal_Vals (ReadMode : Sensor_Read_Mode)
--     is
--     begin
--        case ReadMode is
--           when Emitters_On =>
--              Serial_Print ("Emitters on");
--              for I in Zumo_QTR.Cal_Vals_On'Range loop
--                 Serial_Print_Calibration (Index => I,
--                                           Min   => Zumo_QTR.Cal_Vals_On (I).Min,
--                                           Max   => Zumo_QTR.Cal_Vals_On (I).Max);
--              end loop;
--           when Emitters_Off =>
--              Serial_Print ("Emitters off");
--              for I in Zumo_QTR.Cal_Vals_Off'Range loop
--                 Serial_Print_Calibration (Index => I,
--                                           Min   => Zumo_QTR.Cal_Vals_Off (I).Min,
--                                           Max   => Zumo_QTR.Cal_Vals_Off (I).Max);
--              end loop;
--           when Emitters_On_Off =>
--              Print_Cal_Vals (ReadMode => Emitters_On);
--              Print_Cal_Vals (ReadMode => Emitters_Off);
--        end case;
--     end Print_Cal_Vals;


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
               Zumo_Motors.SetSpeed (LeftVelocity  => -90,
                                     RightVelocity => 90);
            when 81 =>
               Zumo_Motors.SetSpeed (LeftVelocity  => 90,
                                     RightVelocity => -90);
            when others =>
               null;
         end case;

         Zumo_QTR.Calibrate (ReadMode => ReadMode);
         SysDelay (20);
      end loop;

      Zumo_Motors.SetSpeed (LeftVelocity  => Stop,
                            RightVelocity => Stop);

 --     Print_Cal_Vals (ReadMode);


      Zumo_LED.Yellow_Led (On => True);
      Zumo_Pushbutton.WaitForButton;
   end Setup;

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
      Zumo_QTR.ReadLine (Sensor_Values => QTR,
                         ReadMode      => ReadMode,
                         WhiteLine     => True,
                         On_Line => On_Line,
                         Bot_Pos       => Position);

      Error := Position - Integer (((QTR'Length - 1) * Sensor_Value'Last) / 2);

      if not On_Line then
         Offline_Offset := Offline_Offset + Offline_Inc;
         if Error < 0 then
            Error := Error + Offline_Offset;
         else
            Error := Error - Offline_Offset;
         end if;
      else
         Offline_Offset := -1;
      end if;

 --     Serial_Print_Short (Msg => "Error: ",
 --                         Val => Short (Error));

      SpeedDifference := Error / Inv_Prop + Deriv * (Error - LastError);

 --     Serial_Print_Short (Msg => "Speed Diff: ",
 --                         Val => Short (SpeedDifference));

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

--     procedure PrintQTR
--     is
--        QTR : Sensor_Array;
--     begin
--        Zumo_QTR.ReadCalibrated (Sensor_Values => QTR,
--                                 ReadMode      => ReadMode);
--
--        for I in QTR'Range loop
--           Serial_Print_Short (Msg => I'Img & ": ",
--                               Val => Short (QTR (I)));
--        end loop;
--
--     end PrintQTR;

   procedure WorkLoop
   is
   begin
--      Zumo_Pushbutton.WaitForButton;

      LineFinder;

   end WorkLoop;


end SPARKZumo;
