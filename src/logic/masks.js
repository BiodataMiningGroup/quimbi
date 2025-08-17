export default {
    methods: {
        // Spektrum-Maske
        async updateSpectrumMask() {
            const tiles = Math.ceil(this.dataset.depth / 4);

            const width = Math.ceil(Math.sqrt(tiles));
            const height = Math.ceil(tiles / width);

            const pixels = width * height;
            const maskData = new Uint8Array(pixels * 4);
            const spectra = this.getActiveSpectra();
            const hasActiveAreas = !(spectra.length === 0);

            if (!hasActiveAreas) {
                for (let i = 0; i < pixels * 4; i++) {
                    maskData[i] = 255;
                }
            } else {
                for (let i = 0; i < pixels * 4; i++) {
                    maskData[i] = 0;
                }

                for (const area of spectra) {
                    for (let i = area.start; i <= area.end; i++) {
                        if (i >= this.dataset.depth) continue;

                        const tileIndex = Math.floor(i / 4);
                        const channel = i % 4;

                        maskData[tileIndex * 4 + channel] = 255;
                    }
                }
            }
            const gl = this.handler.getGl();
            const maskTexture = this.handler.getTexture('spectrumMask');
            gl.activeTexture(gl.TEXTURE3);
            gl.bindTexture(gl.TEXTURE_2D, maskTexture);
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, maskData);
        },

        // Polygon-Maske
        async updatePolygonMask() {
            const maskData = await this.generatePolygonMaskTexture();
            const gl = this.handler.getGl();
            const maskTexture = this.handler.getTexture('mask');

            gl.activeTexture(gl.TEXTURE2);
            gl.bindTexture(gl.TEXTURE_2D, maskTexture);
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.dataset.width, this.dataset.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, maskData);
        },
        async generatePolygonMaskTexture() {
            const width = this.dataset.width;
            const height = this.dataset.height;
            const maskData = new Uint8Array(width * height * 4);
            const polygons = this.getActivePolygons();

            for (let y = 0; y < height; y++) {
                for (let x = 0; x < width; x++) {
                    const idx = (y * width + x) * 4;
                    let inside = polygons.length === 0;
                    const point = [x, y];
                    inside = this.checkCoorInPolygons(point);

                    if (inside) {
                        maskData[idx] = 255;
                        maskData[idx + 1] = 255;
                        maskData[idx + 2] = 255;
                        maskData[idx + 3] = 255;
                    } else {
                        maskData[idx] = 0;
                        maskData[idx + 1] = 0;
                        maskData[idx + 2] = 0;
                        maskData[idx + 3] = 255;
                    }
                }
            }
            return maskData;
        },
    },
};
