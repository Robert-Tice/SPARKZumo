--  pragma SPARK_Mode;

with Zumo_LSM303;
with Zumo_L3gd20h;
with Wire;

with Ada.Numerics.Long_Elementary_Functions;
use Ada.Numerics.Long_Elementary_Functions;

package body Zumo_Motion is

   Pi : constant := 3.1415926;

   function Get_Heading return Degrees
   is
      Mag : Axis_Data;

      Heading : Degrees;
   begin
      Zumo_LSM303.Read_Mag (Data => Mag);

      Heading := Degrees (
                          Arctan (
                            Long_Float (Mag (Y)) / Long_Float (Mag (X))
                           ) * (180.0 / Pi));

      if Heading > 360.0 then
         Heading := Heading - 360.0;
      elsif Heading < 0.0 then
         Heading := 360.0 + Heading;
      end if;

      return Heading;

   end Get_Heading;

   procedure Init
   is
   begin
      Wire.Init_Master;
      Zumo_LSM303.Init;
      Zumo_L3gd20h.Init;

      Initd := True;
   end Init;

end Zumo_Motion;
