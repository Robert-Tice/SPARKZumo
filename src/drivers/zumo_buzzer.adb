--pragma SPARK_Mode;

with Interfaces.C; use Interfaces.C;
with System;

package body Zumo_Buzzer is

--   BuzzerFinished : Boolean := True;

   procedure Enable_Timer_ISR (State : Boolean)
   is
      TIMSK2 : Unsigned_Char
        with Address => System'To_Address (16#70#);
   begin
      if State then
         TIMSK2 := 1;
      else
         TIMSK2 := 0;
      end if;
   end Enable_Timer_ISR;

   procedure Init
   is
      TCCR2A : Unsigned_Char
        with Address => System'To_Address (16#B0#);
      TCCR2B : Unsigned_Char
        with Address => System'To_Address (16#B1#);
      OCR2A : Unsigned_Char
        with Address => System'To_Address (16#B3#);
      OCR2B  : Unsigned_Char
        with Address => System'To_Address (16#B4#);
      DDRD   : Unsigned_Char
        with Address => System'To_Address (16#0A#);

   begin
      Initd := True;
      Enable_Timer_ISR (State => False);
      TCCR2A := 16#21#;
      TCCR2B := 16#0B#;
   --   OCR2A := (F_CPU / 64) / 1000;
      OCR2B := 0;
      DDRD := 4;
   end Init;


   procedure PlayFrequency (Freq : Frequency;
                            Dur : Duration;
                            Vol   : Volume)
   is
   begin
      null;

   end PlayFrequency;

   procedure PlayNote (Note : Integer;
                       Dur : Duration;
                       Vol   : Volume)
   is
   begin
      null;
   end PlayNote;

   function PlayCheck return Boolean
   is
   begin
      return False;
   end PlayCheck;

   function IsPlaying return Boolean
   is
   begin
      return False;
   end IsPlaying;

   procedure StopPlaying
   is
   begin
      null;
   end StopPlaying;




end Zumo_Buzzer;
