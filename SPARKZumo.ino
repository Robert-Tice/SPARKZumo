#include <Wire.h>

extern "C" {
	#include <b__sparkzumo.h>
	#include <sparkzumo.h>

	void __gnat_last_chance_handler(void* msg, int line)
	{
		Serial.println("Exception occured!");
		Serial.print("#");
	    Serial.print(line);
	    Serial.print(": ");
	    Serial.println((char*)msg);

	    while(1);
	}


	void sei_wrapper() 
	{ sei(); }
}

void Serial_Print(void* msg) 
{ 
	Serial.println(reinterpret_cast<char*>(msg));
//	Serial.flush();
}

void Wire_Begin_Master(void)
{ Wire.begin(); }

void Wire_Begin_Slave(uint8_t addr)
{ Wire.begin(addr); }

int Wire_RequestFrom(uint8_t addr, uint8_t quant, uint8_t stop)
{ return Wire.requestFrom(addr, quant, stop); }

void Wire_BeginTransmission(uint8_t addr)
{ Wire.beginTransmission(addr); }

byte Wire_EndTransmission(uint8_t stop)
{ return Wire.endTransmission(stop); }

byte Wire_Write_Value(uint8_t val)
{ return Wire.write(val); }

byte Wire_Write_Array(void* arr, size_t length)
{ return Wire.write(reinterpret_cast<uint8_t*>(arr), length); }

int Wire_Available(void)
{ return Wire.available(); }

byte Wire_Read(void)
{ return Wire.read(); }

void Wire_SetClock(uint32_t freq)
{ Wire.setClock(freq); }


void setup() 
{	
  sparkzumoinit();

  Serial.begin(115200);
  sparkzumo__setup();
}

void loop() 
{
  sparkzumo__workloop();
}
