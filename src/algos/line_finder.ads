with Types; use Types;

package Line_Finder is

   procedure LineFinder (ReadMode : Sensor_Read_Mode)
     with Global => Offline_Offset;

   Offline_Offset : Natural := 0;

private

   LastValue : Integer := 0;
   LastError : Integer := 0;

   CorrectedThreshold : constant := 5;
   CorrectionCounter : Natural := 0;

   Noise_Threshold : constant := Timeout / 10;
   Line_Threshold : constant := Timeout / 2;

   type LineState is
     (Lost, Online, BranchRight, BranchLeft, Fork, Perp);

   LastState : LineState := Online;

   type BotOrientation is
     (Left, Center, Right);

   LastOrientation : BotOrientation := Center;

   Fast_Speed : constant Motor_Speed := Motor_Speed'Last - 80;
   Slow_Speed    : constant Motor_Speed := Fast_Speed / 3;

   procedure ReadLine (WhiteLine     : Boolean;
                       ReadMode      : Sensor_Read_Mode;
                       Line_State     : out LineState;
                       Bot_Pos       : out Robot_Position)
     with Global => (In_Out => LastValue);

   procedure DecisionMatrix (State     : LineState;
                             Pos       : in out Robot_Position;
                             BaseSpeed : out Motor_Speed);

   Offline_Inc : constant := 1;

   procedure Offline_Correction (Error : in out Robot_Position)
     with Global => (In_Out => Offline_Offset),
     Depends => (Error => (Offline_Offset, Error),
                 Offline_Offset => (Offline_Offset)),
     Post => Offline_Offset = Offline_Offset'Old + Offline_Inc;

   procedure Error_Correct (Error         : Robot_Position;
                            Current_Speed : Motor_Speed;
                            LeftSpeed     : out Motor_Speed;
                            RightSpeed    : out Motor_Speed);

   function CalculateLineState (D : Boolean_Array) return LineState;

end Line_Finder;
