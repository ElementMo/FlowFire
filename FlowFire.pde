
import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;

import controlP5.Accordion;
import controlP5.ControlP5;
import controlP5.Group;
import controlP5.RadioButton;
import controlP5.Toggle;
import processing.core.*;
import processing.opengl.PGraphics2D;
import processing.video.Capture;

import KinectPV2.*;


int cam_w = 1024;
int cam_h = 576;
int fluidgrid_scale = 0;


// main library context
DwPixelFlow context;

// collection of imageprocessing filters
DwFilter filter;

// fluid solver
DwFluid2D fluid;

MyFluidData cb_fluid_data;

// optical flow
DwOpticalFlow opticalflow;

// buffer for the capture-image
PGraphics2D pg_cam_a, pg_cam_b; 

// offscreen render-target for fluid
PGraphics2D pg_fluid;

// camera capture (video library)
Capture cam;
KinectPV2 kinect;
PImage body;




// some state variables for the GUI/display
boolean DISPLAY_SOURCE   = true;
boolean APPLY_GRAYSCALE  = false;
boolean APPLY_BILATERAL  = true;
int     VELOCITY_LINES   = 1;

boolean UPDATE_FLUID            = true;
boolean DISPLAY_FLUID_TEXTURES  = true;
boolean DISPLAY_FLUID_VECTORS   = !true;
boolean DISPLAY_PARTICLES       = !true;

public void settings() {
  fullScreen(P2D);
  smooth(4);
}

public void setup() {

  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.enablePointCloud(true);
  
  kinect.setLowThresholdPC(0);
  kinect.setHighThresholdPC(2000);
  kinect.init();

  // main library context
  context = new DwPixelFlow(this);
  context.print();
  context.printGL();

  filter = new DwFilter(context);

  // fluid object
  fluid = new DwFluid2D(context, cam_w, cam_h, fluidgrid_scale);

  // some fluid parameters
  fluid.param.dissipation_density     = 0.60f;
  fluid.param.dissipation_velocity    = 0.6f;
  fluid.param.vorticity               = 0.10f;

  // calback for adding fluid data
  cb_fluid_data = new MyFluidData();
  fluid.addCallback_FluiData(cb_fluid_data);

  // optical flow object
  opticalflow = new DwOpticalFlow(context, cam_w, cam_h);

  // render buffers
  pg_cam_a = (PGraphics2D) createGraphics(cam_w, cam_h, P2D);
  pg_cam_a.noSmooth();
  pg_cam_a.beginDraw();
  pg_cam_a.background(0);
  pg_cam_a.endDraw();

  pg_cam_b = (PGraphics2D) createGraphics(cam_w, cam_h, P2D);
  pg_cam_b.noSmooth();

  pg_fluid = (PGraphics2D) createGraphics(cam_w, cam_w, P2D);
  pg_fluid.smooth(4);

  background(0);
  frameRate(120);
}




public void draw() {
  body = kinect.getBodyTrackImage();
  //cam.read();
  // render to offscreenbuffer
  pg_cam_b.beginDraw();
  pg_cam_b.image(body, 0, 0, cam_w, cam_h);
  pg_cam_b.endDraw();
  swapCamBuffer(); // "pg_cam_a" has the image now

  if (APPLY_BILATERAL) {
    filter.bilateral.apply(pg_cam_a, pg_cam_b, 5, 0.10f, 4);
    swapCamBuffer();

    // update Optical Flow
    opticalflow.update(pg_cam_a);

    if (APPLY_GRAYSCALE) {
      // make the capture image grayscale (for better contrast)
      filter.luminance.apply(pg_cam_a, pg_cam_b); 
      swapCamBuffer();
    }
  }



  fluid.update();
  // render everything
  pg_fluid.beginDraw();
  pg_fluid.background(0);
  //pg_fluid.clear();
  pg_fluid.endDraw();

  // add fluid stuff to rendering
  if (DISPLAY_FLUID_TEXTURES) {
    fluid.renderFluidTextures(pg_fluid, 0);
  }

  // display result
  background(0);
  image(pg_fluid, 0, 0, width, height);
}


void swapCamBuffer() {
  PGraphics2D tmp = pg_cam_a;
  pg_cam_a = pg_cam_b;
  pg_cam_b = tmp;
}




public void fluid_resizeUp() {
  fluid.resize(width, height, fluidgrid_scale = max(1, --fluidgrid_scale));
}
public void fluid_resizeDown() {
  fluid.resize(width, height, ++fluidgrid_scale);
}
public void fluid_reset() {
  fluid.reset();
}
public void fluid_togglePause() {
  UPDATE_FLUID = !UPDATE_FLUID;
}

public void fluid_displayVelocityVectors(int val) {
  DISPLAY_FLUID_VECTORS = val != -1;
}
public void fluid_displayParticles(int val) {
  DISPLAY_PARTICLES = val != -1;
}
public void opticalFlow_setDisplayMode(int val) {
  opticalflow.param.display_mode = val;
}
public void activeFilters(float[] val) {
  APPLY_GRAYSCALE = (val[0] > 0);
  APPLY_BILATERAL = (val[1] > 0);
}
public void setOptionsGeneral(float[] val) {
  DISPLAY_SOURCE = (val[0] > 0);
}