// Graphing sketch

/*
Usage:
In replay mode:
Prompts user for file to open.
If immediate, prints out the graph immediately.
Otherwise, prints it out slowly.

If not in replay mode, record into file specified by user.

Click on the red bar to select the scale to change the truth value for. 
The bar turns green indicating that the scale is selected. 
You can then press 0,1,2 or 3 to indicate how many blocks are present.

*/
import processing.serial.*;

boolean replay = true;
boolean immediate = true;

Serial myPort;        // The serial port
int xPos = 1;         // horizontal position of the graph
//float oldVal = 0;
int counter = 0;
int exception_counter = 0;

int num_analog_ports = 4;
int[] analog_ports = {
  14,15,16,17
};

int max_num_blocks = 3;


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

int TEXT_X6 = TEXT_X_W1;
int TEXT_W_X6 = 2*TEXT_X_W1;

int TEXT_Y = 100;

int selectedDevice = -1;
int[] num_blocks = {
  0,0,0,0
};

int[] last_n = {
  0,0,0,0
};

PrintWriter output;

BufferedReader reader;
String line;

void setup () {
  // set the window size:
  size(W, H);        

  if(!replay) {
    // List all the available serial ports
    println(Serial.list());
    // I know that the first port in the serial list on my mac
    // is always my  Arduino, so I open Serial.list()[0].
    // Open whatever port is the one you're using.
    myPort = new Serial(this, Serial.list()[0], 9600);
    // don't generate a serialEvent() unless you get a newline character:
    myPort.bufferUntil('\n');
  }
  // set inital background:
  background(0);

  // For vector fonts, use the createFont() function. 
  fontA = loadFont("CourierNewPSMT-10.vlw");

  // Set the font and its size (in units of pixels)
  textFont(fontA, 10);

  draw_selected_device(selectedDevice);
  draw_num_blocks(num_blocks);

  if(!replay) {
    String savePath = selectOutput();  // Opens file chooser
    if (savePath == null) {
      // If a file was not selected
      println("No output file was selected...");
      exit();
    }
    output = createWriter(savePath);
    output.println("START_SKETCH");
    for(int i = 0; i < num_analog_ports; i++) {
      output.println("N " + analog_ports[i] + " 0");
    }
  } 
  else {
    String loadPath = selectInput();  // Opens file chooser
    if (loadPath == null) {
      // If a file was not selected
      println("No file was selected...");
      exit();
    }
    reader = createReader(loadPath);
  }
}
void draw () {
  if(replay) {
    while(immediate) {
      try {
        counter++;
        line = reader.readLine();
        process(line);
      } 
      catch(IOException e) {
      }
      catch (Exception e) {
        break;
      }
    }
  }
}

void mousePressed() {
  if(!replay) {
    for(int i = 0; i < num_analog_ports; i++) {
      if(mouseY < height/num_analog_ports * (num_analog_ports-i)) {
        selectedDevice = i;
      }
    }
    draw_selected_device(selectedDevice);
  }
}

void keyPressed() {
  if(!replay) {
    int tmp = -1;
    if(key == '0') {
      tmp = 0;
    } 
    else if (key == '1') {
      tmp = 1;
    } 
    else if (key == '2') {
      tmp = 2;
    } 
    else if (key == '3') {
      tmp = 3;
    }
    if(tmp != -1 && selectedDevice >=0 && selectedDevice < num_analog_ports) {
      output.println("N " + analog_ports[selectedDevice] + " " + tmp);
      num_blocks[selectedDevice] = tmp;
      draw_num_blocks(num_blocks);
    }
  }
}

int get_port(int analog_port) {
  for(int i = 0; i < num_analog_ports; i++) {
    if(analog_ports[i] == analog_port) {
      return i;
    }
  }
  return -1;
}

void draw_selected_device(int selectedDevice) {
  for(int i = 0; i < num_analog_ports; i++) {
    if(i == selectedDevice) {
      fill(0,255,0);
    } 
    else {
      fill(255, 0, 0);
    }
    rect(TEXT_X6, height/num_analog_ports*(num_analog_ports-i)-TEXT_Y, TEXT_W_X6, TEXT_H);
  }
}

void draw_n(int analog_port, int val) {
  int i = get_port(analog_port);
  fill(255);
  rect(TEXT_X6, height/num_analog_ports*(num_analog_ports-i)-TEXT_Y - 20, TEXT_W_X6, TEXT_H);
  fill(0);
  text("NUM_BLOCKS " + str(val),  TEXT_X6, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y);
  last_n[i] = val;


  float inByte = map(val, 0, max_num_blocks, 0, height/num_analog_ports/3);
  stroke(255,255,255);
  int base = height/num_analog_ports*(num_analog_ports-i)-height/num_analog_ports*1/3;
  line(xPos, base, xPos+5, base-inByte);
}
void draw_num_blocks(int[] num_blocks) {
  for(int i = 0; i < num_analog_ports; i++) {
    draw_n(analog_ports[i], num_blocks[i]);
  }
}

void draw_errs(int analog_port, float val) {
  int i = get_port(analog_port);
  fill(255);
  rect(TEXT_X1, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y, TEXT_X_W1, TEXT_H);
  fill(0);
  text("ERR " + str(val), TEXT_X1, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y+TEXT_H);

  // draw the line
  float inByte = map(val, 0, 1, 0, height/num_analog_ports);

  // draw the line:
  stroke(255,255,255);
  float y = height/num_analog_ports*(num_analog_ports-i) - inByte;
  line(xPos, y+2, xPos, y);
}  

void draw_combo_counts(int analog_port, int val) {
  int i = get_port(analog_port);
  fill(255);
  rect(TEXT_X5, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y - 20, TEXT_X_W5, TEXT_H);
  fill(0);
  text("COMBO_COUNTS " + str(val), TEXT_X5, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y);
}

void draw_scale_counts(int analog_port, int val) {
  int i = get_port(analog_port);
  fill(255);
  rect(TEXT_X5, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y, TEXT_X_W5, TEXT_H);
  fill(0);
  text("SCALE_COUNTS " + str(val), TEXT_X5, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y+TEXT_H);
}

void draw_combo(int analog_port, int val) {
  int i = get_port(analog_port);
  fill(255);
  rect(TEXT_X2, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y - 20, TEXT_X_W2, TEXT_H);
  fill(0);
  text("COMBO " + str(val), TEXT_X2, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y);
}

void draw_samples(int analog_port, String s) {
  int i = get_port(analog_port);
  fill(255);
  rect(TEXT_X2, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y, TEXT_X_W2, TEXT_H);
  fill(0);
  text(s, TEXT_X2, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y+TEXT_H);
}

void draw_val(int xPos, int analog_port, int val) {
  int i = get_port(analog_port);
  // draw the text
  fill(255);
  rect(TEXT_X1, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y - 20, TEXT_X_W1, TEXT_H);
  fill(0);
  text("A" + str(i) + " " + str(val), TEXT_X1, height/num_analog_ports*(num_analog_ports-i) - TEXT_Y);

  float inByte = map(val, 0, 1023, 0, height/num_analog_ports*1/3);

  // draw the line:
  stroke(127,34,255);
  line(xPos, height/num_analog_ports*(num_analog_ports-i), xPos, height/num_analog_ports*(num_analog_ports-i) - inByte);

  // draw the last_n
  inByte = map(last_n[i], 0, max_num_blocks, 0, height/num_analog_ports/3);
  stroke(0,255,0);
  int base = height/num_analog_ports*(num_analog_ports-i)-height/num_analog_ports*1/3;
  line(xPos, base, xPos, base-inByte);
}

void serialEvent (Serial myPort) {
  try {
    counter++;
    // get the ASCII string:
    String inString = myPort.readStringUntil('\n');

    if (inString != null) {
      process(inString);
      output.println(inString);
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
    if(parts.length > 1) {
      int analog_port = int(trim(parts[1]));
      if(trim(parts[0]).startsWith("COMBO_COUNTS")) {
        draw_combo_counts(analog_port,  int(trim(parts[2])));
      }
      else if(trim(parts[0]).startsWith("COMBO")) {
        draw_combo(analog_port,  int(trim(parts[2])));
      }
      else if(trim(parts[0]).startsWith("ERRS")) {
        draw_errs(analog_port,  float(trim(parts[2])));
      }
      else if(trim(parts[0]).startsWith("SCALE_COUNTS")) {
        draw_scale_counts(analog_port,  int(trim(parts[2])));
      }
      else if(trim(parts[0]).startsWith("SAMPLES")) {
        draw_samples(analog_port, inString);
      }
      else if(replay && trim(parts[0]).startsWith("N")) {
        draw_n(analog_port, int(trim(parts[2])));
      }
      else {
        draw_val(xPos, analog_port,  int(trim(parts[2])));
      }
    }
  }
}

