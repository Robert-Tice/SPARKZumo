pragma SPARK_Mode;

with Zumo_LSM303;
with Zumo_L3gd20h;
with Wire;

with Types; use Types;
with Sparkduino; use Sparkduino;

with Interfaces.C; use Interfaces.C;

with Ada.Numerics; use Ada.Numerics;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Zumo_Motion is

   Last_Time : Unsigned_Long;
   Update_Rate : constant := 20;

   R           : Float;
   P           : Float;
   Y           : Float;

   type Fl_Axis is array (Axises) of Float;

   Gyr_Offsets : Fl_Axis;
   Acc_Offsets : Fl_Axis;



   function ToRad (X : Float) return Float is
     (X * PI / 180.0);
   function ToDeg (X : Float) return Float is
     (X * 180.0 / PI);

   function Gyro_Scale (X : Short) return Float is
     (Float (X) * ToRad (Zumo_L3gd20h.Gain));


   procedure Calculate_RPY (G_Raw   : Axis_Data;
                            M_Raw   : Axis_Data;
                            A_Raw   : Axis_Data;
                            G_Temp  : Signed_Char;
                            AM_Temp : Short)
   is
      Phi, Theta, Psi : Float;
      G               : Fl_Axis;
      M               : Fl_Axis;
      A               : Fl_Axis;
   begin
      for I in G'Range loop
         A (I) := Float (A_Raw (I) - Acc_Offsets (I)) * Zumo_LSM303.A_Sensitivity;
         M (I) := Float (M_Raw (I)) * Zumo_LSM303.M_Sensitivity;
         G (I) := Gyro_Scale (G_Raw (I) - Gyr_Offsets (I));
      end loop;





   end Calculate_RPY;

   procedure Update_Data
   is
      Current_Time : Unsigned_Long := Millis;

      A_Status, M_Status, G_Status : Byte;

      G            : Axis_Data;
      G_Temp       : Signed_Char;

      M            : Axis_Data;
      A            : Axis_Data;
      AM_Temp      : Short;
   begin
      if Current_Time - Last_Time > Update_Rate then
         G_Status := Zumo_L3gd20h.Read_Status;
         M_Status := Zumo_LSM303.Read_M_Status;
         A_Status := Zumo_LSM303.Read_A_Status;

         if G_Status and 2#0000_10000# > 0 then
            Zumo_L3gd20h.Read_Gyro (Data => G);
            G_Temp := Zumo_L3gd20h.Read_Temp;
         end if;

         if M_Status and 2#0000_1000# > 0 then
            Zumo_LSM303.Read_Mag (Data => M);
            AM_Temp := Zumo_LSM303.Read_Temp;
         end if;

         if A_Status and 2#0000_1000# then
            Zumo_LSM303.Read_Acc (Data => A);
         end if;

         Calculate_RPY (G_Raw       => G,
                        M_Raw       => M,
                        A_Raw       => A,
                        G_Temp      => G_Temp,
                        AM_Temp     => AM_Temp);
      end if;

      Last_Time := Current_Time;

   end Update_Data;

   ----------
   -- Init --
   ----------

   procedure Init
   is
      G_Off : Axis_Data;
      A_Off : Axis_Data;

      Acc_Sum, Gyr_Sum : array (Axises) of Integer := (others => 0);

      Iters : constant := 32;
   begin
      Wire.Init_Master;
      Wire.SetClock (Freq => 400_000);

      Zumo_LSM303.Init;
      Zumo_L3gd20h.Init;


      for I in (1 .. Iters) loop
         Zumo_LSM303.Read_Acc (Data => A_Off);
         Zumo_L3gd20h.Read_Gyro (Data => G_Off);

         for J in A_Off'Range loop
            Acc_Sum (J) := Acc (J) + Integer (A_Off (J));
            Gyr_Sum (J) := Gyr (J) + Integer (G_Off (J));
         end loop;

         SysDelay (10);
      end loop;

      for I in Acc_Sum'Range loop
         Acc_Offsets (I) := Short (Acc_Sum (I) / 32);
         Gyr_Offsets (I) := Short (Gyr_Sum (I) / 32);
      end loop;

   end Init;



   ------------------
   -- Get_Position --
   ------------------

   procedure Get_Position
     (Roll  : out Degrees;
      Pitch : out Degrees;
      Yaw   : out Degrees)
   is
   begin
      Update_Data;
      Roll := R;
      Pitch := P;
      Yaw := Y;
   end Get_Position;

   -----------------
   -- Get_Heading --
   -----------------

   function Get_Heading return Degrees is
   begin
      --  Generated stub: replace with real body!
      pragma Compile_Time_Warning (Standard.True, "Get_Heading unimplemented");
      return raise Program_Error with "Unimplemented function Get_Heading";
   end Get_Heading;

end Zumo_Motion;
