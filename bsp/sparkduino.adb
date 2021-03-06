pragma SPARK_Mode;

with System;

package body Sparkduino is

   procedure Arduino_Serial_Print (Msg : System.Address);
   pragma Import (C, Arduino_Serial_Print, "Serial_Print");

   procedure Arduino_Serial_Print_Byte (Msg : System.Address;
                                        Val : Byte);
   pragma Import (C, Arduino_Serial_Print_Byte, "Serial_Print_Byte");

   procedure Arduino_Serial_Print_Short (Msg : System.Address;
                                         Val : short);
   pragma Import (C, Arduino_Serial_Print_Short, "Serial_Print_Short");

   procedure Arduino_Serial_Print_Float (Msg : System.Address;
                                         Val : Float);
   pragma Import (C, Arduino_Serial_Print_Float, "Serial_Print_Float");

   procedure Serial_Print (Msg : String)
     with SPARK_Mode => Off
   is
      Msg_Null : char_array (size_t (Msg'First) .. size_t (Msg'Last + 1));
   begin
      for I in Msg'Range loop
         Msg_Null (size_t (I)) := char (Msg (I));
      end loop;
      Msg_Null (Msg_Null'Last) := nul;
      Arduino_Serial_Print (Msg => Msg_Null'Address);
   end Serial_Print;

   procedure Serial_Print_Byte (Msg : String;
                                Val : Byte)
     with SPARK_Mode => OFf
   is
      Msg_Null : char_array (size_t (Msg'First) .. size_t (Msg'Last + 1));
   begin
      for I in Msg'Range loop
         Msg_Null (size_t (I)) := char (Msg (I));
      end loop;
      Msg_Null (Msg_Null'Last) := nul;
      Arduino_Serial_Print_Byte (Msg => Msg_Null'Address,
                                 Val => Val);
   end Serial_Print_Byte;

   procedure Serial_Print_Short (Msg : String;
                                 Val : short)
     with SPARK_Mode => OFf
   is
      Msg_Null : char_array (size_t (Msg'First) .. size_t (Msg'Last + 1));
   begin
      for I in Msg'Range loop
         Msg_Null (size_t (I)) := char (Msg (I));
      end loop;
      Msg_Null (Msg_Null'Last) := nul;
      Arduino_Serial_Print_Short (Msg => Msg_Null'Address,
                                  Val => Val);
   end Serial_Print_Short;

   procedure Serial_Print_Float (Msg : String;
                                      Val : Float)
     with SPARK_Mode => OFf
   is
      Msg_Null : char_array (size_t (Msg'First) .. size_t (Msg'Last + 1));
   begin
      for I in Msg'Range loop
         Msg_Null (size_t (I)) := char (Msg (I));
      end loop;
      Msg_Null (Msg_Null'Last) := nul;
      Arduino_Serial_Print_Float (Msg => Msg_Null'Address,
                                  Val => Val);
   end Serial_Print_Float;

end Sparkduino;
