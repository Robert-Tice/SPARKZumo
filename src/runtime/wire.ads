pragma SPARK_Mode;

with Types; use Types;

with Interfaces; use Interfaces;

package Wire is

   type Transmission_Status_Index is
     (Success, Data_Too_Long, Rx_NACK_Addr, Rx_NACK_Data, Other_Err);

   Transmission_Status : array (Transmission_Status_Index) of Byte :=
                           (Success       => 0,
                            Data_Too_Long => 1,
                            Rx_NACK_Addr  => 2,
                            Rx_NACK_Data  => 3,
                            Other_Err     => 4);

   function Byte2TSI (BB : Byte)
                      return Transmission_Status_Index;

   procedure Init_Master
     with Global => null;
   pragma Import (C, Init_Master, "Wire_Begin_Master");

   procedure Init_Slave (Addr : Byte)
     with Global => null;
   pragma Import (C, Init_Slave, "Wire_Begin_Slave");

   procedure SetClock (Freq : Unsigned_32)
     with Global => null;
   pragma Import (C, SetClock, "Wire_SetClock");

   function Read_Byte (Addr : Byte;
                       Reg  : Byte)
                       return Byte;

   procedure Read_Bytes (Addr : Byte;
                         Reg  : Byte;
                         Data : out Byte_Array)
     with Global => Transmission_Status,
     Pre => (Data'Length > 0);
   pragma Annotate (GNATprove,
                    False_Positive,
                    """Data"" might not be initialized",
                    String'("Data is properly initialized by this loop"));

   function Write_Byte (Addr : Byte;
                        Reg  : Byte;
                        Data : Byte)
                        return Transmission_Status_Index;

   Wire_Exception : exception;

private

   function RequestFrom (Addr  : Byte;
                         Quant : Byte;
                         Stop  : Boolean)
                         return Byte;

   function RequestFrom_C (Addr  : Byte;
                           Quant : Integer;
                           Stop  : Byte)
                           return Byte
     with Global => null;
   pragma Import (C, RequestFrom_C, "Wire_RequestFrom");

   procedure BeginTransmission (Addr : Byte)
     with Global => null;
   pragma Import (C, BeginTransmission, "Wire_BeginTransmission");

   function EndTransmission (Stop : Boolean) return Byte;

   function EndTransmission_C (Stop : Byte) return Byte
     with Global => null;
   pragma Import (C, EndTransmission_C, "Wire_EndTransmission");

   function Write_Value (Val : Byte) return Byte
     with Global => null;
   pragma Import (C, Write_Value, "Wire_Write_Value");

   function Available return Integer
     with Global => null;
   pragma Import (C, Available, "Wire_Available");

   function Read return Byte
     with Global => null;
   pragma Import (C, Read, "Wire_Read");

end Wire;
