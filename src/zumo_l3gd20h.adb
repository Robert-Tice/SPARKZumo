pragma SPARK_Mode;

with Wire; use Wire;
with Sparkduino; use Sparkduino;

package body Zumo_L3gd20h is

   Chip_Addr : constant := 2#0110_1011#;

   Chip_ID : constant := 2#1101_0111#;

   procedure Check_WHOAMI
   is
      ID : Byte;
   begin
      ID := Wire.Read_Byte (Addr => Chip_Addr,
                            Reg  => Regs'Enum_Rep (WHO_AM_I));

      if ID /= Chip_ID then
         Serial_Print_Byte (Msg => "Read invalid ID:",
                            Val => ID);
      end if;
   end Check_WHOAMI;

   procedure Init
   is
      Init_Seq   : Byte_Array := (Regs'Enum_Rep (CTRL1), 2#0001_1111#,
                                  Regs'Enum_Rep (CTRL2), 2#0000_0000#,
                                  Regs'Enum_Rep (CTRL3), 2#0000_0000#,
                                  Regs'Enum_Rep (CTRL4), 2#0011_0000#,
                                  Regs'Enum_Rep (CTRL5), 2#0000_0000#);
      Status     : Wire.Transmission_Status;
      Status_Pos : Integer;

      Index : Integer := Init_Seq'First;
   begin
      Check_WHOAMI;

      while Index <= Init_Seq'Last loop
         Status := Wire.Write_Byte (Addr => Chip_Addr,
                                    Reg  => Init_Seq (Index),
                                    Data => Init_Seq (Index + 1));

         Status_Pos := Wire.Transmission_Status'Enum_Rep (Status);

         if Status /= Wire.Success then
            Serial_Print ("L3GD20H Init failed with error: "
                          & Status_Pos'Img);
         end if;

         Index := Index + 2;
      end loop;
   end Init;

   function Read_Temp return Signed_Char
   is
      BB : Byte;
      Ret_Val : Signed_Char
        with Address => BB'Address;
   begin
      BB := Wire.Read_Byte (Addr => Chip_Addr,
                            Reg  => Regs'Enum_Rep (OUT_TEMP));
      return Ret_Val;
   end Read_Temp;

   function Read_Status return Byte
   is
   begin
      return Wire.Read_Byte (Addr => Chip_Addr,
                             Reg  => Regs'Enum_Rep (STATUS));
   end Read_Status;

   procedure Read_Gyro (Data : out Axis_Data)
   is
      Reg_Arr : constant array (1 .. 3) of Regs := (OUT_X_L,
                                                    OUT_Y_L,
                                                    OUT_Z_L);
   begin
      for I in Reg_Arr'Range loop
         declare
            Arr : Byte_Array (1 .. 2)
              with Address => Data (I)'Address;
         begin
            Wire.Read_Bytes (Addr => Chip_Addr,
                             Reg  => Regs'Enum_Rep (Reg_Arr (I)),
                             Data => Arr);
         end;
      end loop;
   end Read_Gyro;

end Zumo_L3gd20h;
