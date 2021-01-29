pragma SPARK_Mode;

with Line_Finder_Types; use Line_Finder_Types;

--  @summary
--  Graph filtering mechanism for discrete state filtering
--
--  @description
--  The package is responsible for window averaging a set of states to low-pass
--    filter the change between states that the robot detects.
--
--  Please don't edit anything in this file marked GENERATED! These are items
--    that the project plugin generates during the compilation
--

package Geo_Filter is

   --  The width of the averaging window
   Window_Size : constant := 5;

   --  This changed the size of the lookup table. Corresponds to half the
   --    width and half the height of the lookup graph
   Corner_Coord : constant := 15;

   --  GENERATED - The radii length of calculated noise
   Radii_Threshold    : constant := 7; --  Corner_Coord / 3 * sqrt(2)

   subtype X_Coordinate is Integer range (-1) * Corner_Coord .. Corner_Coord;
   subtype Y_Coordinate is Integer range (-1) * Corner_Coord .. Corner_Coord;

   --  A point in the Lookup table
   --  @field X coordinate in the X horizontal axis
   --  @field Y coordiante in the Y vertical axis
   type Point_Type is record
      X : X_Coordinate;
      Y : Y_Coordinate;
   end record;

   --  Position of each point on the graph. This is the point inserted into
   --    the averaging window
   State2PointLookup : constant array (LineState) of Point_Type :=
                         (Lost        => Point_Type'(X => (-1) * Corner_Coord,
                                                     Y => (-1) * Corner_Coord),
                          Online      => Point_Type'(X => Corner_Coord,
                                                     Y => Corner_Coord),
                          BranchRight => Point_Type'(X => Corner_Coord,
                                                     Y => 0),
                          BranchLeft  => Point_Type'(X => (-1) * Corner_Coord,
                                                     Y => Corner_Coord),
                          Fork        => Point_Type'(X => Corner_Coord,
                                                     Y => (-1) * Corner_Coord),
                          Perp        => Point_Type'(X => Corner_Coord,
                                                     Y => 0),
                          Unknown     => Point_Type'(X => 0,
                                                     Y => 0));

   type Window_Type is array (1 .. Window_Size) of Point_Type;

   Window       : Window_Type := (others => State2PointLookup (Online));
   Window_Index : Integer range 1 .. Window_Size := Window_Type'First;

   --  This performs the filtering
   --  @param State pass the detected state here and received the computed
   --             state here
   --  @param Thresh whether or not the computed point is inside the threshold
   --             window defined by the constant Radii_Threshold
   procedure FilterState (State  : in out LineState;
                          Thresh : out Boolean)
     with Global => (In_Out => (Window,
                                Window_Index)),
     Post => (if State'Old /= Unknown then
                Window_Index /= Window_Index'Old);
private

   --  Computes the distance from the center of the graph to coordinate X, Y
   --  @param X the X value of the coordinate to compute
   --  @param Y the y value of the coordinate to compute
   --  @return True if the distance from the center of the graph to
   --              X, Y > Radii_Threshold
   function Radii_Length (X : Integer;
                          Y : Integer)
                          return Integer;

   type StateLookupTable is array (X_Coordinate'Range, Y_Coordinate'Range)
     of LineState;

   --  GENERATED - this is computed from the project plugin and is dependent
   --    on the Corner_Coord constant above
   AvgPoint2StateLookup : constant StateLookupTable :=
                            ((Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown), (Unknown, Lost, Lost, Lost, Lost, Perp,
                             Perp, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             Perp, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             Perp, Perp, Perp, Perp, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, Unknown), (Unknown, Lost,
                             Lost, Lost, Lost, Lost, Perp, Perp, Perp, Perp,
                             Perp, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, Unknown), (Unknown, Lost, Lost, Lost,
                             Lost, Lost, Lost, Perp, Perp, Perp, Perp, Perp,
                             Perp, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             Perp, Perp, Perp, Perp, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             Unknown), (Unknown, Lost, Lost, Lost, Lost, Lost,
                             Lost, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             Perp, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             Perp, Perp, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, Unknown),
                             (Unknown, Lost, Lost, Lost, Lost, Lost, Lost,
                             Lost, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             Perp, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, Unknown),
                             (Unknown, Lost, Lost, Lost, Lost, Lost, Lost,
                             Lost, Lost, Perp, Perp, Perp, Perp, Perp, Perp,
                             Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             Unknown), (Unknown, Lost, Lost, Lost, Lost, Lost,
                             Lost, Lost, Lost, Lost, Perp, Perp, Perp, Perp,
                             Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, Unknown), (Unknown, Lost, Lost, Lost,
                             Lost, Lost, Lost, Lost, Lost, Lost, Perp, Perp,
                             Perp, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             Perp, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, Unknown), (Unknown, Lost,
                             Lost, Lost, Lost, Lost, Lost, Lost, Lost, Lost,
                             Lost, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
                             Perp, Perp, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, Unknown),
                             (Unknown, Lost, Lost, Lost, Lost, Lost, Lost,
                             Lost, Lost, Lost, Lost, Lost, Perp, Perp, Perp,
                             Perp, Perp, Perp, Perp, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, Unknown), (Unknown, Lost, Lost, Lost,
                             Lost, Lost, Lost, Lost, Lost, Lost, Lost, Lost,
                             Lost, Perp, Perp, Perp, Perp, Perp, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, Unknown),
                             (Unknown, Lost, Lost, Lost, Lost, Lost, Lost,
                             Lost, Lost, Lost, Lost, Lost, Lost, Perp, Perp,
                             Perp, Perp, Perp, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, Unknown), (Unknown, Lost,
                             Lost, Lost, Lost, Lost, Lost, Lost, Lost, Lost,
                             Lost, Lost, Lost, Lost, Perp, Perp, Perp,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, Unknown), (Unknown, Lost, Lost, Lost,
                             Lost, Lost, Lost, Lost, Lost, Lost, Lost, Lost,
                             Lost, Lost, Lost, Perp, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             BranchLeft, BranchLeft, BranchLeft, BranchLeft,
                             Unknown), (Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown), (Unknown, Fork, Fork, Fork,
                             Fork, Fork, Fork, Fork, Fork, Fork, Fork, Fork,
                             Fork, Fork, Fork, BranchRight, Online, Online,
                             Online, Online, Online, Online, Online, Online,
                             Online, Online, Online, Online, Online, Online,
                             Unknown), (Unknown, Fork, Fork, Fork, Fork, Fork,
                             Fork, Fork, Fork, Fork, Fork, Fork, Fork, Fork,
                             BranchRight, BranchRight, BranchRight, Online,
                             Online, Online, Online, Online, Online, Online,
                             Online, Online, Online, Online, Online, Online,
                             Unknown), (Unknown, Fork, Fork, Fork, Fork, Fork,
                             Fork, Fork, Fork, Fork, Fork, Fork, Fork,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, Online, Online, Online,
                             Online, Online, Online, Online, Online, Online,
                             Online, Online, Online, Unknown), (Unknown, Fork,
                             Fork, Fork, Fork, Fork, Fork, Fork, Fork, Fork,
                             Fork, Fork, Fork, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight, Online,
                             Online, Online, Online, Online, Online, Online,
                             Online, Online, Online, Online, Online, Unknown),
                             (Unknown, Fork, Fork, Fork, Fork, Fork, Fork,
                             Fork, Fork, Fork, Fork, Fork, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight, Online,
                             Online, Online, Online, Online, Online, Online,
                             Online, Online, Online, Online, Unknown),
                             (Unknown, Fork, Fork, Fork, Fork, Fork, Fork,
                             Fork, Fork, Fork, Fork, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, Online, Online, Online, Online,
                             Online, Online, Online, Online, Online, Online,
                             Unknown), (Unknown, Fork, Fork, Fork, Fork, Fork,
                             Fork, Fork, Fork, Fork, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight, Online,
                             Online, Online, Online, Online, Online, Online,
                             Online, Online, Unknown), (Unknown, Fork, Fork,
                             Fork, Fork, Fork, Fork, Fork, Fork, Fork,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, Online, Online, Online,
                             Online, Online, Online, Online, Online, Online,
                             Unknown), (Unknown, Fork, Fork, Fork, Fork, Fork,
                             Fork, Fork, Fork, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, Online, Online, Online,
                             Online, Online, Online, Online, Online, Unknown),
                             (Unknown, Fork, Fork, Fork, Fork, Fork, Fork,
                             Fork, BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight, Online,
                             Online, Online, Online, Online, Online, Online,
                             Unknown), (Unknown, Fork, Fork, Fork, Fork, Fork,
                             Fork, BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, Online, Online, Online,
                             Online, Online, Online, Unknown), (Unknown, Fork,
                             Fork, Fork, Fork, Fork, Fork, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, Online, Online, Online, Online,
                             Online, Online, Unknown), (Unknown, Fork, Fork,
                             Fork, Fork, Fork, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, Online, Online, Online,
                             Online, Online, Unknown), (Unknown, Fork, Fork,
                             Fork, Fork, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, BranchRight, BranchRight,
                             BranchRight, Online, Online, Online, Online,
                             Unknown), (Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown, Unknown, Unknown, Unknown,
                             Unknown, Unknown));

end Geo_Filter;
