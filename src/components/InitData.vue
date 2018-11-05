<template>
    <section class="section">
        <div class="container">
            <h1 class="title has-text-centered">quimbi</h1>
            <div class="tile is-ancestor">
                <div class="tile is-2"></div>
                <div class="tile is-8">
                    <div class="container has-text-centered">
                        <div v-if="!loading" class="field">
                            <div class="control has-text-centered">
                                <label class="label has-text-centered">Datei:</label>
                                <input v-model="filePath" type="text" class="input is-full">
                            </div>
                        </div>
                        <div v-if="!loading" class="field">
                            <div class="control has-text-centered">
                                <button class="button" @click="getData">Laden</button>
                            </div>
                        </div>
                        <div v-if="loading">
                            <p class="progress-label"><strong>Lade Daten ...</strong></p>
                            <progress class="progress is-medium" :value="progressBar" max="100"></progress>
                        </div>

                    </div>
                </div>
            </div>
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
                counter: 0,
                progressBar: 0,
                loading: false,
            }
        },
        watch: {
            // Loads glmvlib if all images are loaded
            counter() {
                this.progressBar = Math.round((this.counter / this.data.files.length * 100));
                if (this.counter === this.data.files.length) {
                    this.initGlmvlib();

                }
            }
        },
        methods: {
            /**
             * Makes ajax request to config file, calls parseData
             */
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
                this.data.imageWidth = parseInt(header[4] * this.data.overlayScaleX);
                this.data.imageHeight = parseInt(header[5] * this.data.overlayScaleY);
                this.data.dataWidth = parseInt(header[4]);
                this.data.dataHeight = parseInt(header[5]);

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

                // Create Canvas Element for openlayers
                this.data.canvas = document.createElement('canvas');
                console.log(this.data.canvas.getContext('webgl'));

                // Download images
                this.data.images = new Array(this.data.files.length);
                this.loadImages();

            },

            /**
             * Downloads data images parallel from the server and puts them into an array
             */
            loadImages() {
                this.data.counter = 0;
                for (let i = 0; i < this.data.images.length; i++) {
                    let imagePath = this.data.base + this.data.files[i] + this.data.format;
                    this.data.images[i] = new Image();
                    // watch counter and initialize the glmvlib after last image has been downloaded
                    this.data.images[i].onload = () => this.counter++;
                    // Todo add onerror and show on gui
                    this.data.images[i].src = imagePath;
                }

            },

            initGlmvlib() {
                try {
                    window.glmvilib.init(
                        this.data.canvas,
                        {
                            width: this.data.dataWidth,
                            height: this.data.dataHeight,
                            channels: this.data.channels,
                            reservedUnits: 2
                        }
                    );

                    window.glmvilib.storeTiles(this.data.images);
                    this.loading = false;

                    this.$emit('finish', this.data)
                    // Todo shader.getActive()
                    // Todo glmvilib.render.apply(null, [a,b,c])
                    // Todo start with angledist shader, Programm.coffee,
                    // services/shader.coffee : createProgramms(), getActive()
                    // renderer.coffee: update() glmvilib.render(shader.getActive())
                    // glmbilib.render('angle-dist');s

                } catch (error) {
                    // Todo show error on gui
                    console.log(error);
                    window.glmvilib.finish();
                }
            }

        }
    }
</script>

<style scoped>
    .progress-label {
        margin-top: 30px;
        margin-bottom: 0;
    }

    .progress {
        margin-top: 20px;
    }

</style>