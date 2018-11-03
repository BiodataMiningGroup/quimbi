export default class ShaderHandler {

    constructor (angleDist) {
        this.angleDist = new AngleDist();
    }

    createShader () {
        window.glmvilib.addProgram(this.angleDist);
    }

    getActive () {
        let active = [];
        active.push(this.angleDist.id)
    }

}


class AngleDist {

    constructor (gl, program, assets, helpers) {
        this.id = 'angle-dist';
        this.vertexShaderUrl = 'shader/display-rectangle.glsl.vert';
        this.fragmentShaderUrl = 'shader/angle-dist.glsl.frag';
        this._gl = gl;
        this.mousePosition = null;
        this.channelMaskTexture = null;
        this._regionMaskTexture = null;
        //helpers.useInternalVertexPositions(program);
        //helpers.useInternalTexturePositions(program);
        //helpers.useInternalTextures(program);

        //gl.uniform1f(normalization, 1 / this.angleDist);


    }

}