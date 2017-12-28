pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;

package Proc_Types is

   type Register is mod 2 ** 32
     with Size => 32;

   subtype Pin_Type is unsigned;

end Proc_Types;
