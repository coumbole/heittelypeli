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
int minimumWeight = 10000;

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
  
  // Set an initial ROI
  bs.setRoi(width/3, 100, width/3, height-100);
  isRoiSet = true;
  
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
  //background(100);
  
  // Only run the following code if a new cam frame is available
  if (cam.available()) {
    
    // Every 3 seconds or so, reset roi according to the heaviest blob
    if (frameCount % 90 == 0) {
      println("Setting ROI");
      bs.unsetRoi();
      isRoiSet = false;
      setRoiAroundBlob(findHeaviestBlob());
      isRoiSet = true;
    }
    
    // Reads the latest frame from camera
    cam.read();
    
    // Makes the pixels[] array of cam available.
    // Used in blobdetection
    cam.loadPixels();
    
    // Draw the frame to the screen
    image(cam, 0, 0, width, height);
    
    // An alternate way to render the image to the screen
    // Not sure which is faster, or if the difference is significant at all
    //set(0, 0, currentFrame);
    
    // Once the frame is rendered, perform some operations to make 
    // blobscanning easier. It's nicer to view proper video than inverted
    // and filtered video
    cam.filter(INVERT);
    cam.filter(THRESHOLD, 0.5);
  
    // Prevent reloading of blobs on every frame, and instead reload them ~ once a second
    if (frameCount % 30 == 0) {
      reloadBlobs(cam);
    }

    // Draws bounding boxes of blobs that are heavy enough
    drawBlobs();
    
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
  println("Heaviest blobNum: " + currentHeaviestBlobNum);
  println("Weigth of heaviest blob: " + bs.getBlobWeight(currentHeaviestBlobNum));
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
  // get the x coordinate and width of the blob
  int x = (int)bs.getCentroidX(blobIndex);
  int y = (int)bs.getCentroidY(blobIndex);
  int w = bs.getBlobWidth(blobIndex);
  int h = bs.getBlobHeight(blobIndex);
  
  int roiX = (int)constrain((x - w/2) - w/4, 0, width-w);
  int roiY = (int)constrain((y - h/2) - h/4, 0, height - h);
  int roiW = (int)constrain(w * 1.5, 0, width);
  int roiH = (int)constrain(h * 1.5, 0, height);
  
  bs.setRoi( roiX,
             roiY,
             roiW,
             roiH);
  
  println("ROI set according to the heaviest blob");
}