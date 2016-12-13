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

boolean scored = false;

boolean gameOver = false;

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
  initTarget();
  */
  
  initFonts();

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
  
  if (gameOver) {
    println("Game over");
    cam.stop();
    noLoop();
    drawGameover();
  }
  
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
    if (frameCount % 30 == 0) {
      reloadBlobs(cam);
      updateROI();
    }
    
    // Every 3rd frame, check if there is another blob inside the target
    if (frameCount % 5 == 0) {
      checkCollision();
    }
    
    // Draws bounding boxes of blobs
    //drawBlobs();
    
    /*
    // Adjust the input volume according to cyrsor's Y-position
    updateVolume();
    
    // Adjust the scale of the music visualizer according to volume amplitude
    updateScale();
    
    // Render the visualizer circle around the target
    drawVisualizer();
    
    // Render the target
    drawTarget();
    */
    
    // Render time and score
    drawText();
    
  } else {
    //println("Video was not available");
  }

  // Only for debugging purposes
  //displayFps();
  //drawRoiRect();
}

/*
    Checks if there is a blob inside ROI (which is set to be pretty much the target)
    without inversing the image. Thus, this method will find a white blob inside the
    target rectangle.
*/
void checkCollision() {

  int[] roiParams = bs.getRoiParameters();
  PImage copy = cam;
  copy.filter(INVERT);
  
  // For debugging, uncomment following to visualize when collision check takes place
  //image(copy, 0, 0);

  // To find blobs inside the target, set the ROI smaller
  bs.setRoi(roiParams[0]+50,   // target's X coordinate
            roiParams[1]+50,   // target's Y coordinate
            roiParams[2]-100,   // target's width
            roiParams[3]-100);  // target's height
  
  // Draw the ROI rectangle to help visualize where it is
  //drawRoiRect();
  
  // Find the blobs inside the target
  bs.findBlobs(copy.pixels, copy.width, copy.height);
  bs.loadBlobsFeatures();
  bs.weightBlobs(true);
  
  // There's a white thing inside the target => SCORE!!
  if (bs.getBlobsNumber() > 0) {
    if (bs.getBlobWeight(findHeaviestBlob()) > 9000) {
      scored = true;
    }
  }
  
  // Increment score
  if (scored) score++;
  scored = false;
  
  // Set the original ROI back
  bs.setRoi(roiParams[0],
            roiParams[1],
            roiParams[2],
            roiParams[3]);
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
  bs.weightBlobs(false);
  bs.loadBlobsFeatures();
  bs.findCentroids();

  // True if blobs were found.
  blobsFound = bs.getBlobsNumber() > 0;
  //println("Found " + bs.getBlobsNumber() + " blobs");
}


/* 
    Returns the blobNumber of heaviest (== biggest) blob on camera
*/
int findHeaviestBlob() {
  //println("Finding heaviest blob");
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
  
  int x = (int)bs.getCentroidX(blobIndex);
  int y = (int)bs.getCentroidY(blobIndex);
  int w = bs.getBlobWidth(blobIndex);
  int h = bs.getBlobHeight(blobIndex);

  // Set roi dimensions to be a bit larger than the blob
  int roiX = (int)((x - w/2) - w/8);
  int roiY = (int)((y - h/2) - h/8);
  int roiW = (int)(w*1.2);
  int roiH = (int)(h * 1.2);

  // Set ROI according the previous properties
  bs.setRoi( roiX, 
             roiY, 
             roiW, 
             roiH);

  //println("ROI set according to blob number " + blobIndex);
}


/*
    Blobscanner requires B/W picture for scanning.
    Since the background screen is white, first invert
    colours and then assign everything to black or white
    depending on their  brightness after the invertion.
*/
void processFrameForScanning(PImage frame) {
  frame.filter(INVERT);
  frame.filter(THRESHOLD, 0.7);
}


/*
    Unset ROI, recalculate it's position and reset it
*/
void updateROI() {
  //println("Setting ROI");
  bs.unsetRoi();
  isRoiSet = false;
  setRoiAroundBlob(findHeaviestBlob());
  isRoiSet = true;
}

void restart() {
  score = 0;
  interval = 60;
  gameOver = false;
  cam.start();
  cam.loadPixels();
  loop();
}

void keyPressed() {
  if (gameOver && key == ' ') {
    restart();
  }
}