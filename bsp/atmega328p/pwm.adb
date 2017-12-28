pragma SPARK_Mode;

with System;
with Proc_Types; use Proc_Types;

package body Pwm is

   TCCR1A : Register
     with Address => System'To_Address (16#80#);
   TCCR1B : Register
     with Address => System'To_Address (16#81#);
   ICR1   : Double_Register
     with Address => System'To_Address (16#86#);
   OCR1A : Double_Register
     with Address => System'To_Address (16#88#);
   OCR1B : Double_Register
     with Address => System'To_Address (16#8A#);

   procedure Configure_Timers
   is
   begin
      --  Timer 1 configuration
      --  prescaler: clockI/O / 1
      --  outputs enabled
      --  phase-correct PWM
      --  top of 400
      --
      --  PWM frequency calculation
      --  16MHz / 1 (prescaler) / 2 (phase-correct) / 400 (top) = 20kHz
      TCCR1A := 2#1010_0000#;

      TCCR1B := 2#0001_0001#;

      ICR1 := 400;
   end Configure_Timers;

   procedure SetRate (Index : Pwm_Index;
                      Value : Word)
   is
   begin
      case Index is
         when Left =>
            OCR1B := Double_Register (Value);
         when Right =>
            OCR1A := Double_Register (Value);
      end case;
   end SetRate;

end Pwm;
