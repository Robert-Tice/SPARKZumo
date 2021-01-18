pragma SPARK_Mode;

--  @summary
--  This package enables reading and waiting on a button
--
package Zumo_Pushbutton is

   --  True if the package has be init'd
   Initd : Boolean := False;

   --  The init sequence which does pin muxing and whatnot
   procedure Init
     with Global => (In_Out => Initd),
     Pre => not Initd,
     Post => Initd;

   --  Returns true if the button has been pressed
   --  @return True is the button is pressed
   function IsPressed return Boolean
     with Pre => Initd;

   --  Waits for the button to be pressed and released.
   --    Returns when the button is pressed and released
   procedure WaitForButton
     with Pre => Initd,
     Global => (Proof_In => Initd);

private

   --  Waits for the button to be pressed
   procedure WaitForPress
     with Pre => Initd,
     Global => (Proof_In => Initd);

   --  Waits for the button to be released
   procedure WaitForRelease
     with Pre => Initd,
     Global => (Proof_In => Initd);

end Zumo_Pushbutton;
