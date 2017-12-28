pragma SPARK_Mode;

with Types; use Types;

package Pwm
is
   type Pwm_Index is (Left, Right);

   procedure Configure_Timers;

   procedure SetRate (Index : Pwm_Index;
                      Value : Word);

end Pwm;
