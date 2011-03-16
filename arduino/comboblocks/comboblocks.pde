// ComboBlocks
// controls the ComboBlocks

#include <Servo.h> 

Servo myservo;  // create servo object to control a servo 
// a maximum of eight servo objects can be created 

const int ORIG_STYLE = 0;
const int RMSE_STYLE = 1;

const int STYLE = RMSE_STYLE;

const int RMSE_SCALING = 1;

const int NUM_SCALES = 4;

const int SCALE_PINS[NUM_SCALES] = {
  A0,A1,A2,A3};

const int doorStatePin = A4;
const int servoPin = 2;
const int superbrightRedLedPin = 4;
const int superbrightGreenLedPin = 5;
const int superbrightBlueLedPin = 6;
const int redLedPin = 7;
const int greenLedPin = 8;
const int potPin = A5;
const int emergencyUnlockPin = 9;

const int SERVO_CLOSED = 120;
const int SERVO_OPEN = 165;
const int DOOR_THRESHOLD = 900;
const int SERVO_DELAY = 4;

int combo[NUM_SCALES] = {
  0,0,0,0};
  
int prevUnlocked = 1;

int counter = 0;
int start_counter;

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

void print_int_scale(String type, int* elts) {
  for(int i = 0; i < NUM_SCALES; i++) {
    Serial.print(type);
    Serial.print(" ");
    Serial.print(SCALE_PINS[i]);
    Serial.print(" ");
    Serial.println(elts[i]);

  } 
}

void print_double_scale(String type, double* elts) {
  for(int i = 0; i < NUM_SCALES; i++) {
    Serial.print(type);
    Serial.print(" ");
    Serial.print(SCALE_PINS[i]);
    Serial.print(" ");
    Serial.println(elts[i],6);
  } 
}

int err_check(double err_max, int* combo, int* vals) {
  double errs[NUM_SCALES] = {
  0,0,0,0};
  double err = 0;
  for(int i = 0; i < NUM_SCALES; i++) {
    errs[i] = abs(vals[i] - combo[i])/(1.0*combo[i]);
    err += errs[i];
  }

  print_double_scale("ERRS", errs);
  print_double("ERROR", err);
  return err < err_max;
}

int err_check_rmse(double err_max, int* combo, int* vals) {
  double errs[NUM_SCALES] = {
  0,0,0,0};
  double err = 0;
  for(int i = 0; i < NUM_SCALES; i++) {
    errs[i] = abs(vals[i] - combo[i])/(1.0*combo[i]);
    errs[i] *= errs[i];
    err += errs[i];
  }
  print_double_scale("ERRS", errs);
  err = sqrt(err/4) * RMSE_SCALING;
  print_double("ERROR", err);
  return err < err_max;
}
void setup() {
  Serial.begin(9600);
  for(int i = 0; i < NUM_SCALES; i++) {    
    pinMode(SCALE_PINS[i], INPUT);
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
    combo[i] = analogRead(SCALE_PINS[i]);
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
  double err_max = potState/1023.0;
  print_double("ERR_MAX", err_max);
  int vals[NUM_SCALES] = {
    0,0,0,0                  };
  for(int i = 0; i < NUM_SCALES; i++) {
    vals[i] = analogRead(SCALE_PINS[i]);
    if(doorOpen) {
      combo[i] = vals[i];
    }
  }
  print_int_scale("COMBO", combo);
  print_int_scale("VALS", vals);

  int unlocked = (STYLE == ORIG_STYLE && err_check(err_max, combo, vals))
      || (STYLE == RMSE_STYLE && err_check_rmse(err_max, combo,vals)) || doorOpen;
  print_int("UNLOCKED", unlocked);

  // reset the counter if changed
  if(prevUnlocked != unlocked) {
    start_counter = counter;
  }
  print_int("START_COUNTER", start_counter);

  if(unlocked) {
    digitalWrite(redLedPin, LOW);
    digitalWrite(greenLedPin, HIGH);
  } 
  else {
    digitalWrite(redLedPin, HIGH);
    digitalWrite(greenLedPin, LOW);
  }

  // unlock only if unlocked and we have waited for delay
  int s = unlocked && counter-start_counter > SERVO_DELAY;
  print_int("SERVO_STATE", s);
  if(s) {
    digitalWrite(superbrightRedLedPin, HIGH);
    digitalWrite(superbrightGreenLedPin, LOW);
    digitalWrite(superbrightBlueLedPin, HIGH);
    myservo.write(SERVO_OPEN);
  } 
  else {
    digitalWrite(superbrightRedLedPin, LOW);
    digitalWrite(superbrightGreenLedPin, HIGH);
    digitalWrite(superbrightBlueLedPin, HIGH);
    myservo.write(SERVO_CLOSED);
  }

  print_int("COUNTER", counter++);
  prevUnlocked = unlocked;
  delay(10);

}












