pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;

with Sparkduino; use Sparkduino;

package body SPARKZumo is

   Stop          : constant := 0;

   Sample_Rate : constant := 500;

   procedure Calibration_Sequence
   is
   begin
      for I in 1 .. 4 loop
         case I is
            when 1 | 3 =>
               Zumo_Motors.SetSpeed (LeftVelocity  => Motor_Speed'First / 3,
                                     RightVelocity => Motor_Speed'Last / 3);
            when others =>
               Zumo_Motors.SetSpeed (LeftVelocity  => Motor_Speed'Last / 3,
                                     RightVelocity => Motor_Speed'First / 3);
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

      Initd := True;
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
      Start, Length : unsigned_long;
   begin
      Start := Millis;

      Line_Finder.LineFinder (ReadMode => ReadMode);

      Length := Millis - Start;

      if Length < Sample_Rate then
         DelayMicroseconds (Time => unsigned (Sample_Rate - Length) * 100);
      end if;

   end WorkLoop;

   procedure Exception_Handler
   is
   begin
      Zumo_Motors.SetSpeed (LeftVelocity  => Stop,
                            RightVelocity => Stop);

      loop
         Zumo_LED.Yellow_Led (On => True);
         SysDelay (Time => 500);
         Zumo_LED.Yellow_Led (On => False);
         SysDelay (Time => 500);
      end loop;
   end Exception_Handler;

end SPARKZumo;
