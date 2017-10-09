pragma SPARK_Mode;

with Types; use Types;

package Zumo_Motion is

   Initd : Boolean := False;

   procedure Init
     with Pre => not Initd,
     Post => Initd;

   function Get_Heading return Degrees
     with Pre => Initd;

end Zumo_Motion;
