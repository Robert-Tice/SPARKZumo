pragma SPARK_Mode;

with Types; use Types;

--  These are visible to the spec for SPARK Globals
with Geo_Filter;
--  with Pwm;
with Zumo_LED;
with Zumo_LSM303;
with Zumo_L3gd20h;
with Zumo_Motion;
with Zumo_Motors;
with Zumo_Pushbutton;
with Zumo_QTR;

with Wire;

with Line_Finder;

--  @summary
--  The main entry point to the application
--
--  @description
--  This is the main entry point to the application. The Setup and Workloop
--    functions are called from the Arduino sketch
--
package SPARKZumo is

   --  True if we have called all necessary inits
   Initd    : Boolean := False;

   --  The mode to use to read the IR sensors
   ReadMode : constant Sensor_Read_Mode := Emitters_On;

   --  A quick utility test to work with the RISC board
   procedure RISC_Test;

   --  The main workloop of the application. This is called from the loop
   --    function of the Arduino sketch
   procedure WorkLoop
     with Global => (Proof_In => (Initd,
                                  Zumo_LED.Initd,
                                  Zumo_Motors.Initd,
                                  Zumo_QTR.Initd),
                     Input => (Zumo_Motors.FlipLeft,
                               Zumo_Motors.FlipRight,
                               Zumo_QTR.Calibrated_On,
                               Zumo_QTR.Calibrated_Off),
                     In_Out => (Line_Finder.BotState,
                                Line_Finder.Fast_Speed,
                                Line_Finder.Slow_Speed,
                                Zumo_QTR.Cal_Vals_On,
                                Zumo_QTR.Cal_Vals_Off,
                                Geo_Filter.Window,
                                Geo_Filter.Window_Index)),
     Pre => (Initd and
                Zumo_LED.Initd and
                 Zumo_Motors.Initd and
                   Zumo_QTR.Initd);

   --  This setup procedure is called from the setup function in the Arduino
   --    sketch
   procedure Setup
     with Pre => (not Initd and
                    not Zumo_LED.Initd and
                      not Zumo_Pushbutton.Initd and
                        not Zumo_Motors.Initd and
                          not Zumo_QTR.Initd and
                            not Zumo_Motion.Initd),
             Post => (Initd and
                        Zumo_LED.Initd and
                          Zumo_Pushbutton.Initd and
                            Zumo_Motors.Initd and
                              Zumo_QTR.Initd and
                                Zumo_Motion.Initd);

private

   --  The actual calibration sequence to run. This called calibration many
   --    times while moving the robot around. The robot should be place around
   --    a line so that it can calibrate on what is a line and what isnt.
   procedure Calibration_Sequence
     with Global => (Proof_In => (Initd,
                                  Zumo_Motors.Initd,
                                  Zumo_QTR.Initd),
                     Input => (Zumo_Motors.FlipLeft,
                               Zumo_Motors.FlipRight),
                     Output => (Zumo_QTR.Calibrated_On,
                                Zumo_QTR.Calibrated_Off),
                     In_Out => (Zumo_QTR.Cal_Vals_On,
                                Zumo_QTR.Cal_Vals_Off)),
     Pre => (Initd and
                Zumo_Motors.Initd and
                  Zumo_QTR.Initd);

   --  This handles init'ing everything that needs to be init'd in the app
   procedure Inits
     with Global => (Input  => (Wire.Transmission_Status),
                     --                    Output => (Pwm.Register_State),
                     In_Out => (Initd,
                                Zumo_LED.Initd,
                                Zumo_LSM303.Initd,
                                Zumo_L3gd20h.Initd,
                                Zumo_Motion.Initd,
                                Zumo_Motors.Initd,
                                Zumo_Pushbutton.Initd,
                                Zumo_QTR.Initd)),
     Pre => (not Initd and
               not Zumo_LED.Initd and
                 not Zumo_Pushbutton.Initd and
                   not Zumo_Motors.Initd and
                     not Zumo_QTR.Initd and
                       not Zumo_Motion.Initd),
     Post => (Initd and
                Zumo_LED.Initd and
                  Zumo_Pushbutton.Initd and
                    Zumo_Motors.Initd and
                      Zumo_QTR.Initd and
                        Zumo_Motion.Initd);

   --  This is the exception handler that ends in a infinite loop. This is
   --    called from the Ardunio sketch when an exception is thrown.
   procedure Exception_Handler
     with Pre => (Zumo_LED.Initd and Zumo_Motors.Initd);

end SPARKZumo;
