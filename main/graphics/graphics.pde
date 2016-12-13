// Needed libraries
import processing.sound.*;

AudioIn input;
Amplitude rms;

int scale=1;
PFont font;
String time = "60";
int t;
int interval = 60;
int score;
int ellipseSize;
color ellipseColor1, ellipseColor2, ellipseMusicColor, fontColor;
int x1,x2,y1,y2;
void setup() {
    size(640,360);
    background(255);
        
    //Create an Audio input and grab the 1st channel
    input = new AudioIn(this, 0);
    
    // start the Audio Input
    input.start();
    
    // create a new Amplitude analyzer
    rms = new Amplitude(this);
    
    // Patch the input to an volume analyzer
    rms.input(input);
    
    // Countdown and Score
    font = createFont("Arial", 50);
    fontColor = color(0,0,0);
    
    score = 0;
    
    // Data for targets
    ellipseSize = 150;
    ellipseColor1 = color(255);
    ellipseColor2 = color(6,66,92);
    ellipseMusicColor = color(250, 255, 250);
    x1 = width/4;
    x2 = 3 * width/4;
    y1 = height/ 2;
    y2 = height / 2;
}      


void draw() {
    background(255);
    
    // adjust the volume of the audio input
    input.amp(map(mouseY, 0, height, 0.0, 1.0));
    
    // rms.analyze() return a value between 0 and 1. To adjust
    // the scaling and mapping of an ellipse we scale from 0 to 0.5
    scale=int(map(rms.analyze(), 0, 0.5, 1, 350));
    noStroke();
    
    // Ellipse for audio presentation
    fill(ellipseMusicColor);
    stroke(200);
    ellipse(x1, y1, ellipseSize + 1*scale, ellipseSize + 1*scale);
    ellipse(x2, y2, ellipseSize + 1*scale, ellipseSize + 1*scale);
    
    // Target visualization
    int ellipse = ellipseSize;
    for(int i = 5; i!=0; i--){
      if (i%2==1){
        fill(ellipseColor2);
        stroke(ellipseColor2);
      } else {
        fill(ellipseColor1);
        stroke(ellipseColor1);
      }
      ellipse(x1, y1, ellipse, ellipse);
      ellipse(x2, y2, ellipse, ellipse);
      ellipse -= ellipseSize/5;
    }
    
    fill(fontColor);
    t = interval-int(millis()/1000);
    if(t > -1){
        time = nf(t , 2);
    }
    /* // Loop countDown
    if(t == 0){
        interval += 60;
    }
    */

   text(time, width/2, 25);
   text("Score:  " + score, width - 100, 25);
}