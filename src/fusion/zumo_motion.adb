pragma SPARK_Mode;

with Zumo_LSM303;
with Zumo_L3gd20h;
with Wire;

with Types; use Types;
with Sparkduino; use Sparkduino;

with Interfaces.C; use Interfaces.C;


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

      for I in Mag'Range loop
         Serial_Print_Short (Msg => "Raw: ",
                             Val => Mag (I));
      end loop;

      Heading := Degrees (
                          Arctan (
                            Long_Float (Mag (Y)) / Long_Float (Mag (X))
                           ) * (180.0 / 3.1415926));


      if Heading > 360.0 then
         Heading := Heading - 360.0;
      elsif Heading < 0.0 then
         Heading := 360.0 + Heading;
      end if;

      Serial_Print_Float (Msg => "Heading: ",
                          Val => Heading);

      return Heading;

   end Get_Heading;

   procedure Init
   is
   begin
      Wire.Init_Master;
      Zumo_LSM303.Init;
      Zumo_L3gd20h.Init;
     null;
   end Init;


end Zumo_Motion;
