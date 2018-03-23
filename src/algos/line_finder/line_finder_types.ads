pragma SPARK_Mode;

with Types; use Types;

--  @summary
--  Types used in the line finder algorithm

package Line_Finder_Types is

   --  States detected by the IR sensors
   --  @value Lost no line found. Start panicking
   --  @value Online one line is found somewhere under the middle set of
   --    sensors
   --  @value BranchRight we found a branch going to the right of the robot
   --  @value BranchLeft we found a branch going to the left of the robot
   --  @value Fork we found a fork in the line. Pick it up!
   --  @value Perp we came to a perpendicular intersection.
   --  @value Unknown this is a state where we have lots of noise. Ignore
   type LineState is
     (Lost, Online, BranchRight, BranchLeft, Fork, Perp, Unknown)
     with Size => 8;

   --  The orientation of the robot in relation to the line
   --  @value Left the line is under the left side of the robot
   --  @value Center the line is under the center of the robot
   --  @value Right the line is under the right side of the robot
   type BotOrientation is
     (Left, Center, Right);

   --  When we can't find the line we should do larger circles to refind it.
   --    This is the type that we can use to tell the motors how to circle
   subtype OfflineCounterType is Integer range
     2 * Motor_Speed'First .. 2 * Motor_Speed'Last;

   --  We can make decisions based on a simple scheme or complex
   --  @value Simple simple decision matrix. Best when we are Lost
   --  @value Complex complex decision matrix. Best when we know whats going on
   type DecisionType is
     (Simple, Complex);

   --  The data structure holding information about the robot and its current
   --    situation
   --  @field LineHistory the last computer state
   --  @field OrientationHistory the last computed BotOrientation
   --  @field SensorValueHistory the last sensor value detected
   --  @field ErrorHistory the last computed error from the robot centered
   --  @field OfflineCounter How the motors should circle when lost
   --  @field LostCounter How long its been since we saw the line
   --  @field Decision type of decisions matrix to use
   --  @field LineDetect the value computed from the value we read from the
   --    sensors
   --  @field Sensor_Values the actual values we read from the sensors
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

   --  FOR DEBUG! Maps states to strings
   LineStateStr : array (LineState) of String (1 .. 2) :=
                    (Lost        => "Lo",
                     Online      => "On",
                     BranchRight => "BR",
                     BranchLeft  => "BL",
                     Fork        => "Fo",
                     Perp        => "Pe",
                     Unknown     => "Uk");

   --  This is the lookup table we use to convert SensorValues to detected
   --    states.
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
