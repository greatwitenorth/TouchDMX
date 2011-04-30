import controlP5.*;

import processing.serial.*;

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

ControlP5 controlP5;
ControlFont font;
controlP5.Button b;

// The serial port:
Serial port; 

PFont ipFont;

/* fadeRes Defines the resolution of a fade between presets. 
 * The lower the number the higher the resolution.
 * Don't set it too low though because it will take 
 * longer for the loop to iterate reducing you slider speed accuracy.
 */
int fadeRes = 20;

float theSpeed = 0.2; //Starting point for the speed
float maxSpeed = 10000; //The maximum amount of time for the speed fader in milliseconds
float topLights = 0;
float backLights = 0;
int tapTime;

float topR;
float topG;
float topB;
float topA;

float backR;
float backG;
float backB;
float backA;

String ip1 = "10.0.2.36";
String defaultIP = "169.254.18.207";
boolean isOpen;

String textValue = "";
Textfield myTextfield;

boolean presetState;
Preset[] presets;
String[] lines;
int presetCount;

// Your default DMX Channels go here. They are in order from left to right on the first TouchOSC screen.
// The first 4 in the array are the 'Top' group and the last 4 are the 'Back' group
int[] channels = { 20, 21, 22, 23, 60, 61, 62, 63 };
int[] channelsID = { 20, 21, 22, 23, 60, 61, 62, 63 };


void setup() {
  size(420,420);
  frameRate(25);
  
  if(ip1 == ""){
    ip1 = defaultIP;
  }
  
  //Setup the graphical interface
  controlP5 = new ControlP5(this);
  controlP5.addButton("Reset",10,0,0,100,20).setId(1);
  
  font = new ControlFont(createFont("Times",20),20);
  ipFont = createFont("Helvetica", 12);
  font.setSmooth(true);
  
  controlP5.controller("Reset").captionLabel().setControlFont(font);
  controlP5.controller("Reset").captionLabel().setControlFontSize(10);
  controlP5.controller("Reset").setCaptionLabel("Reset Program");
  
  myTextfield = controlP5.addTextfield("changeIP",100,160,200,20);

  controlP5.addTextfield("Red 1",100,260,30,20).setId(0);
  controlP5.addTextfield("Green 1",100,300,30,20).setId(1);
  controlP5.addTextfield("Blue 1",100,340,30,20).setId(2);
  controlP5.addTextfield("Alpha 1",100,380,30,20).setId(3);
  controlP5.addTextfield("Red 2",200,260,30,20).setId(4);
  controlP5.addTextfield("Green 2",200,300,30,20).setId(5);
  controlP5.addTextfield("Blue 2",200,340,30,20).setId(6);
  controlP5.addTextfield("Alpha 2",200,380,30,20).setId(7);

  controlP5.controller("changeIP").setCaptionLabel("Enter IP Address of iPhone/iPod running TouchOSC then hit enter");
  myTextfield.setFocus(true);
  myTextfield.setAutoClear(false);
  
  //Setup our serail port to the Arduino
  port = new Serial(this, Serial.list()[0], 115200);
  
  // Sets the alpha channels to 1. On most DMX lights the fourth DMX channel is the alpha control.
  // For example if the light is set to DMX channel 33 then the alpha channel whould be 36.
  // This is why we pick the fourth value of the array for each set
  setDMX(channels[3], 1.0);
  setDMX(channels[7], 1.0);
  
  
  /* start oscP5, listening for incoming messages at port 10000 */
  oscP5 = new OscP5(this,10000);

  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
   
  println("this is the IP: "+ip1);
  myRemoteLocation = new NetAddress(ip1,10001);

  /* osc plug service
   * osc messages with a specific address pattern can be automatically
   * forwarded to a specific method of an object. in this example
   * a message with address pattern /test will be forwarded to a method
   * test(). below the method test takes 2 arguments - 2 ints. therefore each
   * message with address pattern /test and typetag ii will be forwarded to
   * the method test(int theA, int theB)
   */
  
  //Send out zero data to touchOSC
  initializeMixer();

  //Attatch our functions to OSC messages
  oscP5.plug(this,"tap","/dmx/tap");
  oscP5.plug(this,"speed","/dmx/speed");
  oscP5.plug(this,"presetSet","/dmx/preset/set");
  
  oscP5.plug(this,"preset0","/dmx/preset/0");
  oscP5.plug(this,"preset1","/dmx/preset/1");
  oscP5.plug(this,"preset2","/dmx/preset/2");
  oscP5.plug(this,"preset3","/dmx/preset/3");
  oscP5.plug(this,"preset4","/dmx/preset/4");
  oscP5.plug(this,"preset5","/dmx/preset/5");
  oscP5.plug(this,"preset6","/dmx/preset/6");
  oscP5.plug(this,"preset7","/dmx/preset/7");
  oscP5.plug(this,"preset8","/dmx/preset/8");
  oscP5.plug(this,"preset9","/dmx/preset/9");

  oscP5.plug(this,"chR1","/dmx/set/20");
  oscP5.plug(this,"chG1","/dmx/set/21");
  oscP5.plug(this,"chB1","/dmx/set/22");
  oscP5.plug(this,"chA1","/dmx/set/23");

  oscP5.plug(this,"chR2","/dmx/set/60");
  oscP5.plug(this,"chG2","/dmx/set/61");
  oscP5.plug(this,"chB2","/dmx/set/62");
  oscP5.plug(this,"chA2","/dmx/set/63");

  oscP5.plug(this,"topToggle","/dmx/preset/top");
  oscP5.plug(this,"backToggle","/dmx/preset/back");
  
  // Loads our preset from the tab delimited txt file in the data folder
  lines = loadStrings("presets.txt");
  loadPresets();
}

public void savePresetsToFile(int presetVal){
  String[] lines2 = new String[presets.length];
  presets[presetVal].topR = topR;
  presets[presetVal].topG = topG;
  presets[presetVal].topB = topB;

  presets[presetVal].backR = backR;
  presets[presetVal].backG = backG;
  presets[presetVal].backB = backB;
  
  for (int i = 0; i < presets.length; i++) {
    lines2[i] = presets[i].topR + "\t" + presets[i].topG + "\t" + presets[i].topB + "\t" + presets[i].backR + "\t" + presets[i].backG + "\t" + presets[i].backB;
  }
  saveStrings("data/presets.txt", lines2); 
}

void loadPresets(){
  presets = new Preset[lines.length];
  for (int i = 0; i < lines.length; i++) {
    String[] pieces = split(lines[i], '\t');
    presets[presetCount] = new Preset(pieces);
    presetCount++;
  } 
}

class Preset {
  float topR;
  float topG;
  float topB;
  float backR;
  float backG;
  float backB;
  
  public Preset(String[] pieces) {
    topR = float(pieces[0]);
    topG = float(pieces[1]);
    topB = float(pieces[2]);

    backR = float(pieces[3]);
    backG = float(pieces[4]);
    backB = float(pieces[5]);
  }
}

// TODO I'm sure there is a better way to do this
public void chR1(float val){
    setDMX(channels[0], val);
    topR = val;
}

public void chG1(float val){
    setDMX(channels[1], val);
    topG = val;
}

public void chB1(float val){
    setDMX(channels[2], val);
    topB = val;
}

public void chA1(float val){
    setDMX(channels[3], val);
    topA = val;
}

public void chR2(float val){
    setDMX(channels[4], val);
    backR = val;
}

public void chG2(float val){
    setDMX(channels[5], val);
    backG = val;
}

public void chB2(float val){
    setDMX(channels[6], val);
    backB = val;
}

public void chA2(float val){
    setDMX(channels[7], val);
    backA = val;
}

public void backToggle(float val){
  backLights = val;
}

public void topToggle(float val){
  topLights = val;
}

public void speed(float speedVal) {
  // This sets the speed for the fades based on incoming messages from TouchOSC
  theSpeed = speedVal;  
  OscMessage myMessage = new OscMessage("/2/label5");
  myMessage.add("Speed "+round(theSpeed*(maxSpeed/1000), 1)+" sec");
  oscP5.send(myMessage, myRemoteLocation);
}

public void speedSlider(float speedVal) {
  // This updates the speed slider on the TouchOSC interface
  theSpeed = speedVal;

  OscMessage myMessage = new OscMessage("/dmx/speed");
  myMessage.add(theSpeed);
  oscP5.send(myMessage, myRemoteLocation); 

  OscMessage myMessage3 = new OscMessage("/2/label5");
  myMessage3.add("Speed "+round(theSpeed*(maxSpeed/1000), 1)+" sec");
  oscP5.send(myMessage3, myRemoteLocation);
}

// TODO again probably a better way to do this
public void presetSet(float presetVal) {
  if(presetVal == 1){
    presetState = true;
  } else {
    presetState = false;
  }
}

public void preset0(float presetVal) {
  if(presetVal == 1){
    if(!presetState){
      fadeToPreset(0);
    } else {
      savePresetsToFile(0);
    }
  }
}

public void preset1(float presetVal) {
  if(presetVal == 1){
    if(!presetState){
      fadeToPreset(1);
    } else {
      savePresetsToFile(1);
    }
  }
}

public void preset2(float presetVal) {
  if(presetVal == 1){
    if(!presetState){
      fadeToPreset(2);
    } else {
      savePresetsToFile(2);
    }
  }
}

public void preset3(float presetVal) {
  if(presetVal == 1){
    if(!presetState){
      fadeToPreset(3);
    } else {
      savePresetsToFile(3);
    }
  }
}

public void preset4(float presetVal) {
  if(presetVal == 1){
    if(!presetState){
      fadeToPreset(4);
    } else {
      savePresetsToFile(4);
    }
  }
}

public void preset5(float presetVal) {
  if(presetVal == 1){
    if(!presetState){
      fadeToPreset(5);
    } else {
      savePresetsToFile(5);
    }
  }
}

public void preset6(float presetVal) {
  if(presetVal == 1){
    if(!presetState){
      fadeToPreset(6);
    } else {
      savePresetsToFile(6);
    }
  }
}

public void preset7(float presetVal) {
  if(presetVal == 1){
    if(!presetState){
      fadeToPreset(7);
    } else {
      savePresetsToFile(7);
    }
  }
}

public void preset8(float presetVal) {
  if(presetVal == 1){
    if(!presetState){
      fadeToPreset(8);
    } else {
      savePresetsToFile(8);
    }
  }
}

public void preset9(float presetVal) {
  if(presetVal == 1){
    if(!presetState){
      fadeToPreset(9);
    } else {
      savePresetsToFile(9);
    }
  }
}

public void tap(float theC) {
  // This listens for messages coming from the 'Tap to Sync' button.
  // It updates the speed based on the taps and the slider in TouchOSC
  if (theC == 1){
    theSpeed = (millis() - tapTime)/maxSpeed;
    constrain(theSpeed, 0, 1.0);

    if (theSpeed <= 1.0){
      tapTime = millis();
      speedSlider(theSpeed);
    } 
    else {
      tapTime = millis();
    }
  }
}

void fadeToPreset(int presetVal){
  float lerR = 0;
  float lerG = 0;
  float lerB = 0;
  float backLerR = 0;
  float backLerG = 0;
  float backLerB = 0;

  float time = theSpeed*maxSpeed;

  //Time cannot equal zero since we cannot divide by zero
  if(time == 0){
    time = fadeRes; //Set the time to our fader resolution defined at the top
  };
  
  float theSpeedFlt = theSpeed*maxSpeed;
  
  if(backLights == 1 || topLights == 1){
    for (int i = 0; i <= time ; i = i+fadeRes){
      if(topLights == 1){
        // Using lerp gives us a smooth transistion between the two values
        lerR = lerp(topR, presets[presetVal].topR, i/time);
        lerG = lerp(topG, presets[presetVal].topG, i/time);
        lerB = lerp(topB, presets[presetVal].topB, i/time);
        setDMX(channels[0], lerR);
        setDMX(channels[1], lerG);
        setDMX(channels[2], lerB);
        updateRGBFader(channelsID[0], lerR);
        updateRGBFader(channelsID[1], lerG);
        updateRGBFader(channelsID[2], lerB);
      }
  
      if(backLights == 1){
        backLerR = lerp(backR, presets[presetVal].backR, i/time);
        backLerG = lerp(backG, presets[presetVal].backG, i/time);
        backLerB = lerp(backB, presets[presetVal].backB, i/time);
        setDMX(channels[4], backLerR);
        setDMX(channels[5], backLerG);
        setDMX(channels[6], backLerB);
        updateRGBFader(channelsID[4], backLerR);
        updateRGBFader(channelsID[5], backLerG);
        updateRGBFader(channelsID[6], backLerB);
        println(backLerR);
      }    
  
      OscMessage myMessage = new OscMessage("/dmx/preset/"+presetVal);
      myMessage.add(1);
      oscP5.send(myMessage, myRemoteLocation);
      
      OscMessage myMessage2 = new OscMessage("/2/seconds");
      myMessage2.add(round(((theSpeedFlt)-i)/1000, 1)+"sec");
      oscP5.send(myMessage2, myRemoteLocation);
            
      delay(fadeRes);
    }
  }

  delay(10);
  
  for (int i = 0; i <= 10; i++){
    //Now that we're done our fade make sure all presets lights are offin the TouchOSC display
    turnOffPreset(i);
  }
  
  //Update global rgb variables to current values
  if(backLights == 1 || topLights == 1){
    if(topLights == 1){
      topR = lerR;
      topG = lerG;
      topB = lerB;
    }
    if(backLights == 1){
      backR = backLerR;
      backG = backLerG;
      backB = backLerB;
    }
  }
}

void turnOffPreset(int preset){
  OscMessage myMessage2 = new OscMessage("/dmx/preset/"+preset);
  myMessage2.add(0);
  oscP5.send(myMessage2, myRemoteLocation);
}

float round(float number, float decimal) {
  return (float)(round((number*pow(10, decimal))))/pow(10, decimal);
}

void setRGBChannelLabel(String label, String oscaddr){
  OscMessage myMessage2 = new OscMessage(oscaddr);
  myMessage2.add(label);
  oscP5.send(myMessage2, myRemoteLocation);
}

void setDMX(int channel, float val){
  float m = map(val, 0, 1, 0, 255);
  int v = int(m);
  port.write("<" + channel + "," + v + ">");

}

void updateRGBFader(int channel, float val){
  OscMessage myMessage2 = new OscMessage("/dmx/set/"+channel);
  myMessage2.add(val);
  oscP5.send(myMessage2, myRemoteLocation);
}

void updateItem(String item, float val){
  OscMessage myMessage2 = new OscMessage(item);
  myMessage2.add(val);
  oscP5.send(myMessage2, myRemoteLocation);
  delay(10);
}

void initializeMixer(){
  //Reset speed slider on remote device 
  speedSlider(theSpeed);

  updateItem("/dmx/preset/top", topLights);
  updateItem("/dmx/preset/back", backLights);
  updateItem("/dmx/preset/set", 0);
  
  //Setup our channels and labels
  for (int i = 0; i < channelsID.length; i++){
    //Send out our channel labels
    setRGBChannelLabel("Ch "+channels[i], "/1/label/ch"+i);
    updateItem("/dmx/set/"+channelsID[i], 0);
    setDMX(channelsID[i], 0);
  }
}

void draw() {
  background(0,0,0);
  
  fill(255,255,255);
  textFont(ipFont);
  text("Computer Current IP is set to: "+ip1, 100, 220); 
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  if(theOscMessage.isPlugged()==false) {
    /* print the address pattern and the typetag of the received OscMessage */
    println("### received an osc message.");
    println("### addrpattern\t"+theOscMessage.addrPattern());
    println("### typetag\t"+theOscMessage.typetag());
  }
}

public void Reset(float theValue) {
  setup();
}

public void changeIP(String theText) {
  // receiving text from controller texting
  println("New IP: "+theText);
  ip1 = theText;
  myRemoteLocation = new NetAddress(theText,10001);
  initializeMixer();
  //setup();
}

public void setDmxChan(String val, int id){
  //println(theText);
  println();
}

public void controlEvent(ControlEvent theEvent) {
  //println(theEvent.controller().id());
  //println("controlEvent: accessing a string from controller '"+theEvent.controller().name()+"': "+theEvent.controller().stringValue());
  if (theEvent.controller().name() == "dmxChan"){
  switch(theEvent.controller().id()) {
     case(0):
       channels[0] = int(theEvent.controller().stringValue());
       initializeMixer();
     break;
  
     case(1):
       channels[1] = int(theEvent.controller().stringValue());
       initializeMixer();
     break;
     
     case(2):
       channels[2] = int(theEvent.controller().stringValue());
       initializeMixer();
     break;
   
     case(3):
       channels[3] = int(theEvent.controller().stringValue());
       initializeMixer();
     break; 
     
     case(4):
       channels[4] = int(theEvent.controller().stringValue());
       initializeMixer();
     break;
     
     case(5):
       channels[5] = int(theEvent.controller().stringValue());
       initializeMixer();
     break;
   
     case(6):
       channels[6] = int(theEvent.controller().stringValue());
       initializeMixer();
     break;   
  
     case(7):
       channels[7] = int(theEvent.controller().stringValue());
       initializeMixer();
     break;
   }
  }

}
