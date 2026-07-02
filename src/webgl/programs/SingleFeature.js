import IntensityProgram from './IntensityProgram';
import fragmentShaderSource from '../shaders/single-feature.fs';
import vertexShaderSource from '../shaders/rectangle.vs';

export default class SingleFeature extends IntensityProgram {
    constructor(options) {
        super(vertexShaderSource, fragmentShaderSource, options);
        this.maskPointer = null;
    }

    initialize(gl, handler) {
        super.initialize(gl, handler);

        let pointer = this.getPointer();
        this.texturePointer = gl.getUniformLocation(pointer, 'u_texture');
        this.channelMaskPointer = gl.getUniformLocation(pointer, 'u_channel_mask');
        this.maskPointer = gl.getUniformLocation(pointer, 'u_mask');
        this.channelMask = [1, 0, 0, 0];

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
        gl.texImage2D(gl.TEXTURE_2D,
            0,
            gl.RGBA8,
            this.imageWidth,
            this.imageHeight,
            0,
            gl.RGBA,
            gl.UNSIGNED_BYTE,
            this.EMPTY_CHANNEL
        );
    }

    beforeRender(gl, handler) {
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, this.texture);
        gl.bindFramebuffer(gl.FRAMEBUFFER, this.framebuffer);

        gl.uniform1i(this.texturePointer, 0);
        gl.uniform4f(this.channelMaskPointer, ...this.channelMask);
        gl.uniform1i(this.maskPointer, 2);

        gl.texSubImage2D(
            gl.TEXTURE_2D,
            0,
            0,
            0,
            handler.dataset_.width,
            handler.dataset_.height,
            gl.RGBA,
            gl.UNSIGNED_BYTE,
            this.currentChannelImage
        );
    }

    afterRender(gl, handler) {
        super.afterRender(gl, handler);
    }

    create_empty_channel(width, height) {
        const data = new Uint8Array(width * height * 4);

        for (let i = 0; i < data.length; i += 4) {
            data[i] = 200;     // R
            data[i + 1] = 0;   // G
            data[i + 2] = 0;   // B
            data[i + 3] = 0;   // A
        }

        return data;
    }

    async fetchChannelImage(index) {
        const res = await fetch(`/api/channel?index=${index}`);

        if (!res.ok) {
            throw new Error(`Request failed: ${res.status}`);
        }

        return new Uint8Array(await res.arrayBuffer());
    }

    async setChannelImage(index) {
        this.currentChannelImage = await this.fetchChannelImage(index);
    }
}
