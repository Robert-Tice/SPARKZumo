pragma SPARK_Mode;

with Wire; use Wire;

with Interfaces; use Interfaces;

package body Zumo_LSM303 is

   LM_Addr : constant := 2#0001_1101#;  -- 16#1D# 10#29#

   LM_ID   : constant := 2#0100_1001#;  -- 16#49# 10#73#

   procedure Check_WHOAMI
   is
      ID : Byte;
   begin
      ID := Wire.Read_Byte (Addr => LM_Addr,
                            Reg  => Regs (WHO_AM_I));
      if ID /= LM_ID then
         raise LSM303_Exception;
      end if;
   end Check_WHOAMI;

   procedure Init
   is
      Init_Seq   : constant Byte_Array := (Regs (CTRL0), 2#0000_0000#,
                                           Regs (CTRL1), 2#0101_0111#,
                                           Regs (CTRL2), 2#0000_0000#,
                                           Regs (CTRL3), 2#0000_0000#,
                                           Regs (CTRL4), 2#0000_0000#,
                                           Regs (CTRL5), 2#1110_0100#,
                                           Regs (CTRL6), 2#0010_0000#,
                                           Regs (CTRL7), 2#0000_0000#);
      Status     : Wire.Transmission_Status_Index;
      Index : Integer := Init_Seq'First;
   begin
      Check_WHOAMI;

      while Index <= Init_Seq'Last loop
         Status := Wire.Write_Byte (Addr => LM_Addr,
                                    Reg  => Init_Seq (Index),
                                    Data => Init_Seq (Index + 1));

         if Status /= Wire.Success then
            raise LSM303_Exception;
         end if;

         Index := Index + 2;
      end loop;

      Initd := True;

   end Init;

   function Read_M_Status return Byte
   is
   begin
      return Wire.Read_Byte (Addr => LM_Addr,
                             Reg  => Regs (STATUS_M));
   end Read_M_Status;

   function Read_A_Status return Byte
   is
   begin
      return Wire.Read_Byte (Addr => LM_Addr,
                             Reg  => Regs (STATUS_A));
   end Read_A_Status;

   procedure Read_Mag (Data : out Axis_Data)
   is
      Reg_Arr : constant array (Axises) of Reg_Index := (OUT_X_L_M,
                                                         OUT_Y_L_M,
                                                         OUT_Z_L_M);
      Arr     : Byte_Array (1 .. 2);
   begin
      for I in Reg_Arr'Range loop
         Read_Bytes (Addr => LM_Addr,
                     Reg  => Regs (Reg_Arr (I)),
                     Data => Arr);
         declare
            Val : Unsigned_16
              with Address => Data (I)'Address;
         begin

            Val := Shift_Left (Value  => Unsigned_16 (Arr (2)),
                            Amount => 8);
            Val := Val or Unsigned_16 (Arr (1));
         end;
      end loop;
   end Read_Mag;

   procedure Read_Acc (Data : out Axis_Data)
   is
      Raw_Arr : Byte_Array (1 .. Data'Length * 2)
        with Address => Data'Address;
   begin
      Wire.Read_Bytes (Addr => LM_Addr,
                       Reg  => Regs (OUT_X_L_A),
                       Data => Raw_Arr);
   end Read_Acc;

   function Read_Temp return short
   is
      Arr     : Byte_Array (1 .. 2) := (others => 0);

      Sign_Bit : constant Byte := 2#0000_1000#;
      Ret_Val  : short
        with Address => Arr'Address;
   begin
      Wire.Read_Bytes (Addr => LM_Addr,
                       Reg  => Regs (TEMP_OUT_L),
                       Data => Arr);

      if (Arr (Arr'Last) and Sign_Bit) > 0 then
         Arr (Arr'Last) := Arr (Arr'Last) or 2#1111_0000#;
      else
         Arr (Arr'Last) := Arr (Arr'Last) and 2#0000_0111#;
      end if;

      return Ret_Val;

   end Read_Temp;

end Zumo_LSM303;
