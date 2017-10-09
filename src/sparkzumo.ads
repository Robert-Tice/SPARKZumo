pragma SPARK_Mode;

package SPARKZumo is

   Initd : Boolean := False;

   procedure WorkLoop
     with Pre => Initd;

   procedure Setup
     with Pre => not Initd,
     Post => Initd;

private

   procedure Calibration_Sequence
     with Global => null,
     Pre => Initd;

   procedure Inits
     with Pre => not Initd,
     Post => Initd;

end SPARKZumo;
