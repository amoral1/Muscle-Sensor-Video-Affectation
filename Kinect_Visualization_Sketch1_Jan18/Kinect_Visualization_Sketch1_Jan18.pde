// Daniel Shiffman
// Tracking the average location beyond a given depth threshold
// Thanks to Dan O'Sullivan

// https://github.com/shiffman/OpenKinect-for-Processing
// http://shiffman.net/p5/kinect/

import org.openkinect.freenect.*;
import org.openkinect.processing.*;

// The kinect stuff is happening in another class
KinectTracker tracker;
Kinect kinect;


void setup() {
  //size(640, 520, P3D);
  kinect = new Kinect(this);
  tracker = new KinectTracker();
}


void draw() {
  background(55); //255= white

  // Run the tracking analysis
  tracker.track();
  // Show the image
  tracker.display();

  // Let's draw the raw location
  PVector v1 = tracker.getPos();
  fill(50, 100, 250, 200);
  noStroke();
  ellipse(v1.x, v1.y, 20, 20);

  // Let's draw the "lerped" location
  PVector v2 = tracker.getLerpedPos();
  fill(0, 0, 50, 200);
  noStroke();
  ellipse(v2.x, v2.y, 20, 20);


  // Display some info
 int t = tracker.getThreshold();
  fill(0);
  text("threshold: " + t + "    " +  /*"framerate: " + int(frameRate) + */"    " + 
    "UP increase threshold, DOWN decrease threshold", 10, 500);
    
}

// Adjust the threshold with key presses
void keyPressed() {
  int t = tracker.getThreshold();
  if (key == CODED) {
    if (keyCode == UP) {
      t+=19;
      tracker.setThreshold(t);
    } else  if(keyCode == DOWN) {
      t-=50;
      tracker.setThreshold(t);
    }
  }
}
