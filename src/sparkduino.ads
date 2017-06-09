pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;

with Types; use Types;

package Sparkduino is

   F_CPU : constant := 16_000_000;

   procedure SetPinMode (Pin  : Unsigned_Char;
                         Mode : Unsigned_Char)
     with Global => null;
   pragma Import (C, SetPinMode, "pinMode");

   procedure DigitalWrite (Pin : unsigned_char;
                           Val : Unsigned_Char)
     with Global => null;
   pragma Import (C, DigitalWrite, "digitalWrite");

   function DigitalRead (Pin : unsigned_char) return Integer
     with Global => null;
   pragma Import (C, DigitalRead, "digitalRead");

   function Millis return Unsigned_Long;
   pragma Import (C, Millis, "millis");

   function Micros return Unsigned_Long;
   pragma Import (C, Micros, "micros");

   procedure DelayMicroseconds (Time : unsigned)
     with Global => null;
   pragma Import (C, DelayMicroseconds, "delayMicroseconds");

   procedure SysDelay (Time : Unsigned_Long)
     with Global => null;
   pragma Import (C, SysDelay, "delay");

   procedure SEI;
   pragma Import (C, SEI, "sei_wrapper");

   procedure Serial_Print (Msg : String);
   pragma Import (C, Serial_Print, "Serial_Print");

end Sparkduino;
