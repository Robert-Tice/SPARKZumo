pragma SPARK_Mode;

with ATmega328P; use ATmega328P;
with Interfaces.C; use Interfaces.C;
with Sparkduino; use Sparkduino;
with System;

package body Zumo_Motors is


   FlipLeft : Boolean := False;
   FlipRight : Boolean := False;


   PWM_L : constant := 10;
   PWM_R : constant := 9;
   DIR_L : constant := 8;
   DIR_R : constant := 7;

   procedure Init
   is
      TCCR1A : Unsigned_Char
     with Address => System'To_Address (16#80#);

   TCCR1B : Unsigned_Char
     with Address => System'To_Address (16#81#);

   ICR1 : Unsigned_Short
     with Address => System'To_Address (16#86#);
   begin
      Initd := True;
      SetPinMode (Pin  => PWM_L,
                  Mode => PinMode'Pos(OUTPUT));
      SetPinMode (Pin  => PWM_R,
                  Mode => PinMode'Pos(OUTPUT));
      SetPinMode (Pin  => DIR_L,
                  Mode => PinMode'Pos(OUTPUT));
      SetPinMode (Pin  => DIR_R,
                  Mode => PinMode'Pos (OUTPUT));

      TCCR1A := 2#10100000#;

      TCCR1B := 2#00010001#;

      ICR1 := 400;
   end Init;

   procedure FlipLeftMotor (Flip : Boolean)
   is
   begin
      FlipLeft := Flip;
   end FlipLeftMotor;

   procedure FlipRightMotor (Flip : Boolean)
   is
   begin
      FlipRight := Flip;
   end FlipRightMotor;

   procedure SetLeftSpeed (Velocity : Motor_Speed)
   is
      Rev : Boolean := False;
      Speed : Motor_Speed := Velocity;
      OCR1B : Unsigned_Short
     with Address => System'To_Address (16#8A#);
   begin
      if Speed < 0 then
         Rev := True;
         Speed := abs Speed;
      end if;

      OCR1B := Unsigned_Short(Speed);

      if Rev xor FlipLeft then
         DigitalWrite (Pin => DIR_L,
                       Val => DigPinValue'Pos(HIGH));
      else
         DigitalWrite (Pin => DIR_L,
                       Val => DigPinValue'Pos(LOW));
      end if;

   end SetLeftSpeed;

   procedure SetRightSpeed (Velocity : Motor_Speed)
   is
      Rev : Boolean := False;
      Speed : Motor_Speed := Velocity;
         OCR1A : Unsigned_Short
     with Address => System'To_Address (16#88#);
   begin
      if Speed < 0 then
         Rev := True;
         Speed := abs Speed;
      end if;

      OCR1A := Unsigned_Short(Speed);

      if Rev xor FlipRight then
         DigitalWrite (Pin => DIR_R,
                       Val => DigPinValue'Pos(HIGH));
      else
         DigitalWrite (Pin => DIR_R,
                       Val => DigPinValue'Pos(LOW));
      end if;

   end SetRightSpeed;

   procedure SetSpeed (LeftVelocity : Motor_Speed;
                       RightVelocity : Motor_Speed)
   is
   begin
      SetLeftSpeed (Velocity => LeftVelocity);
      SetRightSpeed (Velocity => RightVelocity);
   end SetSPeed;

end Zumo_Motors;
