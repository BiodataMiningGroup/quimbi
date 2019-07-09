<template>
<section class="section">
	<div class="app-content box">
		<div class="level">
			<div class="level-item has-text-centered">
				<h1>Quimbi</h1>
			</div>
		</div>
		<div class="level" v-if="!loading">
			<div class="level-item has-text-centered">
				<div class="field">
					<div class="control has-text-centered">
						<label class="label has-text-centered">Datei:</label>
						<input v-model="filePath" type="text" class="input is-full path">
					</div>
				</div>
			</div>
		</div>
		<div class="level" v-if="!loading">
			<div class="level-item has-text-centered">
				<div class="field">
					<div class="control has-text-centered">
						<button class="button" @click="getData">Laden</button>
					</div>
				</div>
			</div>
		</div>

		<div class="level" v-if="loading">
			<div class="level-item has-text-centered">
				<div>
					<p class="progress-label">Lade Daten ...</p>
					<progress class="progress path is-medium is-info" :value="progressBar" max="100"></progress>
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
		/**
		 *  Loads glmvlib if all images are loaded
		 **/
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
			this.data.canvas.width = this.data.dataWidth;
			this.data.canvas.height = this.data.dataHeight;

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

		/**
		 * Inits the glmbilib with parsed data
		 */
		initGlmvlib() {
			try {
				window.glmvilib.init(
					// Canvas element for openlayers
					this.data.canvas, {
						width: this.data.dataWidth,
						height: this.data.dataHeight,
						channels: this.data.channels,
						reservedUnits: 2
					}
				);

				// Write tiles row major into textures
				window.glmvilib.storeTiles(this.data.images);
				this.loading = false;
				console.log(this.data);
				// Emit finish message to switch to switch component
				this.$emit('finish', this.data)

				// Never happens, but better be save than sorry
			} catch (error) {
				console.log(error);
				// Kill the library to release memory
				window.glmvilib.finish();
			}
		}

	}
}
</script>

<style scoped>
.progress-label {
	margin-bottom: 0;
	color: whitesmoke !important;
}

.progress {
	margin-top: 20px;
}

.path {
	width: 30vw;
	min-width: 350px;
}

.section {
	height: 100vh !important;
	background-color: #1f1f1f;
}

label {
	color: whitesmoke;
}

.app-content {
	color: whitesmoke !important;
	background-color: #454545;
	position: absolute;
	top: 50%;
	left: 50%;
	transform: translate(-50%, -90%);
}

h1 {
	font-family: Helvetica, sans-serif;
	font-weight: bold;
	font-size: 1.7em;
}
</style>
