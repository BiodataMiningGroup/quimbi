// Todo remove
import IntensitiyHistogram from '../IntensityHistogram';

export default class AngleDist {

    constructor(framebuffer, canvasWidth, canvasHeight) {
        this.id = 'angle-dist';
        this.vertexShaderUrl = 'shader/display-rectangle.glsl.vert';
        this.fragmentShaderUrl = 'shader/angle-dist.glsl.frag';
        this.maxAngleDist = Math.PI / 2;
        this.mouseX = 0;
        this.mouseY = 0;
        this.width = canvasWidth;
        this.height = canvasHeight;
        this.framebuffer = framebuffer;

        this.intensityHistogram = new IntensitiyHistogram(this.framebuffer);
    }

    updateMouse(mouseX, mouseY) {
        this.mouseX = mouseX;
        this.mouseY = mouseY;
    }

    setUpDistanceTexture(gl, assets, helpers) {
        if(typeof(assets.framebuffers.distances) === 'undefined') {
            assets.framebuffers.distances = gl.createFramebuffer();
        }
        gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.distances);
        let texture = helpers.newTexture('distanceTexture');
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.width, this.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
        gl.bindTexture(gl.TEXTURE_2D, null);
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);

    }

    setUp(gl, program, assets, helpers) {
        helpers.useInternalVertexPositions(program);
        helpers.useInternalTexturePositions(program);
        helpers.useInternalTextures(program);

        let normalization = gl.getUniformLocation(program, 'u_normalization');
        gl.uniform1f(normalization, 1 / this.maxAngleDist);

        assets._mousePosition = gl.getUniformLocation(program, 'u_mouse_position');
        this.setUpDistanceTexture(gl, assets, helpers);

        // Todo do i need this right now?
        //this._channelMaskTexture = this.setUpChannelMask(gl, program, assets, helpers);
        // Todo soll raus
        //this._regionMaskTexture = setUpRegionMask(gl, program, assets, helpers);
    }

    callback(gl, program, assets, helpers) {
        gl.uniform2f(assets._mousePosition, this.mouseX, this.mouseY);
        helpers.bindInternalTextures();
        //gl.activeTexture(gl.TEXTURE0);
        //Todo where does _channelMaskTexture come from, do i need it right now?
        //gl.bindTexture(gl.TEXTURE_2D, _channelMaskTexture);
        //gl.activeTexture(gl.TEXTURE1);
        // Todo Call setUpDistanceTexture and:
        //gl.bindFramebuffer(gl.FRAMEBUFFER, null);
        gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.distances);
    }

    postCallback (gl, program, assets, helpers) {
        this.framebuffer.updateIntensities();
        this.intensityHistogram.updateHistogram();

    }


}
