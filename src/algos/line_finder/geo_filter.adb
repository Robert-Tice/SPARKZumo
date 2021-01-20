pragma SPARK_Mode;

package body Geo_Filter is

   procedure FilterState (State  : in out LineState;
                          Thresh : out Boolean)
   is
      Current_Point : constant Point_Type := State2PointLookup (State);

      X_Sum, Y_Sum  : Integer := 0;
      X_Avg, Y_Avg  : Integer;
   begin

      case State is
         when Unknown =>
            Thresh := True;

         when others =>
            Window (Window_Index) := Current_Point;

            if Window_Index = Window_Type'Last then
               Window_Index := Window_Type'First;
            else
               Window_Index := Window_Index + 1;
            end if;

            for Item of Window loop
               X_Sum := X_Sum + Item.X;
               Y_Sum := Y_Sum + Item.Y;
            end loop;

            X_Avg := X_Sum / Window'Length;
            Y_Avg := Y_Sum / Window'Length;

            State := AvgPoint2StateLookup (X_Avg, Y_Avg);

            Thresh := (Radii_Length (X => X_Avg,
                                     Y => Y_Avg) > Radii_Threshold);
      end case;

   end FilterState;

   function Radii_Length (X : Integer;
                          Y : Integer)
                          return Integer
   is
      N : constant Integer := (X * X) + (Y * Y);
      A : Integer := N;
      B : Integer := (A + 1) / 2;
   begin
      while B < A loop
         A := B;
         B := (A + N / A) / 2;
      end loop;

      return A;
   end Radii_Length;

end Geo_Filter;
