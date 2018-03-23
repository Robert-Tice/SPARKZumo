pragma SPARK_Mode;

with Line_Finder_Types; use Line_Finder_Types;
with Geo_Filter;
with Types; use Types;

with Zumo_LED;
with Zumo_Motors;
with Zumo_QTR;

--  @summary
--  Line finder algorithm
--
--  @description
--  This package implements the line finder algorithm
--

package Line_Finder is
   --  Amount of time to determine "Hey I'm lost". Used to switch decision type
   Lost_Threshold : constant := 100;

   BotState : RobotState;

   --  Default fast speed used when "Hey I know where I am!!"
   Default_Fast_Speed      : constant := Motor_Speed'Last - 150;

   --  Default slow speed used when "I'm not sure where I am!!"
   Default_Slow_Speed      : constant := 3 * Default_Fast_Speed / 4;

   --  Default slowest speed used when "I have to make a decision,
   --    lets oversample"
   Default_Slowest_Speed : constant := Default_Slow_Speed / 2;

   --  Current fast speed
   Fast_Speed              : Motor_Speed := Default_Fast_Speed;
   --  Current slow speed
   Slow_Speed              : Motor_Speed := Default_Slow_Speed;

   --  The line finder algorithm entry point
   --  @param ReadMode the read mode to pass to read sensors
   procedure LineFinder (ReadMode : Sensor_Read_Mode)
     with Global => (Input => (Zumo_LED.Initd,
                               Zumo_Motors.Initd,
                               Zumo_Motors.FlipLeft,
                               Zumo_Motors.FlipRight,
                               Zumo_QTR.Initd,
                               Zumo_QTR.Calibrated_On,
                               Zumo_QTR.Calibrated_Off),

                     In_Out => (Fast_Speed,
                                Slow_Speed,
                                BotState,
                                Zumo_QTR.Cal_Vals_On,
                                Zumo_QTR.Cal_Vals_Off,
                                Geo_Filter.Window,
                                Geo_Filter.Window_Index)),
     Pre => (Zumo_LED.Initd and
               Zumo_Motors.Initd and
                 Zumo_QTR.Initd);

private

   --  This procedure reads the sensors and determine the bot position
   --  @param WhiteLine am I looking for a white line or black line
   --  @param ReadMode what mode to read to sensors with
   --  @param State the computed LineState
   procedure ReadLine (WhiteLine      : Boolean;
                       ReadMode       : Sensor_Read_Mode;
                       State      : out LineState)
     with Global => (Input  => (Zumo_QTR.Initd,
                                Zumo_QTR.Calibrated_On,
                                Zumo_QTR.Calibrated_Off),
                     In_Out => (BotState,
                                Zumo_QTR.Cal_Vals_On,
                                Zumo_QTR.Cal_Vals_Off)),
     Pre => (Zumo_QTR.Initd);

   --  Calculates the bots position in relation to the line
   --  @param Pos the computed position of the robot on the line
   procedure CalculateBotPosition (Pos : out Robot_Position);

   --  The complex decision matrix to decide the meaning of life
   --  @param State the state computed previously to use in the decision
   procedure DecisionMatrix (State     : LineState)
     with Global => (Input  => (Zumo_LED.Initd,
                                Zumo_Motors.Initd,
                                Zumo_Motors.FlipLeft,
                                Zumo_Motors.FlipRight),
                     In_Out => (BotState,
                                Fast_Speed,
                                Slow_Speed)),
     Pre => (Zumo_LED.Initd and
               Zumo_Motors.Initd);

   --  The simple decision matrix to decide how to survive
   --    See complex decision matrix for normal operation
   --  @param State the state computed previously to use in the decision
   procedure SimpleDecisionMatrix (State : LineState)
     with Global => (Input => (Zumo_LED.Initd,
                               Zumo_Motors.Initd,
                               Zumo_Motors.FlipLeft,
                               Zumo_Motors.FlipRight),
                     In_Out => (BotState,
                                Fast_Speed)),
     Pre => (Zumo_LED.Initd and
               Zumo_Motors.Initd);

   --  This computes how to adjust the motors to bring the bot back centered
   --    on the line.
   --  @param Error the computed error since the last detection
   --  @param Current_Speed the current speed of the bot
   --  @param LeftSpeed the new computed speed for the left motor
   --  @param RightSpeed the new computed speed for the right motor
   procedure Error_Correct (Error         : Robot_Position;
                            Current_Speed : Motor_Speed;
                            LeftSpeed     : out Motor_Speed;
                            RightSpeed    : out Motor_Speed)
     with Global => (In_Out => (BotState));

end Line_Finder;
