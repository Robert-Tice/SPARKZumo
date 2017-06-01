#include <main_loop.h>
#include <main_setup.h>


void sei_wrapper() {
  sei();
}

void setup() {	
  Serial.begin(9600);
  main_setup__setup_placeholder();
}

void loop() {
  main_loop__loop_placeholder();
}
