pragma SPARK_Mode;

with Types; use Types;

--  @summary
--  PWM interface
--
--  @description
--  This package gives an interface to the PWM hardware
package Pwm
is
--  PWM Left Motor or PWM Right Motor
--  @value Left left motor
--  @value Right right motor
   type Pwm_Index is (Left, Right);

   --  Configure the PWM timers
   procedure Configure_Timers;

   --  Set the PWM rate
   --  @param Index left or right motor
   --  @param Value the PWM value to set
   procedure SetRate (Index : Pwm_Index;
                      Value : Word);

end Pwm;
