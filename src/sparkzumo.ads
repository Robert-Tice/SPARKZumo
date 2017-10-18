pragma SPARK_Mode;

with Types; use Types;

package SPARKZumo is

--   Initd    : Boolean := False;
   ReadMode : constant Sensor_Read_Mode := Emitters_On;

   procedure WorkLoop
     with Global => (ReadMode);
   --    Pre => Initd;

   procedure Setup
     with Global => null;
 --    Pre => not Initd,
 --    Post => Initd;

private

   procedure Calibration_Sequence
     with Global => (ReadMode);
   --    Pre => Initd;

   procedure Inits;
   --  with Global => (Initd),
 --    Pre => not Initd,
 --    Post => Initd;

   procedure Exception_Handler;

end SPARKZumo;
