pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;

with Types; use Types;

--  @summary
--  This package exposes many Arduino runtime routines to Ada
--
--  @description
--  This package imports all of the necessary Arduino runtime library calls
--    that are needed.
--
package Sparkduino is

   --  Configures the specified pin to behave either as an input or an output
   --  @param Pin the number of the pin whose mode you wish to set
   --  @param Mode use PinMode'Pos (io_mode) where io_mode is of type PinMode
   --    see Types package for more info
   procedure SetPinMode (Pin  : unsigned_char;
                         Mode : unsigned_char)
     with Global => null;
   pragma Import (C, SetPinMode, "pinMode");

   --  Write a HIGH or a LOW value to a digital pin.
   --  @param Pin the pin number
   --  @param Val use DigPinValue'Pos (state) where state is of type
   --    DigPinValue see Types package for more info
   procedure DigitalWrite (Pin : unsigned_char;
                           Val : unsigned_char)
     with Global => null;
   pragma Import (C, DigitalWrite, "digitalWrite");

   --  Reads the value from a specified digital pin, either HIGH or LOW.
   --  @param Pin the number of the digital pin you want to read
   --  @return an Integer that maps to HIGH or LOW with DigPinValue'Pos
   function DigitalRead (Pin : unsigned_char) return Integer
     with Global => null;
   pragma Import (C, DigitalRead, "digitalRead");

   --  Returns the number of milliseconds since the Arduino board began running
   --    the current program. This number will overflow (go back to zero),
   --    after approximately 50 days.
   --  @return Number of milliseconds since the program started (unsigned long)
   function Millis return unsigned_long
     with Global => null;
   pragma Import (C, Millis, "millis");

   --  Returns the number of microseconds since the Arduino board began
   --    running the current program. This number will overflow
   --    (go back to zero), after approximately 70 minutes. On 16 MHz Arduino
   --    boards (e.g. Duemilanove and Nano), this function has a resolution of
   --    four microseconds (i.e. the value returned is always a multiple of
   --    four). On 8 MHz Arduino boards (e.g. the LilyPad), this function has
   --    a resolution of eight microseconds.
   --  @return Returns the number of microseconds since the Arduino board began
   --    running the current program. (unsigned long)
   function Micros return unsigned_long
     with Global => null;
   pragma Import (C, Micros, "micros");

   --  Pauses the program for the amount of time
   --  @param Time the number of microseconds to pause
   procedure DelayMicroseconds (Time : unsigned)
     with Global => null;
   pragma Import (C, DelayMicroseconds, "delayMicroseconds");

   --  Pauses the program for the amount of time (in milliseconds)
   --  @param Time the number of milliseconds to pause
   procedure SysDelay (Time : unsigned_long)
     with Global => null;
   pragma Import (C, SysDelay, "delay");

   --  AVR specific call which temporarily disables interrupts.
   procedure SEI;
   pragma Import (C, SEI, "sei_wrapper");

   --  Print a string to the serial console
   --  @param Msg the string to print
   procedure Serial_Print (Msg : String)
     with SPARK_Mode => Off;

   --  Print a byte to the serial console
   --  @param Msg the string to prepend
   --  @param Val the byte to print
   procedure Serial_Print_Byte (Msg : String;
                                Val : Byte)
     with SPARK_Mode => Off;

   --  Print a short to the serial console
   --  @param Msg the string to prepend
   --  @param Val the short to print
   procedure Serial_Print_Short (Msg : String;
                                 Val : short)
     with SPARK_Mode => Off;

   --  Print a float to the serial console
   --  @param Msg the string to prepend
   --  @param Val the float to print
   procedure Serial_Print_Float (Msg : String;
                                 Val : Float)
     with SPARK_Mode => Off;

   --  Print the format calibration data to the serial console
   --  @param Index the specific sensor calibration data to print
   --  @param Min the min sensor value in the calibration record
   --  @param Max the max sensor value in the calibration record
   procedure Serial_Print_Calibration (Index : Integer;
                                       Min   : Sensor_Value;
                                       Max   : Sensor_Value);
   pragma Import (C, Serial_Print_Calibration, "Serial_Print_Calibration");

   --  analog pin mappings
   A0 : constant := 14;
   A1 : constant := 15;
   A2 : constant := 16;
   A3 : constant := 17;
   A4 : constant := 18;
   A5 : constant := 19;
   A6 : constant := 20;
   A7 : constant := 21;

end Sparkduino;
