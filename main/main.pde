// Required libraries
import blobscanner.*;
import processing.video.*;

// Instance of blobscanner that's used to detect 'blobs' (ie a ball on the video stream)
Detector bs;

// Required to be able to capture video
Capture video;

// variable for holding the current frame for manipulation
PImage currentFrame;

// Variables to be used when drawing bounding boxes to blobs
color boundingBoxColor = color(0, 255, 0);
int boundingBoxThickness = 1;

// This limits the amount of small blobs that are drawn
int minimumWeight = 2100;

// Treshold that's used in blob detection
int thres = 255;


void setup() {
  size(640, 480);
  frameRate(30);
  // Initialize the Detector with the given treshold
  bs = new Detector(this, thres);
  
  // Initialized the video instance for streaming video from camera
  video  = new Capture(this, width, height);
  
  // Start streaming
  video.start();
  
  // Makes the video object's pixels[] array available
  video.loadPixels();
}

void draw() {
  
  if (video.available()) {
    
    // Reads the latest frame
    video.read();
  
    // Makes the video object's pixels array available.
    // This is used in scanBlobs() method.
    video.loadPixels();
  }
  
  // Assign the latest frame to the currentFrame variable
  currentFrame = video;
  
  // Draw the frame to the screen
  image(currentFrame, 0, 0, width, height);
  
  // Once the frame is rendered, perform some operations to make 
  // blobscanning easier
  currentFrame.filter(INVERT);
  currentFrame.filter(THRESHOLD, 0.7);
  
  // Scan the blobs and draw bounding boxes
  scanBlobs(video.pixels);

}

/*
    All blob scanning is done here. The method takes a the pixels
    of the current frame of the video as a parameter, finds the blobs
    that are "heavy" enough and draws their bounding boxes.
    
    Loading the pixels instead of a PImage object is faster
    according to the blobscanner library's documentation
*/
void scanBlobs(int[] pixelArray) {
  // Must be called first before doing any operations with blobs
  bs.findBlobs(pixelArray, width, height);
  bs.loadBlobsFeatures();
  
  // Must be called before performing any operations related to blob weights
  bs.weightBlobs(true);
  
  // Draws bounding boxes to the blobs that weight at least minimumWeight
  bs.drawSelectBox(minimumWeight, boundingBoxColor, boundingBoxThickness);
}