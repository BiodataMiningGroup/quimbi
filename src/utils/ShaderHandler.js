import AngleDist from './programs/angledist.js'

export default class ShaderHandler {

    constructor() {
        this.angleDist = new AngleDist();
    }

    createShader() {
        window.glmvilib.addProgram(this.angleDist);
    }

    getActive() {
        let active = [];
        active.push(this.angleDist.id)
    }

}