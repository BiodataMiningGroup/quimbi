export default class AngleDist {

    constructor() {
        //helpers.useInternalVertexPositions(program);
        //helpers.useInternalTexturePositions(program);
        //helpers.useInternalTextures(program);
        this.id = 'angle-dist';

        //gl.uniform1f(normalization, 1 / this.angleDist);
    }


    setUp(gl, program, assets, helpers) {
        let id = 'angle-dist';
        let vertexShaderUrl = 'shader/display-rectangle.glsl.vert';
        let fragmentShaderUrl = 'shader/angle-dist.glsl.frag';
        let _gl = gl;
        let mousePosition = null;
        let channelMaskTexture = null;
        let _regionMaskTexture = null;
    }

}
