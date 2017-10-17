with Sparkduino; use Sparkduino;
with Zumo_LED;
with Zumo_Motion;
with Zumo_Pushbutton;
with Zumo_Motors;
with Zumo_QTR;

with Line_Finder;

package body SPARKZumo is

   Stop          : constant := 0;

   procedure Calibration_Sequence
   is
   begin
      for I in 1 .. 4 loop
         case I is
            when 1 | 3 =>
               Zumo_Motors.SetSpeed (LeftVelocity  => Motor_Speed'First / 2,
                                     RightVelocity => Motor_Speed'Last / 2);
            when others =>
               Zumo_Motors.SetSpeed (LeftVelocity  => Motor_Speed'Last / 2,
                                     RightVelocity => Motor_Speed'First / 2);
         end case;

         for J in 1 .. 80 loop
            Zumo_QTR.Calibrate (ReadMode => ReadMode);
            SysDelay (20);
         end loop;

      end loop;

      Zumo_Motors.SetSpeed (LeftVelocity  => Stop,
                            RightVelocity => Stop);
   end Calibration_Sequence;

   procedure Inits
   is
   begin
      Zumo_LED.Init;
      Zumo_Pushbutton.Init;
      Zumo_Motors.Init;

      Zumo_QTR.Init;

      Zumo_Motion.Init;

      --    Initd := True;
   end Inits;

   procedure Setup
   is
   begin
      Inits;
      Zumo_LED.Yellow_Led (On => True);
      Zumo_Pushbutton.WaitForButton;
      Zumo_LED.Yellow_Led (On => False);

      Calibration_Sequence;

      Zumo_LED.Yellow_Led (On => True);
      Zumo_Pushbutton.WaitForButton;
   end Setup;

   procedure WorkLoop
   is
   begin

      Line_Finder.LineFinder (ReadMode => ReadMode);

   end WorkLoop;

end SPARKZumo;
