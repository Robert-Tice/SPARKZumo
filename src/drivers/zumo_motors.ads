pragma SPARK_Mode;

with Types; use Types;

package Zumo_Motors is

   Initd : Boolean := False;

   FlipLeft : Boolean := False;
   FlipRight : Boolean := False;

   procedure Init
     with Global => (In_Out => Initd),
     Pre => not Initd,
     Post => Initd;

   procedure FlipLeftMotor (Flip : Boolean)
     with Global => (Output => (FlipLeft)),
     Post => FlipLeft = Flip;

   procedure FlipRightMotor (Flip : Boolean)
     with Global => (Output => (FlipRight)),
     Post => FlipRight = Flip;

   procedure SetLeftSpeed (Velocity : Motor_Speed)
     with Global => (Input  => (Initd,
                                FlipLeft)),
                     --                    Output => (Pwm.Register_State)),
     Pre => Initd;

   procedure SetRightSpeed (Velocity : Motor_Speed)
     with Global => (Input => (Initd,
                               FlipRight)),
   --                    Output => (Pwm.Register_State)),
     Pre => Initd;

   procedure SetSpeed (LeftVelocity  : Motor_Speed;
                       RightVelocity : Motor_Speed)
     with Global => (Input => (Initd,
                               FlipLeft,
                               FlipRight)),
   --                 Output => (Pwm.Register_State)),
     Pre => Initd;

end Zumo_Motors;
