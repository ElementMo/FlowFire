private class MyFluidData implements DwFluid2D.FluidData {

  @Override
    // this is called during the fluid-simulation update step.
    public void update(DwFluid2D fluid) {

    // use the text as input for density
    addDensityTexture (fluid, opticalflow);
    addDensityTexture_cam(fluid, opticalflow);

    //addTemperatureTexture(fluid, opticalflow);
    addVelocityTexture(fluid, opticalflow);
  }

  // custom shader, to add density from a texture (PGraphics2D) to the fluid.
  public void addDensityTexture(DwFluid2D fluid, DwOpticalFlow opticalflow) {
    context.begin();
    context.beginDraw(fluid.tex_density.dst);
    DwGLSLProgram shader = context.createShader("data/addDensity.frag");
    shader.begin();
    shader.uniform2f     ("wh", fluid.fluid_w, fluid.fluid_h);                                                                   
    shader.uniform1i     ("blend_mode", 6);    
    shader.uniform1f     ("multiplier", 3);    
    shader.uniform1f     ("mix_value", 0.1f);
    shader.uniformTexture("tex_opticalflow", opticalflow.frameCurr.velocity);
    shader.uniformTexture("tex_density_old", fluid.tex_density.src);
    shader.drawFullScreenQuad();
    shader.end();
    context.endDraw();
    context.end("app.addDensityTexture");
    fluid.tex_density.swap();
  }


  public void addDensityTexture_cam(DwFluid2D fluid, DwOpticalFlow opticalflow) {
    int[] pg_tex_handle = new int[1];

    if ( !pg_cam_a.getTexture().available() ) return;

    float mix = opticalflow.UPDATE_STEP > 1 ? 0.01f : 1.0f;

    context.begin();
    context.getGLTextureHandle(pg_cam_a, pg_tex_handle);
    context.beginDraw(fluid.tex_density.dst);
    DwGLSLProgram shader = context.createShader("data/addDensityCam.frag");
    shader.begin();
    shader.uniform2f     ("wh", fluid.fluid_w, fluid.fluid_h);                                                                   
    shader.uniform1i     ("blend_mode", 6);   
    shader.uniform1f     ("mix_value", mix);     
    shader.uniform1f     ("multiplier", 1f);     
    //      shader.uniformTexture("tex_ext"   , opticalflow.tex_frames.src);
    shader.uniformTexture("tex_ext", pg_tex_handle[0]);
    shader.uniformTexture("tex_src", fluid.tex_density.src);
    shader.drawFullScreenQuad();
    shader.end();
    context.endDraw();
    context.end("app.addDensityTexture");
    fluid.tex_density.swap();
  }




  // custom shader, to add density from a texture (PGraphics2D) to the fluid.
  public void addVelocityTexture(DwFluid2D fluid, DwOpticalFlow opticalflow) {
    context.begin();
    context.beginDraw(fluid.tex_velocity.dst);
    DwGLSLProgram shader = context.createShader("data/addVelocity.frag");
    shader.begin();
    shader.uniform2f     ("wh", fluid.fluid_w, fluid.fluid_h);                                                                   
    shader.uniform1i     ("blend_mode", 2);    
    shader.uniform1f     ("multiplier", 1.0f);   
    shader.uniform1f     ("mix_value", 0.1f);
    shader.uniformTexture("tex_opticalflow", opticalflow.frameCurr.velocity);
    shader.uniformTexture("tex_velocity_old", fluid.tex_velocity.src);
    shader.drawFullScreenQuad();
    shader.end();
    context.endDraw();
    context.end("app.addDensityTexture");
    fluid.tex_velocity.swap();
  }
}