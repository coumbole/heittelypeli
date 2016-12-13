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
int radius;
color ellipseColor1, ellipseColor2, ellipseMusicColor, fontColor;

color BLACK = color(0, 0, 0);
color WHITE = color(255);
color LIGHTGRAY = color(250, 255, 250);
color TEAL = color(6, 66, 92);

int targetX, targetY;

void initAudio() {
  //Create an Audio input and grab the 1st channel
  input = new AudioIn(this, 0);
  
  // start the Audio Input
  input.start();
  
  // create a new Amplitude analyzer
  rms = new Amplitude(this);
  
  // Patch the input to an volume analyzer
  rms.input(input);  
}

void initFonts() {
  
  // Countdown and Score
  font = createFont("Arial", 50);
  fontColor = BLACK;
}

void initTarget() {
  
  score = 0;
  
  // Circle properties
  radius = 150;
  targetX = width/2;
  targetY = height/2;
}


// Adjust the volume according to the cursor position
void updateVolume() {
  input.amp(map(mouseY, 0, height, 0.0, 1.0));
}


// Adjust the scale depending on the amplitude of input
void updateScale() {
  scale = (int)map(rms.analyze(), 0, 0.5, 1, 350);
}


// Render the music visualizer circle
void drawVisualizer() {
  noStroke();
  fill(LIGHTGRAY);
  stroke(200);
  ellipse(targetX, targetY, radius + scale, radius + scale);
}


// Render the target for throwing
void drawTarget() {
  
  // Changing radius for targets, starting from radius-value
  int ellipse = radius;
  
  // Draw 5 inner circles to visualize the target
  for(int i = 5; i > 0; i--){
    
    // Change the colour on every other circle
    if (i % 2 == 1){
      fill(TEAL);
      stroke(TEAL);
    } else {
      fill(WHITE);
      stroke(WHITE);
    }
    
    // Draw the target
    ellipse(targetX, targetY, ellipse, ellipse);
    
    // Reduce the radius to draw the inner circles
    ellipse -= radius/5;
  }
  
  fill(BLACK);
  t = interval - (int) millis() / 1000;
  if(t > -1){
    time = nf(t , 2);
  }
  /* // Loop countDown
  if(t == 0){
      interval += 60;
  }
  */
}


void drawText() {
  text(time, width/2, 25);
  text("Score:  " + score, width - 100, 25);
}