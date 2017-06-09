pragma SPARK_Mode;

with Sparkduino;
with Zumo_LED;
with Zumo_Pushbutton;
with Zumo_Motors;

package body Main_Loop is

   Speed : constant := 400;
   Stop : constant := 0;

   OnTime : constant := 1000;

   procedure MainLoop
   is
   begin
      Zumo_Pushbutton.WaitForButton;
      Zumo_LED.Yellow_Led (On => not Zumo_Led.State);
      Zumo_Motors.SetSpeed (LeftVelocity  => Speed,
                            RightVelocity => Speed);
      Sparkduino.SysDelay (Time => OnTime);
      Zumo_Motors.SetSpeed (LeftVelocity  => Stop,
                            RightVelocity => Stop);
   end MainLoop;

end Main_Loop;
