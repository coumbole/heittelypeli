// Required libraries
import blobscanner.*;
import processing.video.*;

// Instance of blobscanner that's used to detect 'blobs' (ie a ball on the video stream)
Detector bs;

// Required to be able to capture video
Capture cam;

// Variables to be used when drawing bounding boxes to blobs
color boundingBoxColor = color(0, 255, 0);
int boundingBoxThickness = 1;

// This limits the amount of small blobs that are drawn
int minimumWeight = 5000;

// Threshold that's used in blob detection
int thres = 255;

// This is changed to true if reloadBlobs() method finds more than 1 blob
boolean blobsFound = false;

// This is set to true when ROI is set to something
boolean isRoiSet = false;



void setup() {
  size(1280, 720);
  frameRate(25);
  
  // Initialize the Detector with the given treshold
  bs = new Detector(this, thres);

  // Set an initial ROI to make startup lighter
  bs.setRoi(width/4, height/4, width/2, height/2);
  isRoiSet = true;

  /*
  initAudio();
  initFonts();
  initTarget();
  */

  // Uncomment to have the list of available cameras printed to the console
  //findCameras();

  // Initialized the video instance for streaming video from camera
  cam = new Capture(this, width, height);

  // Start streaming
  cam.start();

  // Makes the video object's pixels[] array available
  cam.loadPixels();
}


void draw() {
  
  // Only run the following code if a new cam frame is available
  if (cam.available()) {

    // Reads the latest frame from camera
    cam.read();

    // Makes the pixels[] array of cam available. Array is required by findBlobs() method
    cam.loadPixels();

    // Render the frame to the screen
    image(cam, 0, 0, width, height);

    // Invert and filter the frame. Required by blobscanner
    processFrameForScanning(cam);

    // Recalculate all blobs inside the ROI approx. once a second
    if (frameCount % 30 == 0 || frameCount == 1) {
      reloadBlobs(cam);
    }

    // Every 3 seconds or so, reset roi according to the heaviest blob
    if (frameCount % 90 == 0) {
      updateROI();
    }

    
    
    // Draws bounding boxes of blobs
    drawBlobs();
    
    /*
    // Adjust the input volume according to cyrsor's Y-position
    updateVolume();
    
    // Adjust the scale of the music visualizer according to volume amplitude
    updateScale();
    
    // Render the visualizer circle around the target
    drawVisualizer();
    
    // Render the target
    drawTarget();
    
    // Render time and score
    drawText();
    
    */
    
  } else {
    println("Video was not available");
  }

  // Only for debugging purposes
  displayFps();
  drawRoiRect();
}


/*
    Draws bounding boxes to blobs that are heavy enough
*/
void drawBlobs() {
  // Only run if more than 1 blobs are found in reloadBlobs() method
  if (blobsFound) {
    bs.drawSelectBox(minimumWeight, boundingBoxColor, boundingBoxThickness);
  }
}


/*
    These must be called before performing any other operations on blobs.
 However, it's probably not necessary to call this every single frame
 since these are pretty heavy operations
 
 Loading the pixels from Piamge instead of a PImage object itself is faster
 according to the blobscanner library's documentation
 
 If no blobs are found (ie. getBlobsNumber() returns 0, blobsFound variable,
 is false, and thus 
 */
void reloadBlobs(PImage frame) {
  //println("Reloading blobs");
  bs.findBlobs(frame.pixels, frame.width, frame.height);
  bs.weightBlobs(true);
  bs.loadBlobsFeatures();
  bs.findCentroids();

  // True if blobs were found.
  blobsFound = bs.getBlobsNumber() > 0;
  println("Found " + bs.getBlobsNumber() + " blobs");
}


/* 
    Returns the blobNumber of heaviest (== biggest) blob on camera
*/
int findHeaviestBlob() {
  println("Finding heaviest blob");
  // By default the heaviest blob is the blob at index 0
  int currentHeaviestBlobNum = 0;

  // No reason to do the comparison unless there's more than 1 blob
  if (bs.getBlobsNumber() > 1) {

    // Loop through all the blobs
    for (int i = 1; i < bs.getBlobsNumber(); i++) {

      // Compare the weights of the blob at index i and the blob that's currently the heaviest one
      if (bs.getBlobWeight(i) > bs.getBlobWeight(currentHeaviestBlobNum)) {
        currentHeaviestBlobNum = i;
      }
    }
  }
  // Helpful debug messages
  //println("Heaviest blobNum: " + currentHeaviestBlobNum);
  //println("Weigth of heaviest blob: " + bs.getBlobWeight(currentHeaviestBlobNum));

  return currentHeaviestBlobNum;
}


/*
    This is used to set the ROI (region of interest) so that 
    blobscanner only scans for blobs (incoming/flying balls)
    around the target. This is cheaper in terms of computing resources
    and improves efficiency. 
     
    However, this pretty much assumes that the player is directly behind the target,
    so that the ball is not thrown from the side. In that case, blobscanner
    most likely would not be able to track it fast enough.
     
    Below is a picture of screen, the bounding box
    of the target and the ROI around the target
     
    SCREEN
    -------------------------------------
    |      |           |                |
    |      |    ROI    |                |
    |      |           |                |
    |      |  -------  |                |
    |      |  | tar |  |                |
    |      |  | get |  |                |
    |      |  -------  |                |
    |      |           |                |
    |      |    ROI    |                |
    |      |           |                |
    -------------------------------------
         
 */
void setRoiAroundBlob(int blobIndex) {
  // get the blob properties that are used for setting the ROI
  int x = (int)bs.getCentroidX(blobIndex);
  int y = (int)bs.getCentroidY(blobIndex);
  int w = bs.getBlobWidth(blobIndex);
  int h = bs.getBlobHeight(blobIndex);

  // Set roi dimensions to be a bit larger than the blob
  int roiX = (int)constrain((x - w/2) - w/4, 0, width-w);
  int roiY = (int)constrain((y - h/2) - h/4, 0, height - h);
  int roiW = (int)constrain(w * 1.3, 0, width);
  int roiH = (int)constrain(h * 1.3, 0, height);

  // Set ROI according the previous properties
  bs.setRoi( roiX, 
             roiY, 
             roiW, 
             roiH);

  println("ROI set according to the heaviest blob");
}


/*
    Blobscanner requires B/W picture for scanning.
    Since the background screen is white, first invert
    colours and then assign everything to black or white
    depending on their  brightness after the invertion.
*/
void processFrameForScanning(PImage frame) {
  frame.filter(INVERT);
  frame.filter(THRESHOLD, 0.5);
}


/*
    Unset ROI, recalculate it's position and reset it
*/
void updateROI() {
  println("Setting ROI");
  bs.unsetRoi();
  isRoiSet = false;
  setRoiAroundBlob(findHeaviestBlob());
  isRoiSet = true;
}