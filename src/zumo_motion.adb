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

   type Motion_Type is new Motion_Type;

   function ToRad (X : Motion_Type) return Motion_Type is
     (X * PI / 180.0);
   function ToDeg (X : Motion_Type) return Motion_Type is
     (X * 180.0 / PI);

   Gyr_DeltaT : constant := (1 / 50);
   Acc_DeltaT : constant = (1 / 50);

   Gyr_Meas_Err : constant := ToRad (25);
   Gyr_Meas_Drift : constant := ToRad (0.011);

   Beta : constant := Sqrt (3.0 / 4.0) * Gyr_Meas_Err;
   Zeta : constant := Sqrt (3.0 / 4.0) * Gyr_Meas_Drift;

   SEq : array (1 .. 4) of Motion_Type := (1 => 1.0,
                                           others => 0.0);

   B_X                 : Motion_Type := 1.0;
   B_Z                 : Motion_Type := 0.0;

   W_B : array (Axises) of Motion_Type := (others => 0.0);


   type Fl_Axis is array (Axises) of Motion_Type;

   Gyr_Offsets : Fl_Axis;
   Acc_Offsets : Fl_Axis;




   function Gyro_Scale (X : Short) return Motion_Type is
     (Motion_Type (X) * ToRad (Zumo_L3gd20h.Gain));


   procedure Calculate_RPY (G_Raw   : Axis_Data;
                            M_Raw   : Axis_Data;
                            A_Raw   : Axis_Data;
                            G_Temp  : Signed_Char;
                            AM_Temp : Short)
   is
      Norm : Motion_Type;
      SEqDot_Omega : array (1 .. 4) of Motion_Type;
      F            : array (1 .. 6) of Motion_Type;
      J            : array (1 .. 18) of Motion_Type;
      SEqHatDot    : array (1 .. 4) of Motion_Type;
      W_Err        : Fl_Axis;
      H            : Fl_Axis;

      A            : Fl_Axis;
      W            : Fl_Axis;
      M            : Fl_Axis;

      -- constants to avoid repeat math
      HalfSEq      : array (1 .. 4) of Motion_Type := (1 => 0.5 * SEq (1),
                                                       2 => 0.5 * SEq (2),
                                                       3 => 0.5 * SEq (3),
                                                       4 => 0.5 * SEq (4));
      TwoSEq       : array (1 .. 4) of Motion_Type := (1 => 2.0 * SEq (1),
                                                       2 => 2.0 * SEq (2),
                                                       3 => 2.0 * SEq (3),
                                                       4 => 2.0 * SEq (4));
      TwoB_X       : Motion_Type := 2.0 * B_X;
      TwoB_Z       : Motion_Type := 2.0 * B_Z;

      TwoB_XSEq    : array (1 .. 4) of Motion_Type := (1 => 2.0 * B_X * SEq (1),
                                                       2 => 2.0 * B_X * SEq (2),
                                                       3 => 2.0 * B_X * SEq (3),
                                                       4 => 2.0 * B_X * SEq (4));

      TwoB_ZSEq    : array (1 .. 4) of Motion_Type := (1 => 2.0 * B_Z * SEq (1),
                                                       2 => 2.0 * B_Z * SEq (2),
                                                       3 => 2.0 * B_Z * SEq (3),
                                                       4 => 2.0 * B_Z * SEq (4));
      SEq1x3       : Motion_Type := SEq (1) * SEq (3);
      Seq2x4       : Motion_Type := SEq (2) * SEq (4);

   begin
      -- scale readings into correct units
      for I in G'Range loop
         A (I) := Motion_Type (A_Raw (I) - Acc_Offsets (I)) * Zumo_LSM303.A_Sensitivity;
         M (I) := Motion_Type (M_Raw (I)) * Zumo_LSM303.M_Sensitivity;
         W (I) := Gyro_Scale (G_Raw (I));
      end loop;

      -- normalize acc measurements
      Norm := Sqrt (A (X) * A (X) + A (Y) * A (Y) + A (Z) * A (Z));
      A (X) := A (X) / Norm;
      A (Y) := A (Y) / Norm;
      A (Z) := A (Z) / Norm;

      -- normalize mag measurements
      Norm := Sqrt (M (X) * M (X) + M (Y) * M (Y) + M (Z) * M (Z));
      M (X) := M (X) / Norm;
      M (Y) := M (Y) / Norm;
      M (Z) := M (Z) / Norm;

      -- compute objective function and jacobian
      F (1) := TwoSEq (2) * SEq (4) - TwoSEq (1) * SEq (3) - A (X);
      F (2) := TwoSEq (1) * SEq (2) + TwoSEq (3) * SEq (4) - A (Y);
      F (3) := 1.0 - TwoSEq (2) * SEq (2) - TwoSEq (3) * SEq (3) - A (Z);
      F (4) := TwoB_X * (0.5 - SEq (3) * SEq (3) - SEq (4) * SEq (4)) + TwoB_Z * (SEq2x4 - SEq1x3) - M (X);
      F (5) := TwoB_X * (SEq (2) * SEq (3) - SEq (1) * SEq (4)) + TwoB_Z * (SEq (1) * SEq (2) + SEq (3) * SEq (4)) - M (Y);
      F (6) := TwoB_X * (SEq1x3 + Seq2x4) + TwoB_Z * (0.5 - SEq (2) * SEq (2) - SEq (3) * SEq (3)) - M (Z);





   end Calculate_RPY;

   procedure Update_Data
   is
      A_Status, M_Status, G_Status : Byte;

      G            : Fifo_Axis_Data;
      G_Temp       : Signed_Char;

      M            : Axis_Data;
      A            : Fifo_Axis_Data;
      AM_Temp      : Short;
   begin

      if Zumo_LSM303.Acc_FIFO_Rdy and Zumo_L3gd20h.FIFO_Rdy then
         Zumo_L3gd20h.Read_Gyro (Data => G);
         Zumo_LSM303.Read_Acc (Data => A);
         Zumo_LSM303.Read_Mag (Data => M);

         Calculate_RPY
      end if;

   end Update_Data;

   ----------
   -- Init --
   ----------

   procedure Init
   is
      G_Off : Fifo_Axis_Data;
      A_Off : Fifo_Axis_Data;

      Acc_Sum, Gyr_Sum : array (Axises) of Integer := (others => 0);
   begin
      Wire.Init_Master;
      Wire.SetClock (Freq => 400_000);

      Zumo_LSM303.Init;
      Zumo_L3gd20h.Init;

      while not (Zumo_L3gd20h.FIFO_Rdy and Zumo_LSM303.Acc_FIFO_Rdy) loop;
         null;
      end loop;

      Zumo_L3gd20h.Read_Gyro (Data => G_Off);
      Zumo_LSM303.Read_Acc (Data => A_Off);


      for I in G_Off'Range loop
         for J in A_Off'Range loop
            Acc_Sum (J) := Acc_Sum (J) + Integer (A_Off (I)(J));
            Gyr_Sum (J) := Gyr_Sum (J) + Integer (G_Off (I)(J));
         end loop;
      end loop;

      for I in Acc_Sum'Range loop
         Acc_Offsets (I) := Short (Acc_Sum (I) / A_Off'Length);
         Gyr_Offsets (I) := Short (Gyr_Sum (I) / G_Off'Length);
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
