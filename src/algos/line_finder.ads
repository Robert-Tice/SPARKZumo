with Types; use Types;

package Line_Finder is

   procedure LineFinder (ReadMode : Sensor_Read_Mode)
     with Global => Offline_Offset;

   Offline_Offset : Natural := 0;

private

   LastValue : Integer := 0;
   LastError : Integer := 0;

   Default_Speed : constant Motor_Speed := Motor_Speed'Last;

   procedure ReadLine (Sensor_Values : out Sensor_Array;
                       WhiteLine     : Boolean;
                       ReadMode      : Sensor_Read_Mode;
                       On_Line       : out Boolean;
                       Bot_Pos       : out Robot_Position)
     with Global => (In_Out => LastValue),
     Post => (if not On_Line then (Bot_Pos = Robot_Position'First or
                  Bot_Pos = Robot_Position'Last));

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

end Line_Finder;
