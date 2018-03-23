pragma SPARK_Mode;

with Types; use Types;

with Interfaces; use Interfaces;

--  @summary
--  Interface to Arduino Wire library
--
--  @description
--  Provides an interface to the Arudino Wire library. This is used for
--    I2C busses.
--

package Wire is

--  Return result of a transmission
--  @value Success success
--  @value Data_Too_Long data too long to fit in transmit buffer
--  @value Rx_NACK_Addr received NACK on transmit of address
--  @value Rx_NACK_Data received NACK on transmit of data
--  @value Other_Err other error
   type Transmission_Status_Index is
     (Success, Data_Too_Long, Rx_NACK_Addr, Rx_NACK_Data, Other_Err);

   Transmission_Status : array (Transmission_Status_Index) of Byte :=
                           (Success       => 0,
                            Data_Too_Long => 1,
                            Rx_NACK_Addr  => 2,
                            Rx_NACK_Data  => 3,
                            Other_Err     => 4);

   --  Translates a Byte to Transmission_Status_Index
   --  @param BB the byte to cast
   --  @return the Transmission_Status_Index corresponding to the value in BB
   function Byte2TSI (BB : Byte)
                      return Transmission_Status_Index;

   --  Initiate the Wire library and join the I2C bus as a master.
   procedure Init_Master
     with Global => null;
   pragma Import (C, Init_Master, "Wire_Begin_Master");

   --  Initiate the Wire library and join the I2C bus as a slave
   --  @param Addr the 7-bit slave address
   procedure Init_Slave (Addr : Byte)
     with Global => null;
   pragma Import (C, Init_Slave, "Wire_Begin_Slave");

   --  This function modifies the clock frequency for I2C communication.
   --  @param Freq the value (in Hertz) of desired communication clock
   procedure SetClock (Freq : Unsigned_32)
     with Global => null;
   pragma Import (C, SetClock, "Wire_SetClock");

   --  Read a byte from the Reg register on the device at Addr
   --  @param Addr the address of the device to access
   --  @param Reg the register to access on the device
   --  @return the Byte read from the device
   function Read_Byte (Addr : Byte;
                       Reg  : Byte)
                       return Byte;

   --  Read multiple bytes from the device at Addr start at register Reg
   --  @param Addr the address of the device to access
   --  @param Reg the starting register to access on the device
   --  @param Data an array of Bytes read from the registers
   procedure Read_Bytes (Addr : Byte;
                         Reg  : Byte;
                         Data : out Byte_Array)
     with Global => Transmission_Status,
     Pre => (Data'Length > 0);
   pragma Annotate (GNATprove,
                    False_Positive,
                    """Data"" might not be initialized",
                    String'("Data is properly initialized by this loop"));

   --  Write a byte to the register Reg on the device at Addr
   --  @param Addr the address of the device to write to
   --  @param Reg the register to write to on the device
   --  @param Data the data to write to the device
   --  @return the status of the write transaction
   function Write_Byte (Addr : Byte;
                        Reg  : Byte;
                        Data : Byte)
                        return Transmission_Status_Index;

private

   --  Used by the master to request bytes from a slave device.
   --    Ada wrapper around imported RequestFrom_C
   --  @param Addr the 7-bit address of the device to request bytes from
   --  @param Quant the number of bytes to request
   --  @param Stop true will send a stop message after the request, releasing
   --    the bus. false will continually send a restart after the request,
   --    keeping the connection active.
   --  @return the number of bytes returned from the slave device
   function RequestFrom (Addr  : Byte;
                         Quant : Byte;
                         Stop  : Boolean)
                         return Byte;

   --  See documentation for RequestFrom
   function RequestFrom_C (Addr  : Byte;
                           Quant : Byte;
                           Stop  : Byte)
                           return Byte
     with Global => null;
   pragma Import (C, RequestFrom_C, "Wire_RequestFrom");

   --  Begin a transmission to the I2C slave device with the given address
   --  @param Addr the 7-bit address of the device to transmit to
   procedure BeginTransmission (Addr : Byte)
     with Global => null;
   pragma Import (C, BeginTransmission, "Wire_BeginTransmission");

   --  Ends a transmission to a slave device that was begun by
   --    BeginTransmission () and transmits the bytes that were queued
   --    by write (). Ada wrapper around EndTransmission_C
   --  @param Stop true will send a stop message, releasing the bus after
   --    transmission. false will send a restart, keeping the connection active
   --  @return byte, which indicates the status of the transmission
   function EndTransmission (Stop : Boolean) return Byte;

   --  See documentation for EndTransmission
   function EndTransmission_C (Stop : Byte) return Byte
     with Global => null;
   pragma Import (C, EndTransmission_C, "Wire_EndTransmission");

   --  Queues bytes for transmission from a master to slave device
   --  @param Val a value to send as a single byte
   --  @return will return the number of bytes written
   function Write_Value (Val : Byte) return Byte
     with Global => null;
   pragma Import (C, Write_Value, "Wire_Write_Value");

   --  Returns the number of bytes available for retrieval with read()
   --  @return The number of bytes available for reading.
   function Available return Integer
     with Global => null;
   pragma Import (C, Available, "Wire_Available");

   --  Reads a byte that was transmitted from a slave device to a master
   --  @return The next byte received
   function Read return Byte
     with Global => null;
   pragma Import (C, Read, "Wire_Read");

end Wire;
