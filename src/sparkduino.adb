pragma SPARK_Mode;

with System;
with Interfaces.C; use Interfaces.C;

package body Sparkduino is

   procedure Arduino_Serial_Print (Msg : System.Address);
   pragma Import (C, Arduino_Serial_Print, "Serial_Print");


   procedure Serial_Print (Msg : String)
     with SPARK_Mode => Off
   is
      Msg_Null : char_array (Size_T (Msg'First) .. Size_T (Msg'Last + 1));
   begin
      for I in Msg'Range loop
         Msg_Null (Size_T (I)) := Char (Msg (I));
      end loop;
      Msg_Null (Msg_Null'Last) := Nul;
      Arduino_Serial_Print (Msg => Msg_Null'Address);
   end Serial_Print;



end Sparkduino;
