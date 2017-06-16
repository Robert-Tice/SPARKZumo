pragma SPARK_Mode;

with System;

package body Sparkduino is

   procedure Arduino_Serial_Print (Msg : System.Address);
   pragma Import (C, Arduino_Serial_Print, "Serial_Print");


   procedure Serial_Print (Msg : String)
     with SPARK_Mode => Off
   is
   begin
      Arduino_Serial_Print (Msg => Msg'Address);
   end Serial_Print;



end Sparkduino;
