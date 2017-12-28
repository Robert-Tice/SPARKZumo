pragma SPARK_Mode;

with Pwm;
with Sparkduino; use Sparkduino;

package body Zumo_Motors is

   PWM_L : constant := 10;
   PWM_R : constant := 9;
   DIR_L : constant := 8;
   DIR_R : constant := 7;

   procedure Init
   is
   begin
      Initd := True;
      SetPinMode (Pin  => PWM_L,
                  Mode => PinMode'Pos (OUTPUT));
      SetPinMode (Pin  => PWM_R,
                  Mode => PinMode'Pos (OUTPUT));
      SetPinMode (Pin  => DIR_L,
                  Mode => PinMode'Pos (OUTPUT));
      SetPinMode (Pin  => DIR_R,
                  Mode => PinMode'Pos (OUTPUT));

      Pwm.Configure_Timers;
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
   begin
      if Speed < 0 then
         Rev := True;
         Speed := abs Speed;
      end if;

      Pwm.SetRate (Index => Pwm.Left,
                   Value => Word (Speed));

      if Rev xor FlipLeft then
         DigitalWrite (Pin => DIR_L,
                       Val => DigPinValue'Pos (HIGH));
      else
         DigitalWrite (Pin => DIR_L,
                       Val => DigPinValue'Pos (LOW));
      end if;

   end SetLeftSpeed;

   procedure SetRightSpeed (Velocity : Motor_Speed)
   is
      Rev   : Boolean := False;
      Speed : Motor_Speed := Velocity;
   begin
      if Speed < 0 then
         Rev := True;
         Speed := abs Speed;
      end if;

      Pwm.SetRate (Index => Pwm.Right,
                   Value => Word (Speed));

      if Rev xor FlipRight then
         DigitalWrite (Pin => DIR_R,
                       Val => DigPinValue'Pos (HIGH));
      else
         DigitalWrite (Pin => DIR_R,
                       Val => DigPinValue'Pos (LOW));
      end if;

   end SetRightSpeed;

   procedure SetSpeed (LeftVelocity : Motor_Speed;
                       RightVelocity : Motor_Speed)
   is
   begin
      SetLeftSpeed (Velocity => LeftVelocity);
      SetRightSpeed (Velocity => RightVelocity);
   end SetSpeed;

end Zumo_Motors;
