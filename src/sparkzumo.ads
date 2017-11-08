pragma SPARK_Mode;

with Types; use Types;

--  These are visible to the spec for SPARK Globals
with ATmega328P;
with Zumo_LED;
with Zumo_LSM303;
with Zumo_L3gd20h;
with Zumo_Motion;
with Zumo_Motors;
with Zumo_Pushbutton;
with Zumo_QTR;

with Wire;

with Line_Finder;

package SPARKZumo is

--   Initd    : Boolean := False;
   ReadMode : constant Sensor_Read_Mode := Emitters_On;

   procedure WorkLoop
     with Global => (Input => ( -- Initd,
                               Zumo_LED.Initd,
                               Zumo_Motors.Initd,
                               Zumo_QTR.Initd,
                               Zumo_Motors.FlipLeft,
                               Zumo_Motors.FlipRight,
                               Zumo_QTR.Calibrated_On,
                               Zumo_QTR.Calibrated_Off),
                     Output => (ATmega328P.OCR1A,
                                ATmega328P.OCR1B),
                     In_Out => (Line_Finder.BotState,
                                Zumo_QTR.Cal_Vals_On,
                                Zumo_QTR.Cal_Vals_Off)),
     Pre => ( -- Initd and
               Zumo_LED.Initd and
                 Zumo_Motors.Initd and
                   Zumo_QTR.Initd);

   procedure Setup
     with Pre => ( -- not Initd and
                    not Zumo_LED.Initd and
                      not Zumo_Pushbutton.Initd and
                        not Zumo_Motors.Initd and
                          not Zumo_QTR.Initd and
                            not Zumo_Motion.Initd),
             Post => ( -- Initd and
                        Zumo_LED.Initd and
                          Zumo_Pushbutton.Initd and
                            Zumo_Motors.Initd and
                              Zumo_QTR.Initd and
                                Zumo_Motion.Initd);

private

   procedure Calibration_Sequence
     with Global => (Input => ( -- Initd,
                               Zumo_Motors.Initd,
                               Zumo_Motors.FlipLeft,
                               Zumo_Motors.FlipRight,
                               Zumo_QTR.Initd),
                     Output => (Zumo_QTR.Calibrated_On,
                                Zumo_QTR.Calibrated_Off,
                                ATmega328P.OCR1A,
                                ATmega328P.OCR1B),
                     In_Out => (Zumo_QTR.Cal_Vals_On,
                                Zumo_QTR.Cal_Vals_Off)),
     Pre => ( -- Initd and
               Zumo_Motors.Initd and
                 Zumo_QTR.Initd);

   procedure Inits
     with Global => (Input  => (Wire.Transmission_Status),
                     Output => (ATmega328P.TCCR1A,
                                ATmega328P.TCCR1B,
                                ATmega328P.ICR1),
                     In_Out => ( -- Initd,
                                Zumo_LED.Initd,
                                Zumo_LSM303.Initd,
                                Zumo_L3gd20h.Initd,
                                Zumo_Motion.Initd,
                                Zumo_Motors.Initd,
                                Zumo_Pushbutton.Initd,
                                Zumo_QTR.Initd)),
     Pre => ( -- not Initd and
               not Zumo_LED.Initd and
                 not Zumo_Pushbutton.Initd and
                   not Zumo_Motors.Initd and
                     not Zumo_QTR.Initd and
                       not Zumo_Motion.Initd),
     Post => ( -- Initd and
                Zumo_LED.Initd and
                  Zumo_Pushbutton.Initd and
                    Zumo_Motors.Initd and
                      Zumo_QTR.Initd and
                        Zumo_Motion.Initd);

   procedure Exception_Handler
     with Pre => (Zumo_LED.Initd and Zumo_Motors.Initd);

end SPARKZumo;
