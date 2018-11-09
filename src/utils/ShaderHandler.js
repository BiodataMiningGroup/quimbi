import AngleDist from './programs/angledist.js'
import ColorMap from './programs/colormap.js'

export default class ShaderHandler {

    constructor(data) {
        this.angleDist = new AngleDist(data.canvas.width, data.canvas.height);
        this.colorMap = new ColorMap();

        // Todo implement ColorMap Program
        // ColorMap Service implementieren, evtl in ColorMap programm implementieren (fire.csv)
        //ColorMap Program: gl.activeTexture gl.TEXTURE0  Texture from angle-dist
        //setUpDistanceTexture
    }

    createShader() {
        window.glmvilib.addProgram(this.angleDist);
        window.glmvilib.addProgram(this.colorMap);
    }

    render(mouse) {
        this.angleDist.updateMouse(mouse.x, mouse.y);
        window.glmvilib.render.apply(null, ['angle-dist', 'color-map']);

    }

    getActive() {
        let active = [];
        active.push(this.angleDist.id)
    }

}