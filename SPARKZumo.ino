extern "C" {
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
	{
	  sei();
	}

	void Serial_Print(void* msg) 
	{
	    Serial.println((char*)msg);
	}
}


void setup() 
{	
  Serial.begin(115200);
  Zumomain();
  sparkzumo__setup();
}

void loop() 
{
  sparkzumo__workloop();
}
