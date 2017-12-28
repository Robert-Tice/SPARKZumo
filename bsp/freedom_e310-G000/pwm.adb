pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;
with Sparkduino; use Sparkduino;

package body Pwm
is

   Pwm_Resolution : constant := 8;

   procedure Configure_Timers
   is
   begin
      null;
   end Configure_Timers;

   procedure SetRate (Index : Pwm_Index;
                      Value : Word)
   is
      Scaled : unsigned;
   begin
      Scaled := (unsigned (Value) * ((2 ** Pwm_Resolution) - 1)) / PWM_Max;
      case Index is
         when Left =>
            AnalogWrite (Pin => 10,
                         Val => Scaled);
         when Right =>
            AnalogWrite (Pin => 9,
                         Val => Scaled);
      end case;
   end SetRate;

end Pwm;
