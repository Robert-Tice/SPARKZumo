pragma SPARK_Mode;


package Zumo_LED is

   Initd : Boolean := False;
   State : Boolean := False;

   procedure Init
     with Pre => not Initd,
     Post => Initd;

   procedure Yellow_Led (On : Boolean)
     with Pre => Initd;

end Zumo_LED;
