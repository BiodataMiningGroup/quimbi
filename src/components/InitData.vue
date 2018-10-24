<template>
    <section class="section">
        <div class="container">
            <h1 class="title has-text-centered">quimbi</h1>
            <div class="tile is-ancestor">
                <div class="tile is-2"></div>
                <div class="tile is-8">
                    <div class="container has-text-centered">
                        <div class="field">
                            <div class="control has-text-centered">
                                <label class="label has-text-centered">Datei:</label>
                                <input v-model="filePath" type="text" class="input is-full">
                            </div>
                        </div>
                        <div class="field">
                            <div class="control has-text-centered">
                                <button v-if="!loading" class="button" @click="getData">Laden</button>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
            <canvas id="canvas" ref="canvas"></canvas>
        </div>
    </section>
</template>

<script>
    import axios from 'axios';

    export default {
        data() {
            return {
                filePath: 'data/small-stacked-max.txt',
                data: {},
                loading: false,
            }
        },
        methods: {
            getData() {
                this.loading = true;
                axios.get(this.filePath)
                    .then(
                        response => {
                            this.loading = true;
                            this.parseData(response);
                        }
                    )
                    .catch(error => console.log(error));
                this.loading = false;
            },
            /**
             * Parses data to create the canvas from the downloaded txt-file
             * @param response
             */
            parseData(response) {
                // Split lines into array and fill the data object
                let input = response.data.split('\n');
                let header = input[0].split(',');
                let brightfieldConfigLine = input[2];
                let brightfieldConfig = brightfieldConfigLine.split(',');
                // Amount of lines for configuration and information
                let configLength = 3;

                this.data.backgroundImage = brightfieldConfig[0];
                this.data.overlayImage = brightfieldConfig[1];

                this.data.overlayScaleX = parseFloat(brightfieldConfig[2]);
                this.data.overlayScaleY = parseFloat(brightfieldConfig[3]);
                this.data.overlayShiftX = parseFloat(brightfieldConfig[4]);
                this.data.overlayShiftY = parseFloat(brightfieldConfig[5]);

                this.data.id = header[0];
                this.data.base = header[1];
                this.data.format = header[2];
                this.data.channels = parseInt(header[3]);
                this.data.width = parseInt(header[4] * this.data.overlayScaleX);
                this.data.height = parseInt(header[5] * this.data.overlayScaleY);
                this.data.dataWidth = parseInt(header[4]);
                this.data.dataHeight = parseInt(header[5]);

                this.data.maxEuclDist = Math.sqrt(input.channels) * 255;

                // Todo ??
                this.data.preprocessing = input[0];

                // Push image names into channelNames
                this.data.channelNames = [];
                this.data.files = [];
                input.forEach((inputLine, key) => {
                    if (key >= configLength && inputLine !== '') {

                        this.data.files.push(inputLine);

                        inputLine.split('-').forEach((item) => {
                            this.data.channelNames.push(item);
                        });
                    }
                });

                // Download images
                this.data.images = new Array(this.data.files.length);
                this.loadImages();

            },

            /**
             * Downloads data images parallel from the server and puts them into an array
             */
            loadImages() {
                //console.log(glm);
                for (let i = 0; i < this.data.images.length; i++) {
                    let imagePath = this.data.base + this.data.files[i] + this.data.format;
                    this.data.images[i] = new Image();
                    this.data.images[i].src = imagePath;
                    //console.log(this.data.images[i]);
                    document.body.appendChild(this.data.images[i]);
                }

                // Initialize the glmvlib after last image has been downloaded
                this.data.images[this.data.images.length - 1].onload = () => (this.initGlmvlib());

            },

            initGlmvlib () {
                this.$refs.canvas.width = this.data.width;
                this.$refs.canvas.height = this.data.height;
                try {
                    // Todo Passt das so?
                    window.glmvilib.init(
                        this.$refs.canvas,
                        {
                            width: this.data.width,
                            height: this.data.height,
                            channels: this.data.channels,
                            reservedUnits: 2
                        }
                    );

                    window.glmvilib.storeTiles(this.data.images);
                    window.glmvilib.finish();
                    this.loading = false;
                    this.$emit('finish', this.data)
                } catch (error) {

                    // Todo ab und zu: WebGL: Invalid_vValue: texSubImage2D: invalid image/bad image data
                    // Todo Large Dataset zum besseren Testen
                    console.log(error);
                }
            }

        }
    }
</script>

<style scoped>

</style>