pragma SPARK_Mode;

with Sparkduino; use Sparkduino;
with Zumo_LED;
with Zumo_Pushbutton;
with Zumo_Motors;
with Zumo_QTR;

with Interfaces.C; use Interfaces.C;


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
   begin
      Zumo_Pushbutton.WaitForButton;
      Zumo_LED.Yellow_Led (On => not Zumo_Led.State);

      Zumo_Motors.SetSpeed (LeftVelocity  => Speed,
                            RightVelocity => Speed);
      Sparkduino.SysDelay (Time => OnTime);
      Zumo_Motors.SetSpeed (LeftVelocity  => Stop,
                            RightVelocity => Stop);
   end WorkLoop;


end SPARKZumo;
