with Types; use Types;

package Line_Finder is

   procedure LineFinder (ReadMode : Sensor_Read_Mode)
     with Global => Offline_Offset;

   Offline_Offset : Natural := 0;

private

   LastValue : Integer := 0;
   LastError : Integer := 0;

   Noise_Threshold : constant := Timeout / 10;
   Line_Threshold : constant := Timeout / 2;

   type RobotLineState is
     (Lost, Online, BranchRight, BranchLeft, Fork, Perp);

   Default_Speed : constant Motor_Speed := Motor_Speed'Last;

   procedure ReadLine (Sensor_Values : out Sensor_Array;
                       WhiteLine     : Boolean;
                       ReadMode      : Sensor_Read_Mode;
                       Bot_State     : out RobotLineState;
                       Bot_Pos       : out Robot_Position)
     with Global => (In_Out => LastValue);

   Offline_Inc : constant := 1;

   procedure Offline_Correction (Error : in out Robot_Position)
     with Global => (In_Out => Offline_Offset),
     Depends => (Error => (Offline_Offset, Error),
                 Offline_Offset => (Offline_Offset)),
     Post => Offline_Offset = Offline_Offset'Old + Offline_Inc;

   procedure Error_Correct (Error      : Robot_Position;
                            LeftSpeed  : out Motor_Speed;
                            RightSpeed : out Motor_Speed)
     with Global => (Input  => Default_Speed,
                     In_Out => LastError),
     Depends => (LeftSpeed  => (Error, LastError, Default_Speed),
                 RightSpeed => (Error, LastError, Default_Speed),
                 LastError  => (Error, LastError)),
     Post => (LastError = Error);

   function CalculateBotState (D : Boolean_Array) return RobotLineState;

end Line_Finder;
