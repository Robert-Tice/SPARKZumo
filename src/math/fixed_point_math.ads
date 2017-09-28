pragma SPARK_Mode;

generic
   type F is delta <>;
package Fixed_Point_Math is
   function Sin (X : F) return F;
   function Cos (X : F) return F;
--   function Sqrt (X : F) return F
--     with Pre => X >= 0.0;   

end Fixed_Point_Math;
