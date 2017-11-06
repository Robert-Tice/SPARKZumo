--  pragma SPARK_Mode;

with Types; use Types;

with Zumo_LSM303;
with Zumo_L3gd20h;
with Wire;

package Zumo_Motion is

   Initd : Boolean := False;

   procedure Init
     with Global => (Input  => (Wire.Transmission_Status),
                     Output => (Initd,
                                Zumo_LSM303.Initd,
                                Zumo_L3gd20h.Initd)),
     Pre => not Initd,
     Post => Initd;

   function Get_Heading return Degrees
     with Pre => Initd;

end Zumo_Motion;
