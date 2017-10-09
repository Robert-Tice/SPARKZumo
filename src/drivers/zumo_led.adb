pragma SPARK_Mode;

with Sparkduino; use Sparkduino;
with Types; use Types;

package body Zumo_LED is

   YellowLEDPin : constant := 13;

   procedure Init
   is
   begin
      Initd := True;
      SetPinMode (Pin  => YellowLEDPin,
                  Mode => PinMode'Pos (OUTPUT));

   end Init;

   procedure Yellow_Led (On : Boolean)
   is
   begin
      if On then
         DigitalWrite (Pin => YellowLEDPin,
                       Val => DigPinValue'Pos (HIGH));
      else
         DigitalWrite (Pin => YellowLEDPin,
                       Val => DigPinValue'Pos (LOW));
      end if;
      State := On;
   end Yellow_Led;

end Zumo_LED;
