pragma SPARK_Mode;

with Zumo_LED;
with Zumo_Pushbutton;
with Zumo_Motors;
with Zumo_QTR;

with Sparkduino; use Sparkduino;

with Interfaces.C; use Interfaces.C;

package body Main_Setup is


   procedure Setup
   is
      StartTime : Unsigned_Long;
   begin
      Zumo_LED.Init;
      Zumo_Pushbutton.Init;
      Zumo_Motors.Init;

      Zumo_QTR.Init;

      Zumo_LED.Yellow_Led (On => True);
      StartTime := Millis;
      while (Millis - StartTime < 10000) loop
         Zumo_QTR.Calibrate;
      end loop;
      Zumo_LED.Yellow_Led (On => False);

      Serial_Print ("Cal Data");
      for I in Zumo_QTR.Cal_Vals_On'Range loop
         Serial_Print (I'Img &
                         ": Min: " &
                         Zumo_QTR.Cal_Vals_On (I).Min'Img &
                         "    Max: " &
                         Zumo_QTR.Cal_Vals_On (I).Max'Img &
                         "\n");
      end loop;

   end Setup;

end Main_Setup;
