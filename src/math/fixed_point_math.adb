pragma SPARK_Mode;

package body Fixed_Point_Math is

   Pi  : constant := 3.141592;
   One : constant F := 1.0;

   function Reduce (X : F) return F;


   ---------
   -- Sin --
   ---------

   function Sin (X : F) return F
   Is
      X2 : constant F := X * X;
   begin
      if X < 0.0 then
         return -Sin (-X);

      elsif X < Pi / 4 then
         return F (X *  (One - F (X2 * (One / 6 -  F (X2 * (One / 120
                   - X2 / (120 * 6 * 7)))))));
      elsif X  < Pi / 2 then
         return Cos (Pi / 2 - X);
      else
         --  Bring value of X in safe range.
         return Sin (Reduce (X));
      end if;
   end Sin;

   ---------
   -- Cos --
   ---------

   function Cos (X : F) return F
   is
      X2 : constant F := X * X;
   begin
      if X < 0.0 then
         return Cos (-X);

      elsif X < Pi / 4 then
         return 1.0 - F (X2 / 2 * (One - F (X2 *  (F (One - X2 / 30) / 12))));

      elsif X < Pi / 2 then
         return Sin (Pi / 2 - X);
      else
         return Cos (Reduce (X));
      end if;

   end Cos;

   ----------
   -- Sqrt --
   ----------

--     function Sqrt (X : F) return F
--     is
--        Accuracy : constant := F'Delta;
--        Lo, Hi, Guess : F;
--     begin
--        if X < 0.0 then
--           return Sqrt (-X);
--        end if;
--
--        if X < One then
--           Lo := X;
--           Hi := One;
--        else
--           Lo := One;
--           Hi := X;
--        end if;
--
--        while Hi - Lo > 2.0 * Accuracy loop
--           Guess := (Lo + Hi) / 2.0;
--           if Guess * Guess > X then
--              Hi := Guess;
--           else
--              Lo := Guess;
--           end if;
--        end loop;
--        return (Lo + Hi) / 2.0;
--     end Sqrt;

   ------------
   -- Reduce --
   ------------

   function Reduce (X : F) return F
   is
      Excess : F := X;
   begin
      while abs Excess > Pi / 2 loop
         Excess := Excess - Pi / 2;
      end loop;
      if X > 0.0 then
         return Excess;
      else
         return -Excess;
      end if;
   end Reduce;


end Fixed_Point_Math;
