pragma SPARK_Mode;

with Types; use Types;

with Zumo_LSM303;
with Zumo_L3gd20h;

package Zumo_Motion is

   Initd : Boolean := False;

   procedure Init
     with Global => (In_Out => (Initd,
                                Zumo_LSM303.Initd,
                                Zumo_L3gd20h.Initd)),
     Pre => not Initd
       and then not Zumo_LSM303.Initd
       and then not Zumo_L3gd20h.Initd,
     Post => Initd
       and then Zumo_LSM303.Initd
       and then Zumo_L3gd20h.Initd;

   function Get_Heading return Degrees
     with Pre => Initd and Zumo_LSM303.Initd;

end Zumo_Motion;
