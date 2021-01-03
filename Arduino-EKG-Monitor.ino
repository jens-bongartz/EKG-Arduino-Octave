#include <TimerOne.h>

int faADC  = 200;

// Analoge Eingänge
int adcChannel = 0;  // A0

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  Timer1.initialize(1000000/faADC);             
  Timer1.attachInterrupt(readADC);                             
}

void loop() {
}

void readADC() {
  int adcValue = analogRead(adcChannel);
  Serial.print("ADC:");
  Serial.println(adcValue);
}

void serialEvent() {
  char inChar = Serial.read();
  if (inChar == 's') {   // 's'top
    Timer1.stop();
  }
  if (inChar == 't') {   //  restar't'
    Timer1.restart();
  }
}
