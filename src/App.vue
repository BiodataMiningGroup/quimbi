<template>
<div class="show-container">
    <nav class="navbar navbar-dark bg-dark">
        <a class="navbar-brand" href="#">
            QUIMBI
        </a>
        <span v-show="initialized" class="navbar-text text-light font-weight-bold">
            {{dataset.name}} <small>{{dataset.width}}&times;{{dataset.height}}&times;{{dataset.depth}} @ {{dataset.precision}}bit</small>
        </span>
        <span></span>
    </nav>
    <div class="main">
        <dialog ref="initModal" class="bg-dark text-light">
            <h1 class="logo text-center w-100 mb-4">
                QUIMBI
            </h1>
            <p>
                 Quick Exploration Tool for Multivariate Bioimages (QUIMBI) is a web application that allows you to visualize and explore mass spectrometry images interactively in the browser.
            </p>
            <p>
                Code and information on how to generate a dataset ZIP file can be found at <a href="https://github.com/BiodataMiningGroup/quimbi">GitHub</a>.
            </p>
            <p class="mb-0">
                Select a dataset ZIP file to start the application.
            </p>
            <div v-if="error" class="alert alert-danger mt-4 mb-0" v-text="errorMessage"></div>

            <div class="mt-4 text-center">
                <div v-if="loading" class="spinner-border text-light" role="status">
                    <span class="sr-only">Loading...</span>
                </div>
                <button v-else autofocus class="btn btn-primary btn-lg" @click="selectFile">
                    Select ZIP file
                </button>
            </div>
        </dialog>
        <div class="main-content">
            <Visualization
                ref="visualization"
                v-bind:dataset="dataset"
                v-on:hover="updateHoverPixelVector"
                v-on:select="updateSelectPixelVector"
                @freeze="onFreeze"
                @spectrum-areas-changed="handleAreasChanged"
            ></Visualization>
        </div>
        <div class="main-aside">
            <PixelVectorDisplay
                ref="pixelVectorDisplay"
                v-bind:dataset="dataset"
                v-on:hover="updateHoveredFeature"
                @select-mz="handleSpectrumPointSelect"
            ></PixelVectorDisplay>
        </div>
    </div>
    <input type="file" name="file" accept="application/zip" ref="fileInput" @change="selectedFile" style="display: none;">
</div>
</template>

<script>
import WebglHandler from './webgl/Handler';
import Visualization from './components/Visualization.vue';
import PixelVectorDisplay from './components/PixelVectorDisplay.vue';
import {ZipReader, BlobReader, TextWriter} from "@zip.js/zip.js";

const DATASET_KEYS = [
    'precision',
    'name',
    'height',
    'width',
    'channels',
];

const NUMERIC_FIELDS = [
    'precision',
    'height',
    'width',
];

const PRECISION_STEPS = [32, 16, 8];

export default {
    components: {
        Visualization,
        PixelVectorDisplay,
    },
    data() {
        return {
            dataset: {},
            initialized: false,
            loading: false,
            error: null,
        };
    },
    computed: {
        errorMessage() {
            if (this.error) {
                return this.error.message ? this.error.message : this.error;
            }

            return '';
        },
    },
    methods: {
        updateHoverPixelVector(vector) {
            // Use a method instead of prop because the pixel vector array stays the
            // same object.
            this.$refs.pixelVectorDisplay.updatePixelVector(vector);
        },
        updateSelectPixelVector(vector) {
            // Use a method instead of prop because the pixel vector array stays the
            // same object.
            this.$refs.pixelVectorDisplay.updateReferencePixelVector(vector);
        },
        updateHoveredFeature(feature) {
            this.$refs.visualization.showFeature(feature);
        },
        selectFile() {
            this.$refs.fileInput.click();
        },
        selectedFile(e) {
            this.loading = true;
            this.loadDataset(e.target.files[0]);
        },
        verifyDataset(dataset) {
            DATASET_KEYS.forEach(function (key) {
                if (dataset[key] === undefined) {
                    throw Error(`The metadata.json is missing the ${key} field.`);
                }
            });

            NUMERIC_FIELDS.forEach(function (key) {
                if (!Number.isInteger(dataset[key])) {
                    throw Error(`The the ${key} field is not an integer.`);
                }

                if (dataset[key] <= 0) {
                    throw Error(`The the ${key} field must be greater than 0.`);
                }
            });

            if (!PRECISION_STEPS.includes(dataset.precision)) {
                throw Error(`The the precision must be 32, 16 or 8.`);
            }

            let fileMultiplier = dataset.precision / 32;
            let expectedFiles = Math.ceil(dataset.depth * fileMultiplier);
            let foundFiles = Object.keys(dataset.entries).length;
            if (foundFiles !== expectedFiles) {
                throw new Error(`Wrong number of feature files. Found ${foundFiles} but expected ${expectedFiles}.`);
            }

            if (dataset.overlay && !dataset.overlayEntry) {
                throw new Error('The overlay.jog file is missing.');
            }

            for (let i = expectedFiles - 1; i >= 0; i--) {
                if (!dataset.entries[`${i}.png`]) {
                    throw new Error(`The feature file ${i}.png is missing.`);
                }
            }
        },
        async loadDataset(blobOrFile) {
            try {
                let reader = new ZipReader(new BlobReader(blobOrFile));
                let entries = await reader.getEntries();
                let entryMap = {};
                entries.forEach(e => entryMap[e.filename] = e);
                let metaEntry = entryMap['metadata.json'];

                if (!metaEntry) {
                    throw new Error('The metadata.json file is missing.');
                }

                delete entryMap['metadata.json'];
                let meta = await metaEntry.getData(new TextWriter());
                let dataset = JSON.parse(meta);

                if (dataset.overlay && entryMap['overlay.jpg']) {
                    dataset.overlayEntry = entryMap['overlay.jpg'];
                    delete entryMap['overlay.jpg'];
                }

                dataset.entries = entryMap;
                dataset.depth = dataset.channels.length;
                this.verifyDataset(dataset);

                this.dataset = dataset;
                this.initialized = true;
                console.log('Geladener Datensatz:', dataset);

            } catch (e) {
                this.error = e;
                return;
            } finally {
                this.loading = false;
            }

            this.$refs.initModal.close();
        },
        onFreeze(freeze) {
            if (freeze) {
                this.$refs.visualization.freeze();
            } else {
                this.$refs.visualization.unfreeze();
            }
        },
        handleSpectrumPointSelect(payload) {
            this.$refs.visualization.handleSpectrumClick(payload);
        },
        handleAreasChanged(areas) {
            this.$refs.pixelVectorDisplay.handleNewArea(areas);
        },
    },
    mounted() {
        this.$refs.initModal.showModal();
        let dataset = new URLSearchParams(window.location.search).get('d');
        if (dataset) {
            this.loading = true;
            fetch(`datasets/${dataset}`)
                .then(response => response.blob())
                .then(this.loadDataset)
        }
    },
}
</script>

<style lang="scss">
.show-container {
    width: 100vw;
    height: 100vh;
    display: flex;
    flex-direction: column;

    .navbar {
        border-bottom: 1px solid $gray-900;
    }
    .main {
        display: flex;
        flex-direction: column;
        flex: 1;
        overflow: hidden;
        position: relative;
    }

    .main-content {
        width: 100%;
        height: 100%;
        position: relative;
        flex: 1;
        background-image: url('/noise.png');
    }

    .main-aside {
        width: 100%;
        height: 200px;
        border-top: 1px solid $gray-900;
        position: relative;
        overflow: hidden;
        padding: 10px 0;
        box-sizing: border-box;
    }

}

dialog {
    z-index: 10;
    max-width: 500px;
    border: 1px solid rgba(0,0,0,.2);
    border-radius: .3rem;
    position: absolute;
}

dialog::backdrop {
    background-color: rgba(0, 0, 0, 0.4);
}
</style>
