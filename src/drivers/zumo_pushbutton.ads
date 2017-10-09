pragma SPARK_Mode;

package Zumo_Pushbutton is

   Initd : Boolean := False;

   procedure Init
     with Pre => not Initd,
     Post => Initd;

   function IsPressed return Boolean
     with Pre => Initd;

   procedure WaitForButton
     with Pre => Initd;

end Zumo_Pushbutton;
