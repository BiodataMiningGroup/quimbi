import ImageStatic from 'node_modules/ol/source/ImageStatic';
import ImageCanvas from 'node_modules/ol/ImageCanvas';
import EventType from 'node_modules/ol/events/EventType';
import {listen} from 'node_modules/ol/events';

/**
 * Class to enabling loading the distance map into the canvas of the openlayers map
 */
export default class Canvas extends ImageStatic {
    constructor(options) {
        super(options);
        this.image_ = new ImageCanvas(options.imageExtent, 1, 1, options.canvas);
        listen(this.image_, EventType.CHANGE, this.handleImageChange, this);
    }
}
