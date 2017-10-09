pragma SPARK_Mode;

with Types; use Types;

package SPARKZumo is

   procedure WorkLoop;
   procedure Setup;

private

   procedure ReadLine (Sensor_Values : out Sensor_Array;
                       ReadMode      : Sensor_Read_Mode;
                       WhiteLine     : Boolean;
                       On_Line       : out Boolean;
                       Bot_Pos       : out Natural);

   procedure LineFinder;

end SPARKZumo;
