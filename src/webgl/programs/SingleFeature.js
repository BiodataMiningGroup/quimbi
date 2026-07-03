import IntensityProgram from './IntensityProgram';
import fragmentShaderSource from '../shaders/single-feature.fs';
import vertexShaderSource from '../shaders/rectangle.vs';

export default class SingleFeature extends IntensityProgram {
    constructor(options) {
        super(vertexShaderSource, fragmentShaderSource, options);
        this.maskPointer = null;
        this.currentChannelIndex = undefined;
    }

    initialize(gl, handler) {
        super.initialize(gl, handler);

        let pointer = this.getPointer();
        this.texturePointer = gl.getUniformLocation(pointer, 'u_texture');
        this.maskPointer = gl.getUniformLocation(pointer, 'u_mask');

        this.EMPTY_CHANNEL = this.create_empty_channel(handler.dataset_.width, handler.dataset_.height);
        this.currentChannelImage = this.EMPTY_CHANNEL;
        this.imageWidth = handler.dataset_.width;
        this.imageHeight = handler.dataset_.height

        this.texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, this.texture);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, this.texture);

        gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1);
        gl.texImage2D(gl.TEXTURE_2D,
            0,
            gl.R8,
            this.imageWidth,
            this.imageHeight,
            0,
            gl.RED,
            gl.UNSIGNED_BYTE,
            this.EMPTY_CHANNEL
        );
    }

    beforeRender(gl, handler) {
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, this.texture);
        gl.bindFramebuffer(gl.FRAMEBUFFER, this.framebuffer);

        gl.uniform1i(this.texturePointer, 0);
        gl.uniform1i(this.maskPointer, 2);

        gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1);
        gl.texSubImage2D(
            gl.TEXTURE_2D,
            0,
            0,
            0,
            handler.dataset_.width,
            handler.dataset_.height,
            gl.RED,
            gl.UNSIGNED_BYTE,
            this.currentChannelImage
        );
    }

    afterRender(gl, handler) {
        super.afterRender(gl, handler);
    }

    create_empty_channel(width, height) {
        const data = new Uint8Array(width * height);
        data.fill(0);
        return data;
    }

    async fetchChannel(index) {
        const res = await fetch(`/api/channel?index=${index}`);

        if (!res.ok) {
            throw new Error(`Request failed: ${res.status}`);
        }

        return new Uint8Array(await res.arrayBuffer());
    }

    async setChannel(index) {
        this.currentChannelIndex = index;
        const channelImage = await this.fetchChannel(index);
        if (this.currentChannelIndex !== index) {
            return;
        }
        this.currentChannelImage = channelImage;
    }

    setEmptyChannel() {
        this.currentChannelImage = this.EMPTY_CHANNEL;
    }
}
