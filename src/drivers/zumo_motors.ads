pragma SPARK_Mode;

with Types; use Types;

package Zumo_Motors is

   Initd : Boolean := False;

   procedure Init
     with Pre => not Initd,
     Post => Initd;

   procedure FlipLeftMotor (Flip : Boolean);
   procedure FlipRightMotor (Flip : Boolean);

   procedure SetLeftSpeed (Velocity : Motor_Speed)
     with Pre => Initd;
   procedure SetRightSpeed (Velocity : Motor_Speed)
     with Pre => Initd;
   procedure SetSpeed (LeftVelocity : Motor_Speed;
                       RightVelocity : Motor_Speed)
     with Pre => Initd;

end Zumo_Motors;
