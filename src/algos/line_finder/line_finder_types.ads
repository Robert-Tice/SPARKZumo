package Line_Finder_Types is

   type LineState is
     (Lost, Online, BranchRight, BranchLeft, Fork, Perp);

   type BotOrientation is
     (Left, Center, Right);

   type RobotState is record
      LineHistory        : LineState := Online;
      OrientationHistory : BotOrientation := Center;

      SensorValueHistory : Integer := 0;

      CorrectionCounter  : Natural := 0;

      ErrorHistory       : Integer := 0;

      Offline_Offset     : Natural := 0;
   end record;

end Line_Finder_Types;
