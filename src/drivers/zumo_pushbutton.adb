pragma SPARK_Mode;

with Sparkduino; use Sparkduino;
with Types; use Types;

package body Zumo_Pushbutton is

   Zumo_Button : constant := 12;
   Zumo_Button_Pullup : constant PinMode := INPUT_PULLUP;
   Zumo_Button_Default_Pinval : constant DigPinValue := HIGH;

   procedure Init
   is
   begin

      Initd := True;
      SetPinMode (Pin  => Zumo_Button,
                  Mode => PinMode'Pos (Zumo_Button_Pullup));

      DelayMicroseconds (Time => 5);

   end Init;

   function IsPressed return Boolean
   is
   begin
      return DigitalRead (Pin => Zumo_Button) /=
        DigPinValue'Pos (Zumo_Button_Default_Pinval);
   end IsPressed;

   procedure WaitForPress
   is
   begin
      loop
         while not IsPressed loop
            null;
         end loop;
         SysDelay (Time => 10);
         exit when IsPressed;
      end loop;
   end WaitForPress;

   procedure WaitForRelease
   is
   begin
      loop
         while IsPressed loop
            null;
         end loop;
         SysDelay (Time => 10);
         exit when not IsPressed;
      end loop;
   end WaitForRelease;

   procedure WaitForButton
   is
   begin
      WaitForPress;
      WaitForRelease;
   end WaitForButton;

end Zumo_Pushbutton;
