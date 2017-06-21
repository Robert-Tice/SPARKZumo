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
   
   function Write_Bytes (Addr : Byte;
                         Data : in Byte_Array)
                         return Transmission_Status;
   
private
                   
   function RequestFrom (Addr  : Byte;
                         Quant : Integer;
                         Stop  : Boolean)
                         return Byte;
   pragma Import (C, RequestFrom, "Wire_RequestFrom");
   
   procedure BeginTransmission (Addr : Byte);
   pragma Import (C, BeginTransmission, "Wire_BeginTransmission");
   
   function EndTransmission (Stop : Boolean) return Byte;
   pragma Import (C, EndTransmission, "Wire_EndTransmission");
   
   function Write_Value (Val : Byte) return Byte;
   pragma Import (C, Write_Value, "Wire_Write_Value");
    
   function Write_Array (Addr   : System.Address;
                         Length : Integer) 
                         return Byte;
   pragma Import (C, Write_Array, "Wire_Write_Array");
   
   function Available return Integer;
   pragma Import (C, Available, "Wire_Available");
   
   function Read return Byte;
   pragma Import (C, Read, "Wire_Read");
  

end Wire;
