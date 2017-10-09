pragma SPARK_Mode;

with Types; use Types;
with System;

package ATmega328P is

   F_CPU : constant := 16_000_000;

   TCCR1A : Byte
     with Address => System'To_Address (16#80#);
   TCCR1B : Byte
     with Address => System'To_Address (16#81#);
   ICR1   : Word
     with Address => System'To_Address (16#86#);
   OCR1A : Word
     with Address => System'To_Address (16#88#);
   OCR1B : Word
     with Address => System'To_Address (16#8A#);

end ATmega328P;
