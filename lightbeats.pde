/**
 * "Light beats" version 2.0
 * © 2014, http://lightbeats.cz/
 * Creative commons license BY-NC-SA Attribution-NonCommercial-ShareAlike for more information see: http://creativecommons.org/licenses/by-nc-sa/4.0/
 * Creative commons licence BY-NC-SA Uveďte autora-Neužívejte dílo komerčně-Zachovejte licenci 
 * the author disclaims all warranties with regard to this software including all implied warranties of merchantability and fitness. in no event shall the author be liable for any special, direct, indirect, or consequential damages or any damages whatsoever resulting from loss of use, data or profits, whether in an action of contract, negligence or other tortious action, arising out of or in connection with the use or performance of this software. 
 
 * Make a brightness treshold,
 * than buffer previous frames and animate them translated negatively on x axis. 
 * Visualization represent graphical juggling notation diagrams used by jugglers and known as siteswaps.
 * dependencies: Jmyron processing library, processing 2.2.1, webcam (originally designed for PS3eye)
 
 *Use arrows UP, DOWN for controlling speed of movement along x-axis 
 *Use arrows LEFT, RIGHT to controll the brightness treshold
 *Spacebar will save snapshot to the sketch folder
 *by clicking on running sketch the camera settings should appear
 */

import JMyron.*;
import gab.opencv.*;

//---------------------------------------------------------------
// GLOBAL SETTINGS
// camera
int camResX = 640;
int camResY = 480;

// jmyron
float threshold = 130;

// dev
boolean debug = true;

// view
int ballStateCount = 10;
int avgStateCount = 5;

// glob detection
// - probability weights
float colorWeight = 0.4;
float positionWeight = 0.4;
float predictedPositionWeight = 0.0;
float sizeWeight = 0.3;
// - maximal values
float dColorMax = 255;
float dPositionMax = pow(100, 2);
float dPredictedPositionMax = pow(100, 2);
float dSizeMax = pow(20, 2);

// prediction
float correctionWeight = 0.5;

// ball detection
float ballProbabilityThreshold = 0.8; // po jaké hodnotě se glob považuje za míček


// zapne fullscreen
boolean sketchFullScreen() {
	return true;
}

int find (float needle, float[] haystack) {
	for (int i = 0; i < haystack.length; i++) {
		if(haystack[i] == needle)
			return i;
	}
	return -1;
}

JMyron m;
OpenCV opencv;
int[][] globArray;

int program = -3; //controlling speed along x axis, on start stay static until UP or DOWN arrow keys are pressed; 

boolean capture = false;

PImage debugView;

// processing
Balls balls;


//-----------------------------------------------------------------------------------------------------------
//SETUP

void setup() {
	size(displayWidth, displayHeight);
	
	m = new JMyron();
	m.start(camResX, camResY);
	m.findGlobs(1);
	// m.trackColor(0, 44, 222, 255); //track the brightest
	// m.adaptivity(2);
	m.trackNotColor(0,0,0,255);
	m.minDensity(250);
	m.maxDensity(1000);
	m.sensitivity(threshold);

	opencv = new OpenCV(this, camResX, camResY);

	ellipseMode(CENTER); //we draw ellipse from center
	noStroke();
	
	debugView = createImage(camResX, camResY, ARGB);

	balls = new Balls();
}

//-----------------------------------------------------------------------------------------------------------
//DRAW

void draw() {
	// scale(displayWidth/camResX, displayHeight/camResY);
	scale(min(displayWidth/float(camResX), displayHeight/float(camResY)));
	background(0); //Set background black
	m.update();
	
	if(debug){
		m.imageCopy(debugView.pixels);
		debugView.updatePixels();
		image(debugView, 0, 0);
	}
	// opencv.loadImage(debugView);
	// opencv.findCannyEdges(20, 75);
	// ArrayList<Line> lines = opencv.findLines(100, 30, 20);

	// image(opencv.getOutput(), 0, 0);

	// strokeWeight(3);
	// for (Line line : lines) {
	// 	// lines include angle in radians, measured in double precision
	// 	// so we can select out vertical and horizontal lines
	// 	// They also include "start" and "end" PVectors with the position
	// 	if (line.angle >= radians(0) && line.angle < radians(1)) {
	// 		stroke(0, 255, 0);
	// 		line(line.start.x, line.start.y, line.end.x, line.end.y);
	// 	}

	// 	if (line.angle > radians(89) && line.angle < radians(91)) {
	// 		stroke(255, 0, 0);
	// 		line(line.start.x, line.start.y, line.end.x, line.end.y);
	// 	}
	// }

	globArray = m.globBoxes();

	if(debug){
		// draw the glob bounding boxes
		// for(int i = 0; i < globArray.length; i++) {
		// 	int[] boxArray = globArray[i];
		
		// 	noFill();
		// 	strokeWeight(3);
		// 	stroke(255, 0, 0);
		// 	rect(boxArray[0], boxArray[1], boxArray[2], boxArray[3]);
		// 	strokeWeight(1);
		// 	noStroke();
		// }

		// int list[][][] = m.globPixels();
		// stroke(255, 0, 0);

		// for(int i=0;i<list.length;i++){
		// int[][] pixellist = list[i];
		// if(pixellist!=null){
		//   // beginShape(POINTS);
		//   for(int j=0;j<pixellist.length;j++){
		//   	if(j % 10 == 0)
		//     	point( pixellist[j][0]  ,  pixellist[j][1] );
		//     // vertex( pixellist[j][0]  ,  pixellist[j][1] );
		//    // print( pixellist[j][0]  +" " +  pixellist[j][1] );
		//   }
		//   // endShape();
		//  }
		// }
		//draw edge points (same as last, but vector based)
		// int list[][][] = m.globEdgePoints(20);
		// stroke(255, 0, 0);
		// for(int i=0;i<list.length;i++){
		// int[][] contour = list[i];
		// if(contour!=null){
		//   for(int j=0;j<contour.length - 1;j++){    
		//     line( contour[j][0]  ,  contour[j][1], contour[j+1][0]  ,  contour[j+1][1] );
		//   }
		//  }
		// }
	}

	balls.processGlobs(globArray, m.image());
	balls.render();

	if(capture && frameCount % 10 == 0){
		saveFrame();
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------
//User input - calibrating camera and animation
	
void mousePressed(){
	m.settings();//click the window to get the settings of camera
}

//by pressing arrow key up and down you animate movement of previous frames along x axis 
//(originally designed to flow in the left direction-UP arrow key or stay static - program value is 0)
void keyPressed(){
	switch(keyCode) {
	case UP: 
			program --;
			break;
	case DOWN: 
			program ++;
			break;
	case LEFT: 
			threshold --;
			m.sensitivity(threshold);
			break;
	case RIGHT: 
			threshold ++;
			m.sensitivity(threshold);
			break;
	case ' ': 
			saveFrame("diagram-####.jpg"); //tga is the fastest..but you can specify jpg,png...
			break;
	case 'A':
			// m.adapt();
			color c = m.average(0, 0, camResX, camResY);
			m.trackNotColor(int(red(c)), int(green(c)), int(blue(c)), 255);
			balls.adapt();
			break;
	case 'D':
			debug = !debug;
			break;
	case 'C':
			capture = !capture;
			break;
	case 'Q':
			stop();
			break;
	case 27: // ESCAPE
			stop();
			break;

	}
}
//-----------------------------------------------------------------------------------------------------------
public void stop() {
	m.stop();
	super.stop();
}
