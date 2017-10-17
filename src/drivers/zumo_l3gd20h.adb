--  pragma SPARK_Mode;

with Wire; use Wire;

package body Zumo_L3gd20h is

   Chip_Addr : constant := 2#0110_1011#;

   Chip_ID : constant := 2#1101_0111#;

   procedure Check_WHOAMI
   is
      ID : Byte;
   begin
      ID := Wire.Read_Byte (Addr => Chip_Addr,
                            Reg  => Regs (WHO_AM_I));

      if ID /= Chip_ID then
         raise L3GD20H_Exception;
      end if;
   end Check_WHOAMI;

   procedure Init
   is
      Init_Seq   : constant Byte_Array := (Regs (CTRL1), 2#1001_1111#,
                                           Regs (CTRL2), 2#0000_0000#,
                                           Regs (CTRL3), 2#0000_0000#,
                                           Regs (CTRL4), 2#0011_0000#,
                                           Regs (CTRL5), 2#0000_0000#,
                                           Regs (LOW_ODR), 2#0000_0001#);
      Status     : Wire.Transmission_Status_Index;

      Index : Byte := Init_Seq'First;
   begin
      Check_WHOAMI;

      while Index <= Init_Seq'Last loop
         Status := Wire.Write_Byte (Addr => Chip_Addr,
                                    Reg  => Init_Seq (Index),
                                    Data => Init_Seq (Index + 1));

         if Status /= Wire.Success then
            raise L3GD20H_Exception;
         end if;

         Index := Index + 2;
      end loop;

      Initd := True;
   end Init;

   function Read_Temp return signed_char
   is
      BB : Byte := 0;
      Ret_Val : signed_char
        with Address => BB'Address;
   begin
      BB := Wire.Read_Byte (Addr => Chip_Addr,
                            Reg  => Regs (OUT_TEMP));
      return Ret_Val;
   end Read_Temp;

   function Read_Status return Byte
   is
   begin
      return Wire.Read_Byte (Addr => Chip_Addr,
                             Reg  => Regs (STATUS));
   end Read_Status;

   procedure Read_Gyro (Data : out Axis_Data)
   is
      Raw_Arr : Byte_Array (1 .. Data'Length * 2)
        with Address => Data'Address;
   begin
      Wire.Read_Bytes (Addr => Chip_Addr,
                       Reg  => Regs (OUT_X_L),
                       Data => Raw_Arr);
   end Read_Gyro;

end Zumo_L3gd20h;
