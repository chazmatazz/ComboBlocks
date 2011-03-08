// Scale

#include <Servo.h> 

Servo myservo;  // create servo object to control a servo 
// a maximum of eight servo objects can be created 

const int SUPERBRIGHT = 1; // use the superbright RGB LED
const int LOW_POWER = 1; // use the low power LEDs

const int NUM_SCALES = 4;
int scalePins[NUM_SCALES] = {
  A0,A1,A2,A3};

double errs[NUM_SCALES] = {
  0,0,0,0};

int doorStatePin = A4;
int servoPin = 2;
int superbrightRedLedPin = 4;
int superbrightGreenLedPin = 5;
int superbrightBlueLedPin = 6;
int redLedPin = 7;
int greenLedPin = 8;
int potPin = A5;
int emergencyUnlockPin = 9;

const int SERVO_CLOSED = 120;
const int SERVO_OPEN = 165;
const int DOOR_THRESHOLD = 900;
const int SERVO_DELAY = 8;

int lastDoorButton = 0;

int doorOpen = 0;

int prevUnlocked = 1;

int start_counter;

double err_max;

int combo[NUM_SCALES] = {
  0,0,0,0};

int counter = 0;

void print_int(String key, int val) {
  Serial.print(key);
  Serial.print(" ");
  Serial.println(val); 
}

void print_double(String key, double val) {
  Serial.print(key);
  Serial.print(" ");
  Serial.println(val,6); 
}

void print_scale(String type, int* elts) {
  for(int i = 0; i < NUM_SCALES; i++) {
    Serial.print(type);
    Serial.print(" ");
    Serial.print(scalePins[i]);
    Serial.print(" ");
    Serial.println(elts[i]);

  } 
}

void print_double_scale(String type, double* elts) {
  for(int i = 0; i < NUM_SCALES; i++) {
    Serial.print(type);
    Serial.print(" ");
    Serial.print(scalePins[i]);
    Serial.print(" ");
    Serial.println(elts[i],6);
  } 
}

int err_check(int* combo, int* vals) {
  double err = 0;
  for(int i = 0; i < NUM_SCALES; i++) {
    errs[i] = abs(vals[i] - combo[i])/(1.0*combo[i]);
    err += errs[i];
  }
  print_double_scale("ERRS", errs);
  print_double("ERROR", err);
  return err < err_max;
}

void setup() {
  Serial.begin(9600);
  for(int i = 0; i < NUM_SCALES; i++) {    
    pinMode(scalePins[i], INPUT);
  }
  pinMode(doorStatePin, INPUT);
  pinMode(emergencyUnlockPin, INPUT);
  pinMode(potPin, INPUT);
  myservo.attach(servoPin);
  pinMode(superbrightRedLedPin, OUTPUT);
  pinMode(superbrightGreenLedPin, OUTPUT);
  pinMode(superbrightBlueLedPin, OUTPUT);
  pinMode(redLedPin, OUTPUT);
  pinMode(greenLedPin, OUTPUT);
  for(int i = 0; i < NUM_SCALES; i++) {
    combo[i] = analogRead(scalePins[i]);
  }
}

void loop() {
  int doorState = analogRead(doorStatePin);
  int emergencyUnlockState = digitalRead(emergencyUnlockPin)==LOW;
  int doorOpen = doorState < DOOR_THRESHOLD || emergencyUnlockState;
  print_int("EMERGENCY_UNLOCK_STATE", emergencyUnlockState);
  print_int("DOOR_STATE", doorState);
  print_int("DOOR_OPEN", doorOpen);

  int potState = analogRead(potPin);
  err_max = potState/1023.0;
  print_double("ERR_MAX", err_max);
  int vals[NUM_SCALES] = {
    0,0,0,0            };
  for(int i = 0; i < NUM_SCALES; i++) {
    vals[i] = analogRead(scalePins[i]);
    if(doorOpen) {
      combo[i] = vals[i];
    }
  }
  print_scale("COMBO", combo);
  print_scale("VALS", vals);

  int unlocked = err_check(combo, vals) || doorOpen;
  print_int("UNLOCKED", unlocked);

  // reset the counter if changed
  if(prevUnlocked != unlocked) {
    start_counter = counter;
  }
  print_int("START_COUNTER", start_counter);

  if(unlocked) {
    digitalWrite(redLedPin, LOW);
    digitalWrite(greenLedPin, LOW_POWER?HIGH:LOW);
  } 
  else {
    digitalWrite(redLedPin, LOW_POWER?HIGH:LOW);
    digitalWrite(greenLedPin, LOW);
  }
  
  // unlock only if unlocked and we have waited for delay
  int s = unlocked && counter-start_counter > SERVO_DELAY;
  print_int("SERVO_STATE", s);
  if(s) {
    digitalWrite(superbrightRedLedPin, HIGH);
    digitalWrite(superbrightGreenLedPin, SUPERBRIGHT?LOW:HIGH);
    digitalWrite(superbrightBlueLedPin, HIGH);
    myservo.write(SERVO_OPEN);
  } 
  else {
    digitalWrite(superbrightRedLedPin, SUPERBRIGHT?LOW:HIGH);
    digitalWrite(superbrightGreenLedPin, HIGH);
    digitalWrite(superbrightBlueLedPin, HIGH);
    myservo.write(SERVO_CLOSED);
  }

  print_int("COUNTER", counter++);
  prevUnlocked = unlocked;
  delay(10);

}









