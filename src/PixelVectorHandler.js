
class Region {
    constructor(width, height, depth, data) {
        this.width = width;
        this.height = height;
        this.depth = depth;
        this.data = data;
    }

    index(x, y) {
        return ((y * this.width) + x) * this.depth;
    }

    get(x, y) {
        const start = this.index(x, y);
        return this.data.subarray(start, start + this.depth);
    }
}

export default class PixelVectorHandler {
    constructor(options) {
        this.width = options.width;
        this.height = options.height;
        this.depth = options.depth;
        this.mousePosition = [0, 0];
        // The image is divided into regions, and the spectral data for the current region is cached.
        // When the mouse position leaves the boundaries of the current region, data for the new region is requested.
        // The term "region" is used instead of "tile" (although they basically are tiles) to avoid confusion with the spectrum tiles.
        const regionSizeUpperLimit = 1000;
        this.regionWidth = this.width;
        this.regionHeight = this.height;
        while (this.regionWidth * this.regionHeight > regionSizeUpperLimit) {
            this.regionWidth = this.regionWidth / 2;
            this.regionHeight = this.regionHeight / 2;
        }
        this.regionWidth = Math.ceil(this.regionWidth);
        this.regionHeight = Math.ceil(this.regionHeight);
        this.regionsPerRow = Math.ceil(this.width / this.regionWidth);
        this.currentRegionIndex = -1;
        this.currentRegion = null;

        this._debounceTimer = null;
        this.debounceDelay = 100;
        this.resolve = null;
    }

    getMousePosition() {
        return this.mousePosition;
    }

    async setMousePosition(position) {
        // Move position to center of pixels.
        // Flip y-coordinates because the webgl textures are flipped, too.
        this.mousePosition = [
            (position[0] + 0.5) / this.width,
            1 - (position[1] + 0.5) / this.height,
        ];
        let currentRegionIndex = this.getCurrentRegionIndex();
        if (currentRegionIndex !== this.currentRegionIndex) {
            this.currentRegionIndex = currentRegionIndex;
            this.currentRegion = null;
        }

        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
        this._debounceTimer = setTimeout(async () => {
            this.currentRegion = await this.fetchRegion(currentRegionIndex);
            this.resolve(this.currentRegion.get(...this.getCurrentRegionPosition()))
        }, this.debounceDelay);
    }

    getPixelVector() {
        // Map mouse position to local position in current region and return spectral data at that position.
        return new Promise((resolve, reject) => {
            if (this.currentRegion) {
                resolve(this.currentRegion.get(...this.getCurrentRegionPosition()))
            } else {
                this.resolve = resolve;
            }
        });
    }

    async fetchRegion(index) {
        const res = await fetch(`/api/spectrum?index=${index}&width=${this.regionWidth}&height=${this.regionHeight}`);

        if (!res.ok) {
            throw new Error(`Request failed: ${res.status}`);
        }

        const buffer = await res.arrayBuffer();
        return new Region(this.regionWidth, this.regionHeight, this.depth, new Float32Array(buffer));
    };

    getCurrentRegionIndex() {
        let [x,y] = this.mousePosition;
        x = x * this.width;
        y = y * this.height;
        return Math.floor(y / this.regionHeight) * this.regionsPerRow + Math.floor(x / this.regionWidth);
    }

    getCurrentRegionPosition() {
        // Get local mouse coordinates in current region.
        let [x,y] = this.mousePosition;
        x = x * this.width;
        y = y * this.height;
        return [
            Math.floor(x % this.regionWidth),
            Math.floor(y % this.regionHeight)
        ];
    }
}
