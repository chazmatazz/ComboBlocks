// Scale

#include <Servo.h> 

Servo myservo;  // create servo object to control a servo 
// a maximum of eight servo objects can be created 

const int SUPERBRIGHT = 1; // use the superbright RGB LED
const int LOW_POWER = 1; // use the low power LEDs

const int COUNT_STYLE = 0; // Count # blocks
const int ORIG_STYLE = 1;
const int RMSE_STYLE = 2;

const int STYLE = RMSE_STYLE;

const int RMSE_SCALING = 4;

const int COUNTER_MOD = 5;

const int NUM_SCALES = 4;
const int COUNT_MULTIPLIERS_PLUS[NUM_SCALES] = {
  20,20,20,20};
const int COUNT_MULTIPLIERS_MINUS[NUM_SCALES] = {
  10,10,10,10};

int scalePins[NUM_SCALES] = {
  A0,A1,A2,A3};

const int NUM_SAMPLES = 5;
int samples[NUM_SCALES][NUM_SAMPLES];

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
int lastVals[NUM_SCALES] = {
  0,0,0,0};
int scaleCounts[NUM_SCALES] = {
  0,0,0,0};

double err_max;

int combo[NUM_SCALES] = {
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

void print_samples() {
  for(int i=0; i< NUM_SCALES; i++) {
    Serial.print("SAMPLES ");
    Serial.print(scalePins[i]);
    int first = counter%NUM_SAMPLES;
    for(int j = first; j < NUM_SAMPLES; j++) {
      Serial.print(" ");
      Serial.print(samples[i][j]);
    }
    for(int j = 0; j < first; j++) {
      Serial.print(" ");
      Serial.print(samples[i][j]);
    }
    Serial.println();
  } 
}
int check_lock(int* combo, int* vals) {
  int err = 0;
  for(int i = 0; i < NUM_SCALES; i++) {
    err += abs(vals[i] - combo[i]);
  }
  return err == 0;
}

void count_blocks(int* current, int* last) {
  double changes[NUM_SCALES] = {
    0,0,0,0      };
  for(int i = 0; i < NUM_SCALES; i++) {
    changes[i] = current[i] - last[i]; 
    if(changes[i] > err_max*COUNT_MULTIPLIERS_PLUS[i]) {
      scaleCounts[i] -= 1;
    }
    else if(changes[i] < -err_max*COUNT_MULTIPLIERS_MINUS[i]) {
      scaleCounts[i] += 1;
    }
    if (scaleCounts[i] < 0) {
      scaleCounts[i] = 0;
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

int err_check_rmse(int* combo, int* vals) {
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
    lastVals[i] = analogRead(scalePins[i]);
    for(int j = 0; j < NUM_SAMPLES; j++) {
      samples[i][j] = -1;
    }
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
    0,0,0,0                  };
  for(int i = 0; i < NUM_SCALES; i++) {
    vals[i] = analogRead(scalePins[i]);
    samples[i][counter%NUM_SAMPLES] = vals[i]; 
    if(doorOpen) {
      combo[i] = vals[i];
    }
  }
  print_scale("COMBO", combo);
  print_scale("VALS", vals);
  print_samples();
  if(counter > NUM_SAMPLES && counter % COUNTER_MOD == 0) {
    count_blocks(vals, lastVals);
  }
  if(doorOpen) {
    //combo[i] = vals[i];
    for(int i = 0; i < NUM_SCALES; i++){
      comboCounts[i] = scaleCounts[i];
    }
  }

  print_scale("COMBO_COUNTS", comboCounts);
  print_scale("SCALE_COUNTS", scaleCounts);


  int unlocked = (STYLE == COUNT_STYLE && check_lock(comboCounts, scaleCounts)) 
    || (STYLE == ORIG_STYLE && err_check(combo, vals))
      || (STYLE == RMSE_STYLE && err_check_rmse(combo,vals)) || doorOpen;
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
  if(counter > NUM_SAMPLES && counter % COUNTER_MOD == 0) {
    for(int i = 0; i < NUM_SCALES; i++) {
      // lastVals[i] = vals[i];
      lastVals[i] = 0;  
      for(int j = 0; j < NUM_SAMPLES; j++) {
        lastVals[i] += samples[i][j];
      }
      lastVals[i] /= NUM_SAMPLES;
    }
  }
  delay(10);

}












