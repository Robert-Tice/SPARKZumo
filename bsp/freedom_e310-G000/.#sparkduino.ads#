pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;
with Proc_Types; use Proc_Types;
with Types; use Types;

package Sparkduino is

   procedure SetPinMode (Pin  : Pin_Type;
                         Mode : unsigned)
     with Global => null;
   pragma Import (C, SetPinMode, "pinMode");

   procedure DigitalWrite (Pin : Pin_Type;
                           Val : unsigned)
     with Global => null;
   pragma Import (C, DigitalWrite, "digitalWrite");

   function DigitalRead (Pin : Pin_Type) return Integer
     with Global => null;
   pragma Import (C, DigitalRead, "digitalRead");

   procedure AnalogWrite (Pin : Pin_Type;
                          Val : unsigned)
     with Global => null;
   pragma Import (C, AnalogWrite, "analogWrite");

   procedure AnalogWriteResolution (Resolution : Integer)
     with Global => null;
   pragma Import (C, AnalogWriteResolution, "analogWriteResolution");

   function Millis return unsigned_long
     with Global => null;
   pragma Import (C, Millis, "millis");

   function Micros return unsigned_long
     with Global => null;
   pragma Import (C, Micros, "micros");

   procedure DelayMicroseconds (Time : unsigned)
     with Global => null;
   pragma Import (C, DelayMicroseconds, "delayMicroseconds");

   procedure SysDelay (Time : unsigned_long)
     with Global => null;
   pragma Import (C, SysDelay, "delay");

   procedure Serial_Print (Msg : String)
     with SPARK_Mode => Off;

   procedure Serial_Print_Byte (Msg : String;
                                Val : Byte)
     with SPARK_Mode => Off;

   procedure Serial_Print_Short (Msg : String;
                                 Val : short)
     with SPARK_Mode => Off;

   procedure Serial_Print_Float (Msg : String;
                                 Val : Float)
     with SPARK_Mode => Off;

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
