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
                this.x = d3.scaleLinear()
                    .domain([0, 54])
                    .range([0, this.canvasWidth])
                    .nice();
                this.y = d3.scaleLinear()
                    .domain([0, 255])
                    .range([this.canvasHeight, 0])
                    .nice();

                // Init Axis
                this.xAxis = d3.axisBottom(this.x);
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

                this.gxAxis.call(this.xAxis.scale(scaleX));
                this.gyAxis.call(this.yAxis.scale(scaleY));
                this.ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

                console.log(this.yValues);
                this.yValues.forEach((point, index) => {
                    console.log(point);
                    this.ctx.beginPath();
                    this.ctx.fillStyle = '#3585ff';
                    const px = scaleX(index);
                    const py = scaleY(point);

                    this.ctx.arc(px, py, 1.2 * transform.k, 0, 2 * Math.PI, true);
                    this.ctx.fill();
                });

            },

            redrawSpectrum() {
                this.drawSpectrum(d3.zoomIdentity);

            },
            zoomSpectrum() {
                return d3.zoom().scaleExtent([1, 1000])
                    .on('zoom', () => {
                        let transform = d3.event.transform;
                        this.ctx.save();
                        this.drawSpectrum(transform);
                        this.ctx.restore();
                    });
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