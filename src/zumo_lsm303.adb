pragma SPARK_Mode;

with Wire; use Wire;
with Sparkduino; use Sparkduino;

with Interfaces; use Interfaces;
with Interfaces.C; use Interfaces.C;

package body Zumo_LSM303 is

   LM_Addr : constant := 2#0001_1101#;  -- 16#1D# 10#29#

   LM_ID   : constant := 2#0100_1001#;  -- 16#49# 10#73#

   procedure Check_WHOAMI
   is
      ID : Byte;
   begin
      ID := Wire.Read_Byte (Addr => LM_Addr,
                            Reg  => Regs'Enum_Rep (WHO_AM_I));
      if ID /= LM_ID then
         Serial_Print ("Read invalid ID: " & ID'Img);
      else
         Serial_Print ("Found device ID: " & ID'Img);
      end if;
   end Check_WHOAMI;

   procedure Init
   is
      Init_Seq   : Byte_Array := (Regs'Enum_Rep (CTRL0), 2#0000_0000#,
                                  Regs'Enum_Rep (CTRL1), 2#0101_0111#, -- 50Hz ODR, En X,Y,Z
                                  Regs'Enum_Rep (CTRL2), 2#0000_0000#,
                                  Regs'Enum_Rep (CTRL3), 2#0000_0000#,
                                  Regs'Enum_Rep (CTRL4), 2#0000_0000#,
                                  Regs'Enum_Rep (CTRL5), 2#1110_0100#, -- Temp EN, High Mag Res, 6.25Hz Mag ODR,
                                  Regs'Enum_Rep (CTRL6), 2#0010_0000#, -- +4 gauss
                                  Regs'Enum_Rep (CTRL7), 2#0000_0000#);
      Status     : Wire.Transmission_Status;
      Status_Pos : Integer;
   begin
      Wire.Init_Master;
      Wire.SetClock (Freq => 400_000);

      Check_WHOAMI;

      Status := Wire.Write_Bytes (Addr => LM_Addr,
                                  Data => Init_Seq);

      Status_Pos := Wire.Transmission_Status'Enum_Rep (Status);

      if Status /= Wire.Success then
         Serial_Print ("LSM303 Init failed with error: "
                       & Status_Pos'Img);
      end if;
   end Init;

   function Read_M_Status return Byte
   is
   begin
      return Wire.Read_Byte (Addr => LM_Addr,
                             Reg  => Regs'Enum_Rep (STATUS_M));
   end Read_M_Status;

   function Read_A_Status return Byte
   is
   begin
      return Wire.Read_Byte (Addr => LM_Addr,
                             Reg  => Regs'Enum_Rep (STATUS_A));
   end Read_A_Status;

   procedure Read_Mag (Data : out Axis_Data)
   is
      Reg_Arr : constant array (1 .. 3) of Regs := (OUT_X_L_M,
                                                    OUT_Y_L_M,
                                                    OUT_Z_L_M);
      Arr     : Byte_Array (1 .. 2);
      Val     : Unsigned_16;
   begin
      for I in Reg_Arr'Range loop
         Read_Bytes (Addr => LM_Addr,
                     Reg  => Regs'Enum_Rep (Reg_Arr (I)),
                     Data => Arr);
         Val := Shift_Left (Value  => Unsigned_16 (Arr (2)),
                            Amount => 8);
         Val := Val or Unsigned_16 (Arr (1));
         Data (I) := Short (Val);
      end loop;
   end Read_Mag;

   procedure Read_Acc (Data : out Axis_Data)
   is
      Reg_Arr : constant array (1 .. 3) of Regs := (OUT_X_L_A,
                                                    OUT_Y_L_A,
                                                    OUT_Z_L_A);
      Arr     : Byte_Array (1 .. 2);
   begin
      for I in Reg_Arr'Range loop
         Read_Bytes (Addr => LM_Addr,
                     Reg  => Regs'Enum_Rep (Reg_Arr (I)),
                     Data => Arr);
         Data (I) := Short (Shift_Left (Value  => Unsigned_16 (Arr (2)),
                                        Amount => 8)
                            or Unsigned_16 (Arr (1)));
      end loop;
   end Read_Acc;


   function Read_Temp return Integer
   is
      Arr     : Byte_Array (1 .. 2);
      Sign    : Integer := 1;

      Sign_Bit : constant Byte := 2#0000_1000#;
      Ret_Val : Integer;
   begin
      Wire.Read_Bytes (Addr => LM_Addr,
                       Reg  => Regs'Enum_Rep (TEMP_OUT_L),
                       Data => Arr);

      Ret_Val := Integer (Shift_Left (Value  => Unsigned_16 (Arr (2)),
                                      Amount => 8) or
                            Unsigned_16 (Arr (1)));

      if (Arr (Arr'Last) and Sign_Bit) > 0 then
         Ret_Val := Ret_Val * (-1);
      end if;

      return Ret_Val;

   end Read_Temp;



end Zumo_LSM303;
