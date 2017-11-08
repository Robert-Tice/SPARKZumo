package body Geo_Filter is

   procedure FilterState (State : in out LineState)
   is
      Current_Point : constant Point_Type := State2PointLookup (State);

      X_Sum, X_Avg  : Integer := 0;
      Y_Sum, Y_Avg  : Integer := 0;
   begin
      Window (Window_Index) := Current_Point;

      if Window_Index = Window_Type'Last then
         Window_Index := Window_Type'First;
      else
         Window_Index := Window_Index + 1;
      end if;

      for Item in Window'Range loop
         X_Sum := X_Sum + Window (Item).X;
         Y_Sum := Y_Sum + Window (Item).Y;
      end loop;

      X_Avg := X_Sum / Window'Length;
      Y_Avg := Y_Sum / Window'Length;

      State := AvgPoint2StateLookup (X_Avg, Y_Avg);

   end FilterState;

end Geo_Filter;
