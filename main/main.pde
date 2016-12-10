
// Required libraries
import blobscanner.*;
import processing.video.*;

// Instance of blobscanner that's used to detect 'blobs' (ie a ball on the video stream)
Detector bs;

// Required to be able to capture video
Capture video;

// Treshold that's used in blob detection
int treshold = 200;

void setup() {
  size(640, 480);
  frameRate(25);
  // Initialize the Detector with the given treshold
  bs = new Detector(this, treshold);
  
  // Initialized the video instance for streaming video from camera
  video  = new Capture(this, width, height);
  
  // Start streaming
  video.start();
  
  // Makes the video object's pixels[] array available
  loadPixels();
}

void draw() {
  //println("Video available: " + video.available());
    
  // Each frame, before doing anything, make sure that the video is available
  if (video.available()) {
    
    // Read the new frame from the camera
    video.read();
    
    // Make its pixels[] array available
    video.loadPixels();
  }
  
  // Draws the current frame on screen
  image(video, 0, 0, width, height);
}