pragma SPARK_Mode;

with Types; use Types;

package Line_Finder_Types is

   type LineState is
     (Lost, Online, BranchRight, BranchLeft, Fork, Perp, Unknown)
     with Size => 8;

   type BotOrientation is
     (Left, Center, Right);

   subtype OfflineCounterType is Integer range
     2 * Motor_Speed'First .. 2 * Motor_Speed'Last;

   type DecisionType is
     (Simple, Complex);

   type RobotState is record
      LineHistory        : LineState := Online;
      OrientationHistory : BotOrientation := Center;

      SensorValueHistory : Integer := 0;

      ErrorHistory       : Robot_Position := 0;

      OfflineCounter     : OfflineCounterType := 0;

      LostCounter        : Natural := 0;
      Decision           : DecisionType := Complex;

      LineDetect         : Byte := 0;

      Sensor_Values      : Sensor_Array := (others => 0);
   end record;

   LineStateStr : array (LineState) of String (1 .. 2) :=
                    (Lost        => "Lo",
                     Online      => "On",
                     BranchRight => "BR",
                     BranchLeft  => "BL",
                     Fork        => "Fo",
                     Perp        => "Pe",
                     Unknown     => "Uk");

   LineStateLookup : constant array (0 .. 2 ** Num_Sensors - 1) of LineState :=
                       (2#00_000_000# => Lost,
                        2#00_000_001# => Online,
                        2#00_000_010# => Online,
                        2#00_000_011# => Online,
                        2#00_000_100# => Online,
                        2#00_000_101# => Fork,
                        2#00_000_110# => Online,
                        2#00_000_111# => BranchLeft,
                        2#00_001_000# => Online,
                        2#00_001_001# => Fork,
                        2#00_001_010# => Fork,
                        2#00_001_011# => Fork,
                        2#00_001_100# => Online,
                        2#00_001_101# => Fork,
                        2#00_001_110# => Online,
                        2#00_001_111# => BranchLeft,
                        2#00_010_000# => Online,
                        2#00_010_001# => Fork,
                        2#00_010_010# => Fork,
                        2#00_010_011# => Fork,
                        2#00_010_100# => Fork,
                        2#00_010_101# => Unknown,
                        2#00_010_110# => Fork,
                        2#00_010_111# => Fork,
                        2#00_011_000# => Online,
                        2#00_011_001# => Fork,
                        2#00_011_010# => Fork,
                        2#00_011_011# => Fork,
                        2#00_011_100# => Online,
                        2#00_011_101# => Fork,
                        2#00_011_110# => Online,
                        2#00_011_111# => BranchLeft,
                        2#00_100_000# => Online,
                        2#00_100_001# => Fork,
                        2#00_100_010# => Fork,
                        2#00_100_011# => Fork,
                        2#00_100_100# => Fork,
                        2#00_100_101# => Unknown,
                        2#00_100_110# => Fork,
                        2#00_100_111# => Fork,
                        2#00_101_000# => Fork,
                        2#00_101_001# => Unknown,
                        2#00_101_010# => Unknown,
                        2#00_101_011# => Unknown,
                        2#00_101_100# => Fork,
                        2#00_101_101# => Unknown,
                        2#00_101_110# => Fork,
                        2#00_101_111# => Fork,
                        2#00_110_000# => Online,
                        2#00_110_001# => Fork,
                        2#00_110_010# => Fork,
                        2#00_110_011# => Fork,
                        2#00_110_100# => Fork,
                        2#00_110_101# => Unknown,
                        2#00_110_110# => Fork,
                        2#00_110_111# => Fork,
                        2#00_111_000# => BranchRight,
                        2#00_111_001# => Fork,
                        2#00_111_010# => Fork,
                        2#00_111_011# => Fork,
                        2#00_111_100# => BranchRight,
                        2#00_111_101# => Unknown,
                        2#00_111_110# => BranchRight,
                        2#00_111_111# => Perp);

end Line_Finder_Types;
