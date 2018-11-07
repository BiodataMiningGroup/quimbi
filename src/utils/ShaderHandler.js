import AngleDist from './programs/angledist.js'

export default class ShaderHandler {

    constructor() {
        this.angleDist = new AngleDist();
    }

    createShader() {
        window.glmvilib.addProgram(this.angleDist);
    }

    render(mouse) {
        this.angleDist.updateMouse(mouse.x, mouse.y);
        window.glmvilib.render.apply(null, ['angle-dist']);


    }

    getActive() {
        let active = [];
        active.push(this.angleDist.id)
    }


}