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
import controlP5.*;

//---------------------------------------------------------------
// GLOBAL SETTINGS
// camera
int camResX = 640;
int camResY = 480;
int camRate = 60;

// jmyron
float threshold = 130;

// dev
boolean debug = true;
boolean capture = false;

// view
int ballStateCount = 10;
int avgStateCount = 7;

// glob detection
// - probability weights
float colorWeight = 0.3;
float positionWeight = 0.5;
float predictedPositionWeight = 0.5;
float sizeWeight = 0.4;
// - maximal values
float dColorMax = 8;
float dPositionMax = pow(11, 2);
float dPredictedPositionMax = pow(8, 2);
float dSizeMax = pow(5, 2);

// ball detection
float ballProbabilityThreshold = 0.2; // po jaké hodnotě se glob považuje za míček


// zapne fullscreen
boolean sketchFullScreen() {
	return true;
}

Myron m;
int[][] globArray;
int[][][] globPixels;

ControlP5 cp5;

int frameTimestamp;
int deltaTime;

PImage debugView;

// processing
Balls balls;

// view
Renderer renderer;

int[] lastCamPixels;
int[] camPixels;
//-----------------------------------------------------------------------------------------------------------
//SETUP
void setup() {
	// size(camResX, camResY);
	size(displayWidth, displayHeight);
	frameRate(-1);
	
	m = new Myron(this);
	if(! m.start(CLCamera.CLEYE_VGA, camRate) ) // 640x480, 60fps
		exit();
	
	m.threshold(threshold);

	debugView = createImage(camResX, camResY, ARGB);

	cp5 = new ControlP5(this);
	cp5.addSlider("brightnessThreshold", 0, 255, threshold, 10, 40, 128, 15).setNumberOfTickMarks(256);
	cp5.addSlider("ballProbabilityThreshold", 0, 1, ballProbabilityThreshold, 10, 70, 128, 15);
	if(!debug)
		cp5.hide();

	balls = new Balls();
	renderer = new Renderer(balls);

	renderer.init();

	lastCamPixels = new int[camResX*camResY];
	camPixels = new int[camResX*camResY];
}

//-----------------------------------------------------------------------------------------------------------
//DRAW

void draw() {
	m.update();

	// srovnání posledních obrázků
	// camPixels = m.camPixels;
	// boolean same = true;
	// for (int x = 0; x < camResX*camResY; x += 1) {
	// 	if(camPixels[x] != lastCamPixels[x]){
	// 		same = false;
	// 		break;
	// 	}
	// }
	// if(same){
	// 	println("tadá :(");
	// 	return;
	// }
	// arrayCopy(camPixels, lastCamPixels);

	int now = millis();
	deltaTime = now - frameTimestamp;
	frameTimestamp = now;
	
	// pushMatrix();

	// scale(min(width/float(camResX), height/float(camResY)));
	background(0); //Set background black

	globArray = m.globBoxes();
	globPixels = m.globEdgePoints();
	if(debug){
		// Zobrazí obrázek z webkamery
		m.debugPixels(m.camPixels);
		// m.debugPixels(m.globPixels);

		for(int i=0;i<globArray.length;i++){
			int[][] boundary = globPixels[i];
			int[] globBox = globArray[i];

			boolean inside = false;
			for (int j = i-1; j >= 0; j--) { // zneužívá se tady toho, že pokud glob bude v jiném globu, ten glob je před ním
				int[] glob2 = globArray[j];
				if(glob2[0] < globBox[0] && glob2[1] < globBox[1] && glob2[0]+glob2[2] > globBox[0]+globBox[2] && glob2[1]+glob2[3] > globBox[1]+globBox[3]){
					inside = true;
					break;
				}
			}
			if(inside){
				continue;
			}

			stroke(255, 0, 0);
			strokeWeight(1);
			if(boundary!=null){
				beginShape(POINTS);
				for(int j=0;j<boundary.length;j+=3){
					vertex(boundary[j][0], boundary[j][1]);
				}
				endShape();
			}

			// stroke(255, 0, 0);
			// textAlign(LEFT, BOTTOM);
			// text(i, globBox[0], globBox[1]);
			// rect(globBox[0], globBox[1], globBox[2], globBox[3]);
		}
	}

	balls.processGlobs(globArray, globPixels);

	if(debug){
		balls.render();
	}
	// popMatrix();

	if(!debug){
		renderer.render();
	}

	if(debug) {
		fill(255,255,0);
		textSize(16);
		textAlign(RIGHT, BOTTOM);
		text(int(frameTimestamp), width-10, height-10);
	}

	if(capture){
		saveFrame("frames/####.tga");
	}

	if(debug){
		// FPS
		fill(255,255,0);
		textSize(16);
		textAlign(RIGHT, TOP);
		text(int(frameRate), width-10, 0);
	}

}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------
//User input - calibrating camera and animation
	
void brightnessThreshold(float t) {
	threshold = t;
	m.threshold(threshold);
}

//by pressing arrow key up and down you animate movement of previous frames along x axis 
//(originally designed to flow in the left direction-UP arrow key or stay static - program value is 0)
void keyPressed() {
	switch(keyCode) {
		case ' ': 
			saveFrame("diagram-####.jpg"); //tga is the fastest..but you can specify jpg,png...
			break;
		case 'A':
			// m.adapt();
			// color c = m.average(0, 0, camResX, camResY);
			// m.trackNotColor(int(red(c)), int(green(c)), int(blue(c)), 255);
			balls.adapt();
			break;
		case 'D':
			debug = !debug;
			if(debug)
				cp5.show();
			else
				cp5.hide();

			break;
		case 'C':
			capture = !capture;
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
