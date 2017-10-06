pragma SPARK_Mode;

with Types; use Types;

with System;
with Interfaces; use Interfaces;

package Wire is
   
   type Transmission_Status is
     (Success, Data_Too_Long, Rx_NACK_Addr, Rx_NACK_Data, Other_Err);
   
   for Transmission_Status use
     (Success       => 0,
      Data_Too_Long => 1,
      Rx_NACK_Addr  => 2,
      Rx_NACK_Data  => 3,
      Other_Err     => 4);
   
   procedure Init_Master;
   pragma Import (C, Init_Master, "Wire_Begin_Master");
   
   procedure Init_Slave (Addr : Byte);
   pragma Import (C, Init_Slave, "Wire_Begin_Slave");
   
   procedure SetClock (Freq : Unsigned_32);
   pragma Import (C, SetClock, "Wire_SetClock");
   
   function Read_Byte (Addr : Byte;
                       Reg  : Byte)
                       return Byte;
   
   procedure Read_Bytes (Addr : Byte;
                         Reg  : Byte;
                         Data : out Byte_Array);
   
   function Write_Byte (Addr : Byte;
                        Reg  : Byte;
                        Data : Byte)
                        return Transmission_Status;
   
private
   
   function RequestFrom (Addr  : Byte;
                         Quant : Integer;
                         Stop  : Boolean)
                         return Byte;
                   
   function RequestFrom_C (Addr  : Byte;
                           Quant : Integer;
                           Stop  : Byte)
                           return Byte;
   pragma Import (C, RequestFrom_C, "Wire_RequestFrom");
   
   procedure BeginTransmission (Addr : Byte);
   pragma Import (C, BeginTransmission, "Wire_BeginTransmission");
   
   function EndTransmission (Stop : Boolean) return Byte;
   
   function EndTransmission_C (Stop : Byte) return Byte;
   pragma Import (C, EndTransmission_C, "Wire_EndTransmission");
   
   function Write_Value (Val : Byte) return Byte;
   pragma Import (C, Write_Value, "Wire_Write_Value");
   
   function Available return Integer;
   pragma Import (C, Available, "Wire_Available");
   
   function Read return Byte;
   pragma Import (C, Read, "Wire_Read");
  

end Wire;
