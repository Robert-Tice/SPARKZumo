with Line_Finder_Types; use Line_Finder_Types;
with Types; use Types;

package Line_Finder is

   procedure LineFinder (ReadMode : Sensor_Read_Mode);

private
   BotState : RobotState;

   function CalculateLineState (D : Boolean_Array) return LineState;

   procedure ReadLine (WhiteLine      : Boolean;
                       ReadMode       : Sensor_Read_Mode;
                       Line_State     : out LineState;
                       Bot_Pos        : out Robot_Position);

   procedure DecisionMatrix (State     : LineState;
                             Pos       : in out Robot_Position;
                             BaseSpeed : out Motor_Speed);

   procedure Offline_Correction (Error : in out Robot_Position);

   procedure Error_Correct (Error         : Robot_Position;
                            Current_Speed : Motor_Speed;
                            LeftSpeed     : out Motor_Speed;
                            RightSpeed    : out Motor_Speed);

end Line_Finder;
