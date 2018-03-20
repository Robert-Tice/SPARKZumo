pragma SPARK_Mode;

with Line_Finder_Types; use Line_Finder_Types;

package Geo_Filter is

   Window_Size : constant := 5;

   Corner_Coord       : constant := 15;

   --------------------------------------------------------------------------
   --                         DO NOT MODIFY BEYOND THIS LINE               --
   --                                                                      --
   --                   This file is autogenerated by the IDE plugin       --
   --------------------------------------------------------------------------


   Corner_Coord_Magic : constant := 4;   --  Corner_Coord / (2 * sqrt(3))

   Radii_Threshold    : constant := 7;  --  Corner_Coord / 3 * sqrt(2)

   subtype X_Coordinate is Integer range (-1) * Corner_Coord .. Corner_Coord;
   subtype Y_Coordinate is Integer range (-1) * Corner_Coord .. Corner_Coord;

   X_Diff       : constant := Corner_Coord / 2;
   Y_Diff       : constant := Corner_Coord - Corner_Coord_Magic;

   type Point_Type is record
      X : X_Coordinate;
      Y : Y_Coordinate;
   end record;

   State2PointLookup : constant array (LineState) of Point_Type :=
                         (Lost        => Point_Type'(X => (-1) * X_Diff,
                                                     Y => (-1) * Y_Diff),
                          Online      => Point_Type'(X => X_Diff,
                                                     Y => Y_Diff),
                          BranchRight => Point_Type'(X => X_Coordinate'Last,
                                                     Y => 0),
                          BranchLeft  => Point_Type'(X => (-1) * X_Diff,
                                                     Y => Y_Diff),
                          Fork        => Point_Type'(X => X_Diff,
                                                     Y => (-1) * Y_Diff),
                          Perp        => Point_Type'(X => X_Coordinate'First,
                                                     Y => 0),
                          Unknown     => Point_Type'(X => 0,
                                                     Y => 0));

   type Window_Type is array (1 .. Window_Size) of Point_Type;

   Window       : Window_Type := (others => Point_Type'(X => X_Diff,
                                                        Y => Y_Diff));
   Window_Index : Integer := Window_Type'First;

   procedure FilterState (State : in out LineState;
                          Thresh : out Boolean)
     with Global => (In_Out => (Window,
                                Window_Index)),
     Post => (Window_Index in Window_Type'Range and
                Window_Index /= Window_Index'Old);
private

   function Radii_Length (X : Integer;
                          Y : Integer)
                          return Integer;

   type StateLookupTable is array (X_Coordinate'Range, Y_Coordinate'Range)
     of LineState;

   AvgPoint2StateLookup : constant StateLookupTable :=
       ((Unknown, Unknown, Unknown, Unknown, Unknown,
        Unknown, Unknown, Unknown, Unknown, Unknown,
        Unknown, Unknown, Unknown, Unknown, Unknown,
        Unknown, Unknown, Unknown, Unknown, Unknown,
        Unknown, Unknown, Unknown, Unknown, Unknown,
        Unknown, Unknown, Unknown, Unknown, Unknown,
        Unknown), (Unknown, Lost, Lost, Lost, Lost,
          Lost, Lost, Lost, Lost, Perp, Perp, Perp, Perp,
          Perp, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
          Perp, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, Unknown), (Unknown, Lost, Lost,
          Lost, Lost, Lost, Lost, Lost, Lost, Perp, Perp,
          Perp, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
          Perp, Perp, Perp, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, Unknown), (Unknown,
          Lost, Lost, Lost, Lost, Lost, Lost, Lost, Lost,
          Lost, Perp, Perp, Perp, Perp, Perp, Perp, Perp,
          Perp, Perp, Perp, Perp, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, Unknown),
        (Unknown, Lost, Lost, Lost, Lost, Lost, Lost,
         Lost, Lost, Lost, Perp, Perp, Perp, Perp, Perp,
         Perp, Perp, Perp, Perp, Perp, Perp, BranchLeft,
         BranchLeft, BranchLeft, BranchLeft, BranchLeft,
         BranchLeft, BranchLeft, BranchLeft, BranchLeft,
         Unknown), (Unknown, Lost, Lost, Lost, Lost,
          Lost, Lost, Lost, Lost, Lost, Lost, Perp, Perp,
          Perp, Perp, Perp, Perp, Perp, Perp, Perp,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, Unknown), (Unknown,
          Lost, Lost, Lost, Lost, Lost, Lost, Lost, Lost,
          Lost, Lost, Perp, Perp, Perp, Perp, Perp, Perp,
          Perp, Perp, Perp, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          Unknown), (Unknown, Lost, Lost, Lost, Lost,
          Lost, Lost, Lost, Lost, Lost, Lost, Lost, Perp,
          Perp, Perp, Perp, Perp, Perp, Perp, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, Unknown), (Unknown,
          Lost, Lost, Lost, Lost, Lost, Lost, Lost, Lost,
          Lost, Lost, Lost, Perp, Perp, Perp, Perp, Perp,
          Perp, Perp, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          Unknown), (Unknown, Lost, Lost, Lost, Lost,
          Lost, Lost, Lost, Lost, Lost, Lost, Lost, Lost,
          Perp, Perp, Perp, Perp, Perp, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, Unknown),
        (Unknown, Lost, Lost, Lost, Lost, Lost, Lost,
         Lost, Lost, Lost, Lost, Lost, Lost, Perp, Perp,
         Perp, Perp, Perp, BranchLeft, BranchLeft,
         BranchLeft, BranchLeft, BranchLeft, BranchLeft,
         BranchLeft, BranchLeft, BranchLeft, BranchLeft,
         BranchLeft, BranchLeft, Unknown), (Unknown,
          Lost, Lost, Lost, Lost, Lost, Lost, Lost, Lost,
          Lost, Lost, Lost, Lost, Lost, Perp, Perp, Perp,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, Unknown), (Unknown, Lost, Lost,
          Lost, Lost, Lost, Lost, Lost, Lost, Lost, Lost,
          Lost, Lost, Lost, Perp, Perp, Perp, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          Unknown), (Unknown, Lost, Lost, Lost, Lost,
          Lost, Lost, Lost, Lost, Lost, Lost, Lost, Lost,
          Lost, Lost, Perp, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          BranchLeft, BranchLeft, BranchLeft, BranchLeft,
          Unknown), (Unknown, Lost, Lost, Lost, Lost,
          Lost, Lost, Lost, Lost, Lost, Lost, Lost, Lost,
          Lost, Lost, Perp, BranchLeft, BranchLeft,
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
          Unknown), (Unknown, Fork, Fork, Fork, Fork,
          Fork, Fork, Fork, Fork, Fork, Fork, Fork, Fork,
          Fork, Fork, BranchRight, Online, Online, Online,
          Online, Online, Online, Online, Online, Online,
          Online, Online, Online, Online, Online,
          Unknown), (Unknown, Fork, Fork, Fork, Fork,
          Fork, Fork, Fork, Fork, Fork, Fork, Fork, Fork,
          Fork, BranchRight, BranchRight, BranchRight,
          Online, Online, Online, Online, Online, Online,
          Online, Online, Online, Online, Online, Online,
          Online, Unknown), (Unknown, Fork, Fork, Fork,
          Fork, Fork, Fork, Fork, Fork, Fork, Fork, Fork,
          Fork, Fork, BranchRight, BranchRight,
          BranchRight, Online, Online, Online, Online,
          Online, Online, Online, Online, Online, Online,
          Online, Online, Online, Unknown), (Unknown,
          Fork, Fork, Fork, Fork, Fork, Fork, Fork, Fork,
          Fork, Fork, Fork, Fork, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, Online, Online, Online, Online,
          Online, Online, Online, Online, Online, Online,
          Online, Online, Unknown), (Unknown, Fork, Fork,
          Fork, Fork, Fork, Fork, Fork, Fork, Fork, Fork,
          Fork, Fork, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight, Online,
          Online, Online, Online, Online, Online, Online,
          Online, Online, Online, Online, Online,
          Unknown), (Unknown, Fork, Fork, Fork, Fork,
          Fork, Fork, Fork, Fork, Fork, Fork, Fork,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, Online, Online, Online, Online,
          Online, Online, Online, Online, Online, Online,
          Online, Unknown), (Unknown, Fork, Fork, Fork,
          Fork, Fork, Fork, Fork, Fork, Fork, Fork, Fork,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, Online, Online, Online, Online,
          Online, Online, Online, Online, Online, Online,
          Online, Unknown), (Unknown, Fork, Fork, Fork,
          Fork, Fork, Fork, Fork, Fork, Fork, Fork,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight, Online,
          Online, Online, Online, Online, Online, Online,
          Online, Online, Online, Unknown), (Unknown,
          Fork, Fork, Fork, Fork, Fork, Fork, Fork, Fork,
          Fork, Fork, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, Online, Online, Online, Online,
          Online, Online, Online, Online, Online, Online,
          Unknown), (Unknown, Fork, Fork, Fork, Fork,
          Fork, Fork, Fork, Fork, Fork, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, Online, Online, Online, Online,
          Online, Online, Online, Online, Online,
          Unknown), (Unknown, Fork, Fork, Fork, Fork,
          Fork, Fork, Fork, Fork, Fork, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, Online, Online, Online, Online,
          Online, Online, Online, Online, Online,
          Unknown), (Unknown, Fork, Fork, Fork, Fork,
          Fork, Fork, Fork, Fork, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight, Online,
          Online, Online, Online, Online, Online, Online,
          Online, Unknown), (Unknown, Fork, Fork, Fork,
          Fork, Fork, Fork, Fork, Fork, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight,
          BranchRight, BranchRight, BranchRight, Online,
          Online, Online, Online, Online, Online, Online,
          Online, Unknown), (Unknown, Unknown, Unknown,
          Unknown, Unknown, Unknown, Unknown, Unknown,
          Unknown, Unknown, Unknown, Unknown, Unknown,
          Unknown, Unknown, Unknown, Unknown, Unknown,
          Unknown, Unknown, Unknown, Unknown, Unknown,
          Unknown, Unknown, Unknown, Unknown, Unknown,
          Unknown, Unknown, Unknown));

end Geo_Filter;
