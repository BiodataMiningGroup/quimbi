<template>
<div id="spectrum-axes">
	<canvas id="spectrum-canvas"></canvas>
</div>
</template>

<script>
import * as d3 from '../../node_modules/d3/dist/d3';

export default {
	props: [
		'xValues',
		'yValues'
	],
	data() {
		return {
			data: [],
			canvas: {},
			svgChart: {},
			svgGroup: {},
			svgPoints: {},
			spectrumMargin: {
				bottom: 30,
				left: 45,
				top: 20,
				right: 30
			},
			custom: {},
			dataExample: [],
			ctx: {},
			x: {},
			y: {},
			canvasWidth: {},
			canvasHeight: {},
			svgHeight: {},
			spectrumAxes: {},
			xAxis: {},
			yAxis: {},
			gxAxis: {},
			gyAxis: {},
			transform: {},
			normedYValues: [],
			clearedXValues: [],
			lineColor: '#e8e8e8',
			tickXValues: [],
			// Zoom Factor of Spectrum when Points get visible
			zoomFactorPoints: 15,
			//actually create accessible data points
			dataPoints: []
		}
	},
	/**
	 * Created the graph and draw it once without values not zoomed
	 */
	mounted() {
		this.initGraph();
		this.drawSpectrum(d3.zoomIdentity);

	},
	methods: {

		initGraph() {

			this.doDomCalculations();
			// Init Canvas
			this.canvas = d3.select('#spectrum-canvas')
				.attr('width', this.canvasWidth)
				.attr('height', this.canvasHeight)
				.style('margin-left', this.spectrumMargin.left + 'px')
				.style('margin-top', this.spectrumMargin.top + 'px');

			// Init SVG
			this.svgChart = d3.select('#spectrum-axes').append('svg:svg')
				//.style('opasity', "1")
				.style('position','absolute')
				.style('z-index', '2')
				.attr('width', this.svgWidth)
				.attr('height', this.svgHeight)
				.attr('class', 'svg-plot');

			this.svgGroup = this.svgChart.append('g')
				.style('position','absolute')
				.attr('transform', `translate(${this.spectrumMargin.left}, ${this.spectrumMargin.top})`);

			this.svgPoints = d3.select('.svg-plot').append('svg')
				.style('position','absolute')
				.style('z-index', '2')
				//.style('opasity', "1")
				.attr('width', this.canvasWidth)
				.attr('height', this.canvasHeight)
				.attr('transform', `translate(${this.spectrumMargin.left}, ${this.spectrumMargin.top})`);

			// Set axis
			this.x = d3.scaleLinear()
				.domain([0, this.xValues.length - 1])
				.range([0, this.canvasWidth]);
			this.y = d3.scaleLinear()
				.domain([0, 100])
				.range([this.canvasHeight, 0]);


			// Workaround to use channel name labels in tickFormat
			let xVars = this.xValues;
			// Init Axis
			this.xAxis = d3.axisBottom(this.x).tickPadding(10).tickFormat(function(d, i) {
				return xVars[i];
			});
			this.yAxis = d3.axisLeft(this.y).tickPadding(13).ticks(4).tickSizeInner(-this.canvasWidth);


			// Set axis groups
			this.gxAxis = this.svgGroup.append('g')
				.attr('transform', `translate(0, ${this.canvasHeight})`)
				.attr("class", "axisx")
				.call(this.xAxis);

			this.gyAxis = this.svgGroup.append('g')
				.attr("class", "yaxis")
				.call(this.yAxis);
			this.ctx = this.canvas.node().getContext('2d');

			// Add event listener for user interaction
			this.canvas.call(this.zoomSpectrum());

			// Resize spectrum if window size changes
			window.addEventListener('resize', this.fitToScreen);

		},
		drawSpectrum(transform) {
			let scaleX = transform.rescaleX(this.x);
			let scaleY = transform.rescaleY(this.y);

			this.gxAxis.call(this.xAxis.scale(scaleX).tickFormat((d, e, target) => {
				// has bug when the scale is too big
				if (Math.floor(d) === d3.format(".1f")(d)) {
					return this.xValues[Math.floor(d)]
				}
				return this.xValues[d];

			}));
			this.gyAxis.call(this.yAxis.scale(scaleY));
			this.ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

			/*
			IS THIS PART NECESSARY?? DOESN'T SEEM TO BE???

			// Loop over all normed y values and draw them to their corresponding x values

			// Draw points if zoom factor of translation is bigger than this.zoomFactorPoints
			// and value is not zero
			if (transform.k >= this.zoomFactorPoints) {
				this.normedYValues.forEach((point, index) => {
					if (point > 0) {
						this.ctx.beginPath();
						const px = scaleX(index);
						const py = scaleY(point);

						// Draw point
						this.ctx.fillStyle = this.lineColor;
						this.ctx.arc(px, py, 3, 0, 2 * Math.PI, true);
						this.ctx.fill();
					}
				});
			}
			*/

			let dataPoints = [];
			let i=0;
			// Draw line between current and the point before
			// Init lastpX/Y for the loop
			let lastpX = 0;
			let lastpY = this.canvasHeight;

			// Put beginPath() and stroke() outside forEach to reduce lags from drawing
			this.ctx.beginPath();
			this.normedYValues.forEach((point, index) => {
				const px = scaleX(index);
				const py = scaleY(point);
				// If first data point: start drawing from there
				if (index === 0) {
					this.ctx.moveTo(px, py);
				} else {
					this.ctx.moveTo(lastpX, lastpY);
				}
				dataPoints.push({});
				dataPoints[i].xValue = this.xValues[index];
				dataPoints[i].normyValue = this.normedYValues[index];
				dataPoints[i].px = px;
				dataPoints[i].py = py;
				i+=1;
				this.ctx.lineTo(px, py);
				this.ctx.strokeStyle = 'white';

				lastpY = py;
				lastpX = px;
			});
			//console.log("dataPoints", dataPoints);
			this.ctx.stroke();

			/*
			CREATING CLICKABLE CIRCLES AT EACH DATA POINT
			TODOS:
			CHECK WHY ONLY PARTIALLY CLICKABLE
			ADD FUNCTION FOR UPDATING THE POSITIONS OF THE CIRCLES DEPENDING ON ZOOM
				AND MAP CLICKING
			*/
			let circles = this.svgPoints.selectAll("circle")
				.data(dataPoints);

			circles.exit().remove();

			circles
				.enter().append("circle")
				.attr("class", "circle")
				.merge(circles)
				.on("click", function(d) {
					console.log(d.xValue)
				});

			let circleAttributes = circles
				.attr("z-index", 2)
				.attr("cx", function(d) {
					return d.px;
				})
				.attr("cy", function(d) {
					return d.py;
				})
				.attr("r", 5)
				.attr("x_value", function(d) {
					return d.xValue;
				})
				.attr("y_value", function(d) {
					return d.yValue;
				})
				.attr("fill", "red");
		},

		/**
		 * Draws spectrum when user zooms or moves the graph
		 */
		redrawSpectrum() {
			this.normedYValues = this.getNormedYValues();
			// Redraw spectrum with current zoom
			this.drawSpectrum(d3.zoomTransform(this.canvas.node()));

		},

		/**
		 * Called on user interaction
		 */
		zoomSpectrum() {
			return d3.zoom().scaleExtent([1, 100]).translateExtent([
					[0, 0],
					[this.canvasWidth, this.canvasHeight]
				]).extent([
					[0, 0],
					[this.canvasWidth, this.canvasHeight]
				])
				.on('zoom', () => {
					let transform = d3.event.transform;
					this.ctx.save();
					this.drawSpectrum(transform);
					this.ctx.restore();
				});
		},

		/**
		 * Norms the intensity values which are 0 to 255 to relative intensity values between 0 and 100
		 */
		getNormedYValues() {
			let maxY = Math.max.apply(null, this.yValues);
			let tmp_array = this.yValues.slice(0, this.xValues.length);
			return Array.from(tmp_array).map(val => val / maxY * 100);
		},

		/**
		 * Makes graph responsive.
		 * Recalculates the graph dom objects to fit screen, if it is rescaled by the user.
		 */
		fitToScreen() {

			this.doDomCalculations();

			this.canvas
				.attr('width', this.canvasWidth)
				.attr('height', this.canvasHeight)
				.style('margin-left', this.spectrumMargin.left + 'px')
				.style('margin-top', this.spectrumMargin.top + 'px');

			this.svgChart
				.attr('width', this.svgWidth)
				.attr('height', this.svgHeight)
				.style('margin-left', this.spectrumMargin.left + 'px')
				.style('margin-top', this.spectrumMargin.top + 'px');

				this.svgPoints = d3.select('.svg-plot').append('svg')
					.attr('width', this.canvasWidth)
					.attr('height', this.canvasHeight)
					.style('margin-left', this.spectrumMargin.left + 'px')
					.style('margin-top', this.spectrumMargin.top + 'px');

			this.svgGroup.attr('transform', `translate(${this.spectrumMargin.left}, ${this.spectrumMargin.top})`);


			this.x.range([0, this.canvasWidth]);
			this.y.range([this.canvasHeight, 0]);

			this.yAxis.tickSizeInner(-this.canvasWidth);

			this.gxAxis
				.attr('transform', `translate(0, ${this.canvasHeight})`)
				.call(this.xAxis);

			this.gyAxis
				.call(this.yAxis);
			this.redrawSpectrum();
		},

		/**
		 * Updates dom elements to current values, before new screen rescale
		 */
		doDomCalculations() {
			this.spectrumAxes = document.getElementById('spectrum-axes');
			this.canvasWidth = document.getElementById('spectrum-axes').offsetWidth - this.spectrumMargin.left - this.spectrumMargin.right;
			this.canvasHeight = document.getElementById('spectrum-axes').offsetHeight - this.spectrumMargin.bottom - this.spectrumMargin.top;
			this.svgWidth = document.getElementById('spectrum-axes').offsetWidth;
			this.svgHeight = document.getElementById('spectrum-axes').offsetHeight;

		}
	}
}
</script>

<style scoped>
#spectrum-axes {
	height: 100%;
	display: block;
	z-index: 1;
}

#spectrum-canvas {
	top: 0;
	left: 0;
	position: absolute;
	z-index: 1;
}
.circle{
top: 0;
left: 0;
position: absolute;
}

</style>
