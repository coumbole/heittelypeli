/*
    Prints the list of available cameras to console.
    Useful for debugging if no video is shown
*/
void findCameras() {
  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
  }
}


// Draw a red rectangle to the screen to where the roi is currently at
// Only for debugging purposes
void drawRoiRect() {
  if (isRoiSet) {
    int[] params = bs.getRoiParameters();
    
    stroke(255, 0, 0);
    noFill();
    strokeWeight(2);
    rect(params[0], params[1], params[2], params[3]);
  }
}

/*
    Displays how many frames per second the program runs
*/
void displayFps() {
  textSize(36);
  text(frameRate, 10, 30);
}