pragma SPARK_Mode;

package SPARKZumo is

   procedure WorkLoop;
   procedure Setup
     with SPARK_Mode => Off;

end SPARKZumo;
