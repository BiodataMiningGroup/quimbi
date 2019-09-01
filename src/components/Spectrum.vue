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

.circle {
    top: 0;
    left: 0;
    position: absolute;
}

</style>

<template>

<div id="spectrum-axes">
    <canvas @mousemove.shift="updateInterestingSpectrals" @mousemove="createAnnotation" @mouseover="setCanvasFocus" @mouseout="clearCanvasFocus" id="spectrum-canvas" tabindex='1'></canvas>
</div>

</template>

<script>

import * as d3 from '../../node_modules/d3/dist/d3';
import * as d3annotate from '../../node_modules/d3-svg-annotation';

export default {
    props: [
        'xValues',
        'yValues',
        'channelTextureDimension',
        'renderHandler'
    ],
    data() {
        return {
            data: [],
            canvas: {},
            svgChart: {},
            svgGroup: {},
            svgSquares: {},
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
            dataPoints: [],
            qdtree: {},
            // holds the temporary spectrum range during the selection phase
            interestingSpectrals: [],
            // holds all selected spectrals
            spectralROIs: [],
            zoomFactor: 1,
            channelMask: undefined,
            xValueIndexMap: []
        }
    },
    /**
     * Created the graph and draw it once without values not zoomed
     */
    mounted() {
        this.channelMask = new Uint8Array(this.channelTextureDimension *
            this.channelTextureDimension * 4
        );
        this.initGraph();
        this.drawSpectrum(d3.zoomIdentity);
        document.getElementById('spectrum-canvas').addEventListener('keyup', (e) => {
            if (e.key == 'Shift' && this.interestingSpectrals.length > 1) {
                this.add2spectralROIs();
            }
        }, false);
        this.xValues.forEach((point, index) => {
          this.xValueIndexMap[point] = index;
        });
        //call once to create an full mask
        this.updateChannelMaskWith();

    },
    methods: {

        initGraph() {
                this.qdtree = d3.quadtree();
                this.doDomCalculations();
                // Init Canvas
                this.canvas = d3.select('#spectrum-canvas')
                    .on('mouseup', this.clearMousePressed)
                    .attr('width', this.canvasWidth)
                    .attr('height', this.canvasHeight)
                    .style('margin-left', this.spectrumMargin.left + 'px')
                    .style('margin-top', this.spectrumMargin.top + 'px');

                // Init SVG
                this.svgChart = d3.select('#spectrum-axes').append('svg:svg')
                    .style('position', 'absolute')
                    //.style('z-index', '2')
                    .attr('width', this.svgWidth)
                    .attr('height', this.svgHeight)
                    .attr('class', 'svg-plot');

                this.svgGroup = this.svgChart.append('g')
                    .style('position', 'absolute')
                    .attr('transform', `translate(${this.spectrumMargin.left}, ${this.spectrumMargin.top})`);


                //Extra SVG for the selected regions layer
                this.svgSquares = d3.select('.svg-plot').append('svg')
                    .style('position', 'absolute')
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
                let that = this;

                let scaleX = transform.rescaleX(this.x);
                let scaleY = transform.rescaleY(this.y);

                this.gxAxis.call(this.xAxis.scale(scaleX).tickFormat((d, e, target) => {
                    // has bug when the scale is too big
                    if (Math.floor(d) === d3.format(".1f")(d)) {
                        return this.xValues[Math.floor(d)];
                    }
                    return this.xValues[d];

                }));
                this.gyAxis.call(this.yAxis.scale(scaleY));
                this.ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

                this.qdtree.removeAll(this.dataPoints);
                this.dataPoints = [];

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
                let i = 0;
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
                    this.dataPoints.push({});
                    this.dataPoints[i].xValue = this.xValues[index];
                    this.dataPoints[i].normyValue = this.normedYValues[index];
                    this.dataPoints[i].px = px;
                    this.dataPoints[i].py = py;
                    i += 1;
                    this.ctx.lineTo(px, py);
                    this.ctx.strokeStyle = 'white';

                    lastpY = py;
                    lastpX = px;
                });
                this.ctx.stroke();

                //adding quadtree and dataPoints to the canvas
                this.qdtree
                    .x(function(d) {
                        return d.px;
                    })
                    .y(function(d) {
                        return that.canvasHeight;
                    })
                    .extent([
                        [0, 0],
                        [this.canvasWidth, this.canvasHeight]
                    ])
                    .addAll(this.dataPoints);
                /**
                 * draw the datapoint circles onto the canvas
                 */
                this.dataPoints.forEach((p, i) => {
                    this.ctx.beginPath();
                    this.ctx.arc(p.px, p.py, 2, 0, 2 * Math.PI);
                    this.ctx.fillStyle = "teal";
                    this.ctx.fill();
                });
            },

            /**
             * Creates a svg layer containing annotations for the closest datapoint in the spectrum
             */
            createAnnotation(event) {
                let mouse = [event.offsetX, event.offsetY];
                let annotation_spacing = 20;

                //get the position of the nearest datapoint in the quadtree (the spectrum)
                let closest = this.qdtree.find(mouse[0], mouse[1]);
                if (typeof closest === 'undefined' || typeof closest["py"] === 'undefined') {
                    d3.select(".annotation-group").remove();
                    return;
                }
                let annotation_text = 'xValue: ' + closest["xValue"] + '\n' + 'yValue: ' + closest["normyValue"];
                let annotations = [{
                    note: {
                        label: annotation_text,
                        bgPadding: 20,
                        //create a newline whenever you read this symbol
                        wrapSplitter: '\n',
                    },
                    subject: {
                        radius: 10,
                    },
                    x: closest["px"],
                    y: closest["py"] + annotation_spacing,
                    className: "show-bg",
                    dx: 10,
                    ny: 45,
                    color: "teal",
                    type: d3annotate.annotationCalloutCircle
                }];
                //remove previous annotation s.th. only one annotation at a time is visible
                d3.select(".annotation-group").remove();

                //create the annotation with the above specifications
                let makeAnnotations = d3annotate.annotation()
                    .editMode(false)
                    .annotations(annotations);

                //add svg plane containing the annotation behind/below the spectrum canvas
                d3.select('.svg-plot').append('svg')
                    .attr("class", "annotation-group")
                    .attr('width', this.canvasWidth)
                    .attr('height', this.canvasHeight + annotation_spacing)
                    .attr('transform', `translate(${this.spectrumMargin.left}, ${this.spectrumMargin.top-annotation_spacing})`)
                    .call(makeAnnotations);
            },

            updateChannelMaskWith() {
                let channel = this.xValues.length;

                // number of active channels of the channel mask
                let activeChannels = 0;

                if (this.spectralROIs.length !== 0 && this.spectralROIs.filter(roiObject => {
                        return roiObject.visible === true
                    }).length !== 0) {
                    // clear mask
                    while (channel--) {
                        this.channelMask[channel] = 0;
                    }
                    for (let i = 0; i < this.spectralROIs.length; i++) {
                        if (this.spectralROIs[i].visible == true) {
                            let offset = this.spectralROIs[i].range;
                            activeChannels += offset;
                            while (offset--) {
                                this.channelMask[this.xValueIndexMap[this.spectralROIs[i].id[0]] + offset] = 255;
                            }
                        }
                    }

                } else {
                    activeChannels = channel;
                    while (channel--) {
                        this.channelMask[channel] = 255;
                    }
                }
                console.log(this.channelMask);
                console.log(activeChannels);
                this.renderHandler.updateChannelMask(this.channelMask, activeChannels);
            },

            /**
             * adding a newly selected region of spectral values to the overall interesting regions array.
             */
            add2spectralROIs() {
                if (this.interestingSpectrals[0].xValue > this.interestingSpectrals[this.interestingSpectrals.length - 1].xValue) {
                    this.interestingSpectrals = this.interestingSpectrals.reverse();
                }
                let regionId = [this.interestingSpectrals[0].xValue, this.interestingSpectrals[this.interestingSpectrals.length - 1].xValue];
                this.spectralROIs.push({
                    pxs: [this.interestingSpectrals[0].px, this.interestingSpectrals[this.interestingSpectrals.length - 1].px],
                    id: regionId,
                    visible: true,
                    range: (this.xValueIndexMap[regionId[1]]-this.xValueIndexMap[regionId[0]])+1
                });
                this.svgSquares.append('rect')
                    .attr('fill', "white")
                    .style('position', 'absolute')
                    .style('opacity', 0.25)
                    .attr("id", regionId)
                    .attr('height', this.canvasHeight)
                    .attr('y', 0)
                    .attr('width', (this.interestingSpectrals[this.interestingSpectrals.length - 1].px - this.interestingSpectrals[0].px))
                    .attr('x', this.interestingSpectrals[0].px);

                this.interestingSpectrals = [];
                this.updateChannelMaskWith();
                EventBus.$emit('addSpectralROI', this.spectralROIs);
            },

            /**
             * updating the temporary interestingSpectrals array - meaning that either a new element is added or removed, depending on if the selected region on the spectral-canvas is increased or decreased.
             */
            updateInterestingSpectrals(event) {
                let mouse = [event.offsetX, event.offsetY];
                //get the position of the nearest datapoint in the quadtree (the spectrum)
                let closest = this.qdtree.find(mouse[0], mouse[1]);
                let interSpecLen = this.interestingSpectrals.length;
                if (interSpecLen == 0 || closest != this.interestingSpectrals[interSpecLen - 1]) {
                    if (closest == this.interestingSpectrals[interSpecLen - 2]) {
                        this.interestingSpectrals.length -= 1;
                    } else {
                        this.interestingSpectrals.push(closest);
                    }
                }
            },

            /**
             * Recalculates the position of the selected region boxes and redraws them.
             */
            redrawSelectedRegions(transform) {
                let regions = this.svgSquares.selectAll('rect')
                    .data(this.spectralROIs);
                regions.remove();
                let indexArray = [];
                let scaleX = transform.rescaleX(this.x);
                let that = this;
                this.normedYValues.forEach((point, index) => {
                    indexArray[that.xValues[index]] = scaleX(index);
                });
                regions.enter().append('rect')
                    .filter(function(d) {
                        return d.visible === true
                    })
                    .attr('fill', "white")
                    .style('position', 'absolute')
                    .style('opacity', 0.25)
                    .attr("id", function(d) {
                        return d.id;
                    })
                    .attr('height', this.canvasHeight)
                    .attr('y', 0)
                    .attr('width', function(d) {
                        return (indexArray[d.id[1]] - indexArray[d.id[0]]);
                    })
                    .attr('x', function(d) {
                        return indexArray[d.id[0]];
                    })
            },

            /**
             * setting the spectrum-canvas focussed s.th. it will recognize key events.
             */
            setCanvasFocus() {
                document.getElementById('spectrum-canvas').focus();
            },
            /**
             * clears the spectrum-canvas focussed s.th. it won't recognize key events.
             */
            clearCanvasFocus() {
                document.getElementById('spectrum-canvas').blur();
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
                        this.zoomFactor = transform.k;
                        this.ctx.save();
                        this.drawSpectrum(transform);
                        this.redrawSelectedRegions(transform);
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

            },
    }
}

</script>
