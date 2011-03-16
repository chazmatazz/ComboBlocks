// Graphing sketch

import processing.serial.*;

Serial myPort;        // The serial port
int xPos = 1;         // horizontal position of the graph
int counter = 0;
int exception_counter = 0;

int A0 = 14;
int A1 = 15;
int A2 = 16;
int A3 = 17;

int NUM_ANALOG_PORTS = 4;
int[] ANALOG_PORTS = {
  A0, A1, A2, A3
};

PFont fontA;

int W = 1000;
int H = 600;

int UNLOCK_R = 40;

int TEXT_H = 20;
int TEXT_W = 180;

int TEXT_Y = 100;

int TEXT_X1 = 0;
int TEXT_W_X1 = TEXT_W;

int TEXT_X2 = W/2;
int TEXT_W_X2 = TEXT_W;

int TEXT_X3 = W-250-UNLOCK_R;
int TEXT_W_X3 = 250;


void setup () {
  // set the window size:
  size(W, H);        

  // List all the available serial ports
  println(Serial.list());
  // I know that the first port in the serial list on my mac
  // is always my  Arduino, so I open Serial.list()[0].
  // Open whatever port is the one you're using.
  myPort = new Serial(this, Serial.list()[0], 9600);
  // don't generate a serialEvent() unless you get a newline character:
  myPort.bufferUntil('\n');

  // set inital background:
  background(0);

  // For vector fonts, use the createFont() function. 
  fontA = loadFont("CourierNewPSMT-16.vlw");

  // Set the font and its size (in units of pixels)
  textFont(fontA, 16);
}

void draw () {
}

int get_port(int analog_port) {
  for(int i = 0; i < NUM_ANALOG_PORTS; i++) {
    if(ANALOG_PORTS[i] == analog_port) {
      return i;
    }
  }
  return -1;
}

void draw_errs(int analog_port, float val) {
  int i = get_port(analog_port);
  fill(255);
  rect(TEXT_X2, height/NUM_ANALOG_PORTS*(NUM_ANALOG_PORTS-i) - TEXT_Y -TEXT_H, TEXT_W_X2, TEXT_H);
  fill(0);
  text("ERR " + str(val), TEXT_X2, height/NUM_ANALOG_PORTS*(NUM_ANALOG_PORTS-i) - TEXT_Y);

  // draw the line
  float inByte = map(val, 0, 1, 0, height/NUM_ANALOG_PORTS);

  // draw the line:
  stroke(255,255,255);
  float y = height/NUM_ANALOG_PORTS*(NUM_ANALOG_PORTS-i) - inByte;
  line(xPos, y+2, xPos, y);
}

void draw_combo(int analog_port, int val) {
  int i = get_port(analog_port);
  fill(255);
  rect(TEXT_X3, height/NUM_ANALOG_PORTS*(NUM_ANALOG_PORTS-i) - TEXT_Y - TEXT_H, TEXT_W_X3, TEXT_H);
  fill(0);
  text("COMBO " + str(val), TEXT_X3, height/NUM_ANALOG_PORTS*(NUM_ANALOG_PORTS-i) - TEXT_Y);
}

void draw_val(int xPos, int analog_port, int val) {
  int i = get_port(analog_port);
  // draw the text
  fill(255);
  rect(TEXT_X1, height/NUM_ANALOG_PORTS*(NUM_ANALOG_PORTS-i) - TEXT_Y - TEXT_H, TEXT_W_X1, TEXT_H);
  fill(0);
  text("A" + str(i) + " " + str(val), TEXT_X1, height/NUM_ANALOG_PORTS*(NUM_ANALOG_PORTS-i) - TEXT_Y);

  float inByte = map(val, 0, 1023, 0, height/NUM_ANALOG_PORTS*1/3);

  // draw the line:
  stroke(127,34,255);
  line(xPos, height/NUM_ANALOG_PORTS*(NUM_ANALOG_PORTS-i), xPos, height/NUM_ANALOG_PORTS*(NUM_ANALOG_PORTS-i) - inByte);
}

void serialEvent (Serial myPort) {
  try {
    counter++;
    // get the ASCII string:
    String inString = myPort.readStringUntil('\n');

    if (inString != null) {
      process(inString);
    }
  } 
  catch (Exception e) {
    //println("exception " + exception_counter++ + " of " + counter);
  }
}

void process(String inString) {
  if(inString.startsWith("COUNTER")) {
    // at the edge of the screen, go back to the beginning:
    if (xPos >= width) {
      xPos = 0;
      background(0);
    } 
    else {
      // increment the horizontal position:
      xPos++;
    }
  }  
  else if (inString.startsWith("SERVO_STATE")) {
    fill(255);
    rect(TEXT_X1, 0, TEXT_W_X1, TEXT_H);
    fill(0);
    text(inString, TEXT_X1, TEXT_H);
  }
  else if (inString.startsWith("DOOR_OPEN")) {
    fill(255);
    rect(TEXT_X1, H-TEXT_H, TEXT_W_X1, TEXT_H);
    fill(0);
    text(inString, TEXT_X1, H);
  }
  else if (inString.startsWith("DOOR_STATE")) {
    fill(255);
    rect(TEXT_X2, H-TEXT_H, TEXT_W_X2, TEXT_H);
    fill(0);
    text(inString, TEXT_X2, H);
  } 
  else if (inString.startsWith("EMERGENCY_UNLOCK_STATE")) {
    fill(255);
    rect(TEXT_X3, H-TEXT_H, TEXT_W_X3, TEXT_H);
    fill(0);
    text(inString, TEXT_X3, H);
  } 
  else if (inString.startsWith("UNLOCKED")) {
    String[] parts = inString.split(" ");
    if(int(trim(parts[1])) == 1) {
      fill(0,255,0);
    } 
    else {
      fill(255,0,0);
    }
    ellipse(W-UNLOCK_R/2, UNLOCK_R/2, UNLOCK_R, UNLOCK_R);
  }
  else if (inString.startsWith("ERR_MAX")) {
    fill(255);
    rect(TEXT_X3, 0, TEXT_W_X3, TEXT_H);
    fill(0);
    text(inString, TEXT_X3, TEXT_H);
  }
  else if (inString.startsWith("ERROR")) {
    fill(255);
    rect(TEXT_X2, 0, TEXT_W_X2, TEXT_H);
    fill(0);
    text(inString, TEXT_X2, TEXT_H);
  }
  else {
    String[] parts = inString.split(" ");
    if(parts.length > 1) {
      int analog_port = int(trim(parts[1]));
      if(trim(parts[0]).startsWith("COMBO")) {
        draw_combo(analog_port,  int(trim(parts[2])));
      }
      else if(trim(parts[0]).startsWith("ERRS")) {
        draw_errs(analog_port,  float(trim(parts[2])));
      }
      else {
        draw_val(xPos, analog_port,  int(trim(parts[2])));
      }
    }
  }
}

