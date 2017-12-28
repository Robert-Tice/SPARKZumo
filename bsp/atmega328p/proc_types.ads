pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;

package Proc_Types is

   type Register is mod 2 ** 8
     with Size => 8;

   type Double_Register is mod 2 ** 16
     with Size => 16;

   subtype Pin_Type is unsigned_char;

end Proc_Types;
