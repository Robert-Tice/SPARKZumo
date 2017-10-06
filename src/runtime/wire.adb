pragma SPARK_Mode;

with Sparkduino; use Sparkduino;
with Interfaces.C; use Interfaces.C;

package body Wire is

   Timeout : constant Unsigned_Long := 1;

   function Read_Byte (Addr : Byte;
                       Reg  : Byte)
                       return Byte
   is
      Ret_Val : Byte := 0;
      Bytes_Read : Byte;

      Bytes_Written : Byte;
      Status : Transmission_Status;
   begin
      Wire.BeginTransmission (Addr => Addr);
      Bytes_Written := Wire.Write_Value (Val => Reg);
      Status := Transmission_Status'Val(Wire.EndTransmission (Stop => True));

      if Status /= Wire.Success or Bytes_Written /= 1 then
         Serial_Print ("Could not set register for read");
         return 0;
      end if;

      Bytes_Read := RequestFrom (Addr  => Addr,
                                 Quant => 1,
                                 Stop  => True);
      if Bytes_Read /= 1 then
         Serial_Print ("Could not read bytes from target. Bytes Read: "
                       & Bytes_Read'Img);
         return 0;
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
      Status     : Transmission_Status;

      Start_Time : Unsigned_Long;
   begin
      Wire.BeginTransmission (Addr => Addr);
      Bytes_Written := Wire.Write_Value (Val => (Reg or 16#80#));
      Status := Transmission_Status'Val(Wire.EndTransmission (Stop => True));

      if Status /= Wire.Success or Bytes_Written /= 1 then
         Serial_Print ("Could not set register for read");
         Data := (others => Byte'Last);
         return;
      end if;

      Bytes_Read := RequestFrom (Addr  => Addr,
                                 Quant => Data'Length,
                                 Stop  => True);

      if Bytes_Read /= Data'Length then
         Serial_Print ("Bad requestfrom: " & Bytes_Read'Img);
         Data := (others => Byte'Last);
         return;
      end if;

      Start_Time := Millis;

      while Wire.Available < Data'Length loop
         if Millis - Start_Time > Timeout then
            Serial_Print ("Read Timeout!");
            Data := (others => Byte'Last);
            return;
         end if;
      end loop;

      for I in Data'Range loop
         Data (I) := Wire.Read;
      end loop;
   end Read_Bytes;


   function Write_Byte (Addr : Byte;
                        Reg  : Byte;
                        Data : Byte)
                        return Transmission_Status
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

      return Transmission_Status'Val (EndTransmission (Stop => True));
   end Write_Byte;

   function Write_Bytes (Addr : Byte;
                         Data : Byte_Array)
                         return Transmission_Status
   is
      Bytes_Written : Byte;

   begin
      BeginTransmission (Addr => Addr);

      for I in Data'Range loop
         Bytes_Written := Write_Value (Val => Data (I));
         if Bytes_Written /= 1 then
            return Other_Err;
         end if;
      end loop;

      return Transmission_Status'Val (EndTransmission (Stop => True));
   end Write_Bytes;

   function RequestFrom (Addr  : Byte;
                         Quant : Integer;
                         Stop  : Boolean)
                         return Byte
   is
      CB : Byte := 0;
   begin
      if Stop then
         CB := 1;
      end if;

      return RequestFrom_C (Addr  => Addr,
                            Quant => Quant,
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


end Wire;
