pragma SPARK_Mode;

--  @summary
--  Controls the little yellow LED on the robot labeled LED 13
--
--  @description
--  Use this interface to turn on and off the LED 13 located near the back
--    of the robot on the right side
package Zumo_LED is

   Initd : Boolean := False;

   --  Initialization sequence. Muxes pins and whatnot
   procedure Init
     with Global => (In_Out => (Initd)),
     Pre => not Initd,
     Post => Initd;

   --  Turns on and off the LED
   --  @param On True to turn on. False to turn off
   procedure Yellow_Led (On : Boolean)
     with Pre => Initd;

end Zumo_LED;
