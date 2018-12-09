<template>
    <div id="spectrum-wrapper">
        <div id="spectrum-axes">
            <canvas id="spectrum-canvas"></canvas>
        </div>
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
                // Zooom Factor of Spectrum when Points get visible
                zoomFactorPoints: 2
            }
        },
        mounted() {
            this.initCanvas();
            this.drawSpectrum(d3.zoomIdentity);

        },
        methods: {
            initCanvas() {
                let margin = {
                    bottom: 30,
                    left: 60,
                    top: 10,
                    right: 10

                };


                this.spectrumAxes = document.getElementById('spectrum-axes');
                this.canvasWidth = document.getElementById('spectrum-axes').offsetWidth - margin.left - margin.right;
                this.canvasHeight = document.getElementById('spectrum-axes').offsetHeight - margin.bottom - margin.top;

                this.svgWidth = document.getElementById('spectrum-axes').offsetWidth;
                this.svgHeight = document.getElementById('spectrum-axes').offsetHeight;

                // Init Canvas
                this.canvas = d3.select('#spectrum-canvas')
                    .attr('width', this.canvasWidth).attr('height', this.canvasHeight)
                    .style('margin-left', margin.left + 'px')
                    .style('margin-top', margin.top + 'px');

                // Init SVG
                const svgChart = d3.select('#spectrum-axes').append('svg:svg')
                    .attr('width', this.svgWidth)
                    .attr('height', this.svgHeight)
                    .attr('class', 'svg-plot')
                    .append('g')
                    .attr('transform', `translate(${margin.left}, ${margin.top})`);

                this.ctx = this.canvas.node().getContext('2d');

                // Init Scales
                this.xValues.forEach((val, i) => {
                    this.tickXValues[i] = i;
                });
                console.log(this.tickValues);

                this.x = d3.scaleLinear()
                    .domain([0, this.xValues.length - 1])
                    .range([0, this.canvasWidth]);
                this.y = d3.scaleLinear()
                    .domain([0, 100])
                    .range([this.canvasHeight, 0]);


                // Workaround to use channel name labels in tickFormat
                let xVars = this.xValues;
                // Init Axis
                this.xAxis = d3.axisBottom(this.x).tickFormat(function (d, i) {
                    return xVars[i];
                });
                this.yAxis = d3.axisLeft(this.y);

                this.gxAxis = svgChart.append('g')
                    .attr('transform', `translate(0, ${this.canvasHeight})`)
                    .attr("class", "axisx")
                    .call(this.xAxis);

                this.gyAxis = svgChart.append('g')
                    .attr("class", "axisy")
                    .call(this.yAxis);

                this.canvas.call(this.zoomSpectrum());


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


                // Init lastpX/Y
                let lastpX = 0;
                let lastpY = this.canvasHeight;
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
                            this.ctx.arc(px, py, 0.2 * transform.k, 0, 2 * Math.PI, true);
                            this.ctx.fill();
                        }
                    });
                }


                //Draw line between current and the point before
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

                    this.ctx.lineTo(px, py);
                    this.ctx.strokeStyle = 'white';

                    lastpY = py;
                    lastpX = px;
                });
                this.ctx.stroke();

            },

            redrawSpectrum() {
                this.normYValues();
                // Redraw spectrum with current zoom
                this.drawSpectrum(d3.zoomTransform(this.canvas.node()));

            },
            zoomSpectrum() {
                return d3.zoom().scaleExtent([1, 100]).translateExtent([[0, 0], [this.canvasWidth, this.canvasHeight]]).extent([[0, 0], [this.canvasWidth, this.canvasHeight]])
                    .on('zoom', () => {
                        let transform = d3.event.transform;
                        this.ctx.save();
                        this.drawSpectrum(transform);
                        this.ctx.restore();
                    });
            },
            normYValues() {
                let maxY = this.findMaxYValue();
                this.normedYValues = this.yValues.map(val => val / maxY * 100);
                console.log(this.normedYValues);
            },
            findMaxYValue() {
                let maxValue = 0;
                this.yValues.forEach(val => {
                    if (val > maxValue) {
                        maxValue = val;
                    }
                });
                return maxValue;
            }
        }
    }

</script>

<style scoped>
    #spectrum-axes {
        width: 100%;
        height: 100%;
        position: absolute;
    }

    #spectrum-canvas {
        position: absolute;
    }


</style>