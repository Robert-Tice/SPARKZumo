pragma SPARK_Mode;

with Zumo_LED;
with Zumo_Pushbutton;
with Zumo_Motors;

package body Main_Setup is


   procedure Setup_Placeholder
   is
   begin
      Zumo_LED.Init;
      Zumo_Pushbutton.Init;
      Zumo_Motors.Init;
   end Setup_PlaceHolder;

end Main_Setup;
