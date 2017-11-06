pragma SPARK_Mode;

with Line_Finder_Types; use Line_Finder_Types;
with Types; use Types;

with ATmega328P;
with Zumo_LED;
with Zumo_Motors;
with Zumo_QTR;

package Line_Finder is
   BotState : RobotState;

   procedure LineFinder (ReadMode : Sensor_Read_Mode)
     with Global => (Input => (Zumo_LED.Initd,
                               Zumo_Motors.Initd,
                               Zumo_QTR.Initd,
                               Zumo_Motors.FlipLeft,
                               Zumo_Motors.FlipRight,
                               Zumo_QTR.Calibrated_On,
                               Zumo_QTR.Calibrated_Off),
                     Output => (ATmega328P.OCR1A,
                                ATmega328P.OCR1B),
                     In_Out => (BotState,
                                Zumo_QTR.Cal_Vals_On,
                                Zumo_QTR.Cal_Vals_Off)),
     Pre => (Zumo_LED.Initd and
               Zumo_Motors.Initd and
                 Zumo_QTR.Initd);

private

   function CalculateLineState (D : Boolean_Array) return LineState
     with Global => (null),
     Pre => (D'Length = Sensor_Array'Length);

   procedure ReadLine (WhiteLine      : Boolean;
                       ReadMode       : Sensor_Read_Mode;
                       Line_State     : out LineState;
                       Bot_Pos        : out Robot_Position)
     with Global => (Input => (Zumo_QTR.Initd,
                               Zumo_QTR.Calibrated_On,
                               Zumo_QTR.Calibrated_Off),
                     In_Out => (BotState,
                                Zumo_QTR.Cal_Vals_On,
                                Zumo_QTR.Cal_Vals_Off)),
     Pre => (Zumo_QTR.Initd);

   procedure DecisionMatrix (State     : LineState;
                             Pos       : in out Robot_Position;
                             BaseSpeed : out Motor_Speed)
     with Global => (Input => (Zumo_LED.Initd),
                     In_Out => BotState),
     Pre => (Zumo_LED.Initd);

   procedure Offline_Correction (Error : in out Robot_Position)
     with Global => (In_Out => (BotState));

   procedure Error_Correct (Error         : Robot_Position;
                            Current_Speed : Motor_Speed;
                            LeftSpeed     : out Motor_Speed;
                            RightSpeed    : out Motor_Speed)
     with Global => (In_Out => (BotState));

end Line_Finder;
