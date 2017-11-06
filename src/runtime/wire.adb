pragma SPARK_Mode;

with Sparkduino; use Sparkduino;
with Interfaces.C; use Interfaces.C;

package body Wire is

   Timeout : constant unsigned_long := 1;

   function RequestFrom (Addr  : Byte;
                         Quant : Byte;
                         Stop  : Boolean)
                         return Byte
   is
      CB : Byte := 0;
   begin
      if Stop then
         CB := 1;
      end if;

      return RequestFrom_C (Addr  => Addr,
                            Quant => Integer (Quant),
                            Stop  => CB);
   end RequestFrom;

   function EndTransmission (Stop : Boolean) return Byte
   is
      CB : Byte := 0;
   begin
      if Stop then
         CB := 1;
      end if;

      return EndTransmission_C (Stop => CB);
   end EndTransmission;

   function Byte2TSI (BB : Byte)
                      return Transmission_Status_Index
   is
   begin
      for I in Transmission_Status_Index loop
         if Transmission_Status (I) = BB then
            return I;
         end if;
      end loop;

      return Other_Err;
   end Byte2TSI;

   function Read_Byte (Addr : Byte;
                       Reg  : Byte)
                       return Byte
   is
      Ret_Val : Byte;
      Bytes_Read : Byte;

      Bytes_Written : Byte;
      Status : Transmission_Status_Index;
   begin
      Wire.BeginTransmission (Addr => Addr);
      Bytes_Written := Wire.Write_Value (Val => Reg);
      Status := Byte2TSI (BB => Wire.EndTransmission (Stop => True));

      if Status /= Wire.Success or Bytes_Written /= 1 then
         return Byte'First;
      end if;

      Bytes_Read := RequestFrom (Addr  => Addr,
                                 Quant => 1,
                                 Stop  => True);
      if Bytes_Read /= 1 then
         return Byte'First;
      end if;

      Ret_Val := Wire.Read;

      return Ret_Val;
   end Read_Byte;

   procedure Read_Bytes (Addr : Byte;
                         Reg : Byte;
                         Data : out Byte_Array)
   is
      Bytes_Read : Byte;

      Bytes_Written : Byte;
      Status     : Transmission_Status_Index;

      Start_Time : unsigned_long;
   begin
      Wire.BeginTransmission (Addr => Addr);
      Bytes_Written := Wire.Write_Value (Val => (Reg or 16#80#));
      Status := Byte2TSI (BB => Wire.EndTransmission (Stop => True));

      if Status /= Wire.Success or Bytes_Written /= 1 then
         Data := (others => Byte'First);
         return;
      end if;

      Bytes_Read := RequestFrom (Addr  => Addr,
                                 Quant => Data'Length,
                                 Stop  => True);

      if Bytes_Read /= Data'Length or Bytes_Read = 0 then
         Data := (others => Byte'First);
         return;
      end if;

      Start_Time := Millis;

      while Wire.Available < Data'Length loop
         if Millis - Start_Time > Timeout then
            Data := (others => Byte'First);
            return;
         end if;
      end loop;

      for I in Data'First .. Data'Last loop
         Data (I) := Wire.Read;
         pragma Annotate (GNATprove,
                          False_Positive,
                          """Data"" might not be initialized",
                          String'("Data properly initialized by this loop"));
      end loop;
   end Read_Bytes;

   function Write_Byte (Addr : Byte;
                        Reg  : Byte;
                        Data : Byte)
                        return Transmission_Status_Index
   is
      Bytes_Written : Byte;
   begin
      BeginTransmission (Addr => Addr);

      Bytes_Written := Write_Value (Val => Reg);
      if Bytes_Written /= 1 then
         return Other_Err;
      end if;

      Bytes_Written := Write_Value (Val => Data);

      if Bytes_Written /= 1 then
         return Other_Err;
      end if;

      return Byte2TSI (BB => EndTransmission (Stop => True));
   end Write_Byte;

end Wire;
