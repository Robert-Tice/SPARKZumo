#include <Wire.h>


extern "C" {
	#include <b__sparkzumo.h>
	#include <sparkzumo.h>

	void __gnat_last_chance_handler_impl(void* msg, const char* file, const char* func, int line)
	{
		Serial.println("Exception(");
		Serial.print(file);
		Serial.print(":");
		Serial.print(func);
		Serial.print(":");
		Serial.print(line);
		Serial.print("): ");
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

void Serial_Print_Byte(void* msg, uint8_t val) 
{ 
	Serial.print(reinterpret_cast<char*>(msg));
	Serial.print(": ");
	Serial.println(val);
//	Serial.flush();
}

void Serial_Print_Short(void* msg, uint16_t val) 
{ 
	Serial.print(reinterpret_cast<char*>(msg));
	Serial.print(": ");
	Serial.println(val);
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

int Wire_Available(void)
{ return Wire.available(); }

byte Wire_Read(void)
{ return Wire.read(); }

void Wire_SetClock(uint32_t freq)
{ Wire.setClock(freq); }


void setup() 
{	
	Serial.begin(115200);		
	sparkzumoinit();
	sparkzumo__setup();
}

void loop() 
{
	sparkzumo__workloop();
}
