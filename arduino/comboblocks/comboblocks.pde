// Scale

#include <Servo.h> 

Servo myservo;  // create servo object to control a servo 
// a maximum of eight servo objects can be created 

const int SUPERBRIGHT = 0; // use the superbright RGB LED

const int NUM_SCALES = 4;
int scalePins[NUM_SCALES] = {
  A0,A1,A2,A3};

double errs[NUM_SCALES] = {0,0,0,0};

int doorStatePin = A3;
int servoPin = 2;
int superbrightRedLedPin = 4;
int superbrightGreenLedPin = 5;
int superbrightBlueLedPin = 6;
int redLedPin = 7;
int greenLedPin = 8;
int potPin = A5;

const int SERVO_CLOSED = 120;
const int SERVO_OPEN = 165;

int lastDoorButton = 0;

int doorOpen = 0;

double err_max;

int lastVals[NUM_SCALES] = {
  0,0,0,0};

int scaleCounts[NUM_SCALES] = {
  0,0,0,0};

int comboCounts[NUM_SCALES] = {
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

void print_scale_counts(String type, int* elts) {
  for(int i = 0; i < NUM_SCALES; i++) {
    Serial.print(type);
    Serial.print(" ");
    Serial.print(elts[i]);
  }
}

int check_lock(int* combo, int* vals) {
  int err = 0;
  for(int i = 0; i < NUM_SCALES; i++) {
    err += abs(vals[i] - combo[i]);
  }
}

void count_blocks(int* current, int* last) {
  double changes[NUM_SCALES] = {
    0,0,0,0};
  for(int i = 0; i < NUM_SCALES; i++) {
    changes[i] = current[i] - last[i]; 
    if(changes[i] > err_max) {
      scaleCounts[i] += 1;
    }
    else if(changes[i] < -err_max) {
      scaleCounts[i] -= 1;
    }
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
  pinMode(potPin, INPUT);
  myservo.attach(servoPin);
  pinMode(superbrightRedLedPin, OUTPUT);
  pinMode(superbrightGreenLedPin, OUTPUT);
  pinMode(superbrightBlueLedPin, OUTPUT);
  pinMode(redLedPin, OUTPUT);
  pinMode(greenLedPin, OUTPUT);
  for(int i = 0; i < NUM_SCALES; i++) {
    lastVals[i] = analogRead(scalePins[i]);
  }
}

void loop() {
  int  doorState = digitalRead(doorStatePin);
  int doorOpen = doorState == HIGH;
  print_int("DOOR_OPEN", doorOpen);

  int potState = analogRead(potPin);
  err_max = potState/1023.0;
  print_double("ERR_MAX", err_max);
  int vals[NUM_SCALES] = {
    0,0,0,0  };
  for(int i = 0; i < NUM_SCALES; i++) {
    vals[i] = analogRead(scalePins[i]);
  }
  
  count_blocks(vals, lastVals);
  if(doorOpen) {
      //combo[i] = vals[i];
      for(int i = 0; i < NUM_SCALES; i++){
        comboCounts[i] = scaleCounts[i];
      }
    }
  
  //print_scale("COMBO", combo);
  //print_scale("VALS", vals);
  print_scale_counts("COMBO COUNTS", comboCounts);
  print_scale_counts("SCALE COUNTS", scaleCounts);

  //int unlocked = err_check(combo, vals);
  int unlocked = check_lock(comboCounts, scaleCounts);

  print_int("UNLOCKED", unlocked);
  if(unlocked) {
    digitalWrite(superbrightRedLedPin, HIGH);
    digitalWrite(superbrightGreenLedPin, SUPERBRIGHT?LOW:HIGH);
    digitalWrite(superbrightBlueLedPin, HIGH);
    digitalWrite(redLedPin, LOW);
    digitalWrite(greenLedPin, SUPERBRIGHT?LOW:HIGH);
    myservo.write(SERVO_OPEN);
  } 
  else {
    digitalWrite(superbrightRedLedPin, SUPERBRIGHT?LOW:HIGH);
    digitalWrite(superbrightGreenLedPin, HIGH);
    digitalWrite(superbrightBlueLedPin, HIGH);
    digitalWrite(redLedPin, SUPERBRIGHT?LOW:HIGH);
    digitalWrite(greenLedPin, LOW);
    myservo.write(SERVO_CLOSED);
  }

  print_int("COUNTER", counter++);
  for(int i = 0; i < NUM_SCALES; i++) {
    lastVals[i] = vals[i];
  }
  delay(10);
}




