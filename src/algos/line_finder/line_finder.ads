pragma SPARK_Mode;

with Line_Finder_Types; use Line_Finder_Types;
with Geo_Filter;
with Types; use Types;

with ATmega328P;
with Zumo_LED;
with Zumo_Motors;
with Zumo_QTR;

package Line_Finder is
   Lost_Threshold : constant := 100;

   BotState : RobotState;

   procedure LineFinder (ReadMode : Sensor_Read_Mode)
     with Global => (Input => (Zumo_LED.Initd,
                               Zumo_Motors.Initd,
                               Zumo_Motors.FlipLeft,
                               Zumo_Motors.FlipRight,
                               Zumo_QTR.Initd,
                               Zumo_QTR.Calibrated_On,
                               Zumo_QTR.Calibrated_Off),

                     In_Out => (BotState,
                                Zumo_QTR.Cal_Vals_On,
                                Zumo_QTR.Cal_Vals_Off,
                                Geo_Filter.Window,
                                Geo_Filter.Window_Index,
                                ATmega328P.OCR1A,
                                ATmega328P.OCR1B)),
     Pre => (Zumo_LED.Initd and
               Zumo_Motors.Initd and
                 Zumo_QTR.Initd);

private

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

   function CalculateBotPosition return Robot_Position;

   procedure DecisionMatrix (State     : LineState)
     with Global => (Input  => (Zumo_LED.Initd,
                                Zumo_Motors.Initd,
                                Zumo_Motors.FlipLeft,
                                Zumo_Motors.FlipRight),
                     In_Out => (BotState,
                                ATmega328P.OCR1A,
                                ATmega328P.OCR1B)),
     Pre => (Zumo_LED.Initd and
               Zumo_Motors.Initd);

   procedure SimpleDecisionMatrix (State : LineState)
     with Global => (Input => (Zumo_LED.Initd,
                               Zumo_Motors.Initd,
                               Zumo_Motors.FlipLeft,
                               Zumo_Motors.FlipRight),
                     In_Out => (BotState,
                                ATmega328P.OCR1A,
                                ATmega328P.OCR1B)),
     Pre => (Zumo_LED.Initd and
               Zumo_Motors.Initd);

   procedure Error_Correct (Error         : Robot_Position;
                            Current_Speed : Motor_Speed;
                            LeftSpeed     : out Motor_Speed;
                            RightSpeed    : out Motor_Speed)
     with Global => (In_Out => (BotState));

end Line_Finder;
