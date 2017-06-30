pragma SPARK_Mode;

with Sparkduino; use Sparkduino;
with Zumo_LED;
with Zumo_LSM303;
with Zumo_Pushbutton;
with Zumo_Motors;
with Zumo_QTR;

with Interfaces.C; use Interfaces.C;
with Types; use Types;


package body SPARKZumo is

   Speed : constant := 400;
   Stop : constant := 0;

   OnTime : constant := 1000;

   procedure Setup
     with SPARK_Mode => Off
   is
      --      StartTime : Unsigned_Long;
   begin
      Zumo_LED.Init;
      Zumo_Pushbutton.Init;
      Zumo_Motors.Init;

      Zumo_QTR.Init;

      Zumo_LSM303.Init;

      Zumo_LED.Yellow_Led (On => True);
--        StartTime := Millis;
--        while (Millis - StartTime < 10000) loop
--           Zumo_QTR.Calibrate;
--        end loop;
--        Zumo_LED.Yellow_Led (On => False);
--
--        Serial_Print ("Cal Data");
--        for I in Zumo_QTR.Cal_Vals_On'Range loop
--           Serial_Print (I'Img &
--                           ": Min: " &
--                           Zumo_QTR.Cal_Vals_On (I).Min'Img &
--                           "    Max: " &
--                           Zumo_QTR.Cal_Vals_On (I).Max'Img &
--                           "\n");
--      end loop;

   end Setup;

   procedure WorkLoop
   is
      Temp     : Short;
      Mag_Data : Axis_Data;
      Acc_Data : Axis_Data;

      M_Status, A_Status : Byte;
   begin

      Zumo_Pushbutton.WaitForButton;
      Zumo_LED.Yellow_Led (On => not Zumo_Led.State);

      --        Serial_Print ("Motors Start");
      --        Zumo_Motors.SetSpeed (LeftVelocity  => Speed,
      --                              RightVelocity => Speed);
      --        Sparkduino.SysDelay (Time => OnTime);
      --        Zumo_Motors.SetSpeed (LeftVelocity  => Stop,
      --                              RightVelocity => Stop);
      --        Serial_Print ("Motors stop");
      Temp := Zumo_LSM303.Read_Temp;
      Serial_Print_Short (Msg => "Temp",
                          Val => Temp);

      M_Status := Zumo_LSM303.Read_M_Status;
      Serial_Print_Byte (Msg => "M Status",
                           Val => M_Status);
      A_Status := Zumo_LSM303.Read_A_Status;
      Serial_Print_Byte (Msg => "A Status",
                         Val => A_Status);

      Zumo_LSM303.Read_Mag (Data => Mag_Data);
      Zumo_LSM303.Read_Acc (Data => Acc_Data);
      Serial_Print ("Mag: " & Mag_Data (1)'Img & " " &
                      Mag_Data (2)'Img & " " &
                      Mag_Data (3)'Img);

      Serial_Print ("Acc: " & Acc_Data (1)'Img & " " &
                      Acc_Data (2)'Img & " " &
                      Acc_Data (3)'Img);

   end WorkLoop;


end SPARKZumo;
