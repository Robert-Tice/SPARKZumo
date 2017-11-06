pragma SPARK_Mode;

package Zumo_Pushbutton is

   Initd : Boolean := False;

   procedure Init
     with Global => (In_Out => Initd),
     Pre => not Initd,
     Post => Initd;

   function IsPressed return Boolean
     with Pre => Initd;

   procedure WaitForButton
     with Pre => Initd,
     Global => Initd;

private

   procedure WaitForPress
     with Pre => Initd,
     Global => Initd;

   procedure WaitForRelease
     with Pre => Initd,
     Global => Initd;

end Zumo_Pushbutton;
