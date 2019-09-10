import AngleDist from './programs/AngleDist.js'
import ColorLens from './programs/ColorLens.js';
import ColorMap from './programs/ColorMap.js'
import FrameBuffer from './programs/helper/FrameBuffer.js';
import IntensitiyHistogram from './programs/helper/IntensityHistogram';
import SelectionInfo from './programs/SelectionInfo';
import RenderChannel from './programs/RenderChannel';
import RenderMeanRanges from './programs/RenderMeanRanges.js';

/**
 * The RenderHandler sets up all Shader Programs and calls the glmvilib to render given shaders
 */
export default class RenderHandler {

    /**
     * Sets up helper classes and inits shader
     * @param data
     */
    constructor(data) {
        // Set up helper to render the UI
        this.selectionInfoTextureDimension = Math.ceil(Math.sqrt(Math.ceil(data.channels/4)));
        this.framebuffer = new FrameBuffer(this.selectionInfoTextureDimension, data.dataWidth, data.dataHeight);
        this.intensityHistogram = new IntensitiyHistogram(this.framebuffer);

        // Init Shader
        this.angleDist = new AngleDist(this.framebuffer, this.intensityHistogram);
        this.colorLens = new ColorLens(this.intensityHistogram, this.framebuffer);
        this.colorMap = new ColorMap(this.framebuffer);
        this.selectionInfo = new SelectionInfo(this.framebuffer, this.selectionInfoTextureDimension);
        this.renderChannel = new RenderChannel(this.framebuffer);
        this.renderMeanRanges = new RenderMeanRanges(this.framebuffer);

    }

    /**
     * Add Shader to the glmvilib to render the generated webgl pixels to the canvas
     */
    createShader() {
        window.glmvilib.addProgram(this.angleDist);
        window.glmvilib.addProgram(this.colorLens);
        window.glmvilib.addProgram(this.colorMap);
        window.glmvilib.addProgram(this.selectionInfo);
        //window.glmvilib.addProgram(this.renderChannel);
        //window.glmvilib.addProgram(this.renderMeanRanges);
    }

    /**
     * Render mouse position depending image to the openlayers canvas
     * @param mouse
     */
    /* TODO if mouse in image frame ... */
    render(mouse) {
        this.angleDist.updateMouse(mouse.x, mouse.y);
        window.glmvilib.render.apply(null, ['angle-dist', 'color-lens', 'color-map']);
    }
    /*TODO: If mouse in spectrum element use renderchannel*/


    updateRegionMask(mask) {
      this.angleDist.updateRegionMask(mask);
  		//this.renderMeanRanges.updateRegionMask(mask);
  		//this.renderChannel.updateRegionMask(mask);
  	}

    updateChannelMask(mask, activeChannels) {
  		this.angleDist.updateChannelMask(mask, activeChannels);
  		//this.renderMeanRanges.updateChannelMask(mask, activeChannels);
  	}

}
