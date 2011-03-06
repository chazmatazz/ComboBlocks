// Graphing sketch

import processing.serial.*;

Serial myPort;        // The serial port
int xPos = 1;         // horizontal position of the graph
//float oldVal = 0;
int counter = 0;
int exception_counter = 0;

int num_analog_ports = 4;
int[] analog_ports = {
  14,15,16,17
};

PFont fontA;

int W = 1000;
int H = 600;

int TEXT_H = 20;
int TEXT_W = 180;

int TEXT_X1 = 0;
int TEXT_X2 = W-TEXT_W;
int TEXT_X_W1 = 140;
int TEXT_X_W2 = TEXT_W;

int TEXT_X3 = 0;
int TEXT_X_W3 = TEXT_W;

int UNLOCK_R = 40;

int TEXT_X4 = W-250-UNLOCK_R;
int TEXT_X_W4 = 250;


int TEXT_X5 = W/2;
int TEXT_X_W5 = 180;

int TEXT_Y = 100;

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
  // everything happens in the serialEvent()
}

int get_port(int analog_port) {
  for(int i = 0; i < num_analog_ports; i++) {
    if(analog_ports[i] == analog_port) {
      return i;
    }
  }
  return -1;
}
void draw_errs(int analog_port, float val) {
  int i = get_port(analog_port);
  fill(255);
  rect(TEXT_X5, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y - 20, TEXT_X_W5, TEXT_H);
  fill(0);
  text("ERR " + str(val), TEXT_X5, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y);

  // draw the line
  float inByte = map(val, 0, 1, 0, height/num_analog_ports);

  // draw the line:
  stroke(255,255,255);
  float y = height/num_analog_ports*(num_analog_ports-i) - inByte;
  line(xPos, y+2, xPos, y);
}  

void draw_combo(int analog_port, int val) {
  int i = get_port(analog_port);
  fill(255);
  rect(TEXT_X2, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y - 20, TEXT_X_W2, TEXT_H);
  fill(0);
  text("COMBO " + str(val), TEXT_X2, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y);
}

void draw_val(int xPos, int analog_port, int val) {
  int i = get_port(analog_port);
  // draw the text
  fill(255);
  rect(TEXT_X1, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y - 20, TEXT_X_W1, TEXT_H);
  fill(0);
  text("A" + str(i) + " " + str(val), TEXT_X1, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y);

  float inByte = map(val, 0, 1023, 0, height/num_analog_ports);

  // draw the line:
  stroke(127,34,255);
  line(xPos, height/num_analog_ports*(num_analog_ports-i), xPos, height/num_analog_ports*(num_analog_ports-i) - inByte);
}

void serialEvent (Serial myPort) {
  try {
    counter++;
    // get the ASCII string:
    String inString = myPort.readStringUntil('\n');

    if (inString != null) {
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
        rect(TEXT_X3, 0, TEXT_X_W3, TEXT_H);
        fill(0);
        text(inString, TEXT_X3, TEXT_H);
      }
      else if (inString.startsWith("DOOR_OPEN")) {
        fill(255);
        rect(TEXT_X3, H-TEXT_H, TEXT_X_W3, TEXT_H);
        fill(0);
        text(inString, TEXT_X3, H);
      }
      else if (inString.startsWith("DOOR_STATE")) {
        fill(255);
        rect(TEXT_X5, H-TEXT_H, TEXT_X_W5, TEXT_H);
        fill(0);
        text(inString, TEXT_X5, H);
      } 
      else if (inString.startsWith("EMERGENCY_UNLOCK_STATE")) {
        fill(255);
        rect(TEXT_X4, H-TEXT_H, TEXT_X_W4, TEXT_H);
        fill(0);
        text(inString, TEXT_X4, H);
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
        rect(TEXT_X4, 0, TEXT_X_W4, TEXT_H);
        fill(0);
        text(inString, TEXT_X4, TEXT_H);
      }
      else if (inString.startsWith("ERROR")) {
        fill(255);
        rect(TEXT_X5, 0, TEXT_X_W5, TEXT_H);
        fill(0);
        text(inString, TEXT_X5, TEXT_H);
      }
      else {

        String[] parts = inString.split(" ");
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
  catch (Exception e) {
    println("exception " + exception_counter++ + " of " + counter);
  }
}

void keyPressed() {
  if (key == 's') {
    String savePath = selectOutput();  // Opens file chooser
    if (savePath == null) {
      // If a file was not selected
      println("No output file was selected...");
    } 
    else {
      // If a file was selected, print path to folder
      println(savePath);
    }
    save(savePath);
  }
}

