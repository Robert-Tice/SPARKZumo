pragma SPARK_Mode;

with Types; use Types;

--  @summary
--  Control for the robot's motors
--
--  @description
--  This package exposes on interface to control the robot's motors
--

package Zumo_Motors is

   --  True if the package has been init'd
   Initd : Boolean := False;

   --  Whether to reverse the left motor
   FlipLeft : Boolean := False;

   --  Whether to reverse the right motor
   FlipRight : Boolean := False;

   --  Init the package. pin mux and whatnot
   procedure Init
     with Global => (In_Out => Initd),
     Pre => not Initd,
     Post => Initd;

   --  Flip the direction of the left motor
   --  @param Flip if true, flip the direction
   procedure FlipLeftMotor (Flip : Boolean)
     with Global => (Output => (FlipLeft)),
     Post => FlipLeft = Flip;

   --  Flip the direction of the right motor
   --  @param Flip if tru,. flip the direction
   procedure FlipRightMotor (Flip : Boolean)
     with Global => (Output => (FlipRight)),
     Post => FlipRight = Flip;

   --  Set the speed of the left motor
   --  @param Velocity the speed to set the motor at
   procedure SetLeftSpeed (Velocity : Motor_Speed)
     with Global => (Proof_In => Initd,
                     Input    => FlipLeft),
                     --                    Output => (Pwm.Register_State)),
     Pre => Initd;

   --  Set the speed of the right motor
   --  @param Velocity the speed to set the motor at
   procedure SetRightSpeed (Velocity : Motor_Speed)
     with Global => (Proof_In => Initd,
                     Input    => FlipRight),
   --                    Output => (Pwm.Register_State)),
     Pre => Initd;

   --  Set the speed of both the left and right motors
   --  @param LeftVelocity the left motor velocity to set
   --  @param RightVelocity the right motor velocity to set
   procedure SetSpeed (LeftVelocity  : Motor_Speed;
                       RightVelocity : Motor_Speed)
     with Global => (Proof_In => Initd,
                     Input => (FlipLeft,
                               FlipRight)),
   --                 Output => (Pwm.Register_State)),
     Pre => Initd;

end Zumo_Motors;
