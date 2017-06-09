pragma SPARK_Mode;


package body Sparkduino is

   procedure Arduino_Serial_Print (Msg : Char_Array);
   pragma Import (C, Arduino_Serial_Print, "Serial_Print");

   procedure Serial_Print (Msg : String)
   is
      Raw_Msg : Char_Array (Size_T(Msg'First) .. Size_T(Msg'Last + 1));
   begin
      for I in Msg'Range loop
         Raw_Msg (Size_T(I)) := Char(Msg (I));
      end loop;

      Raw_Msg (Raw_Msg'Last) := Nul;

      Arduino_Serial_Print (Msg => Raw_Msg);
   end Serial_Print;



end Sparkduino;
