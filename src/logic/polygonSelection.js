import Feature from 'ol/Feature';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import Style from 'ol/style/Style';
import { Stroke } from 'ol/style.js';
import { LineString, Polygon } from 'ol/geom.js';

export default {
    data() {
        return {
            polygonMode: false,
            polygonSource: null,
            polygonLayer: null,
            polygonAreas: [],
            polygonAreaCounter: 0,
            polygonCoords: [],
            clickListener: null,
            tempLineFeature: null,
            highlightFeature: null,
            highlightStyle: null,
        };
    },

    methods: {
        // Layer & Source erzeugen
        setupPolygonLayer() {
            this.polygonSource = new VectorSource();
            this.polygonLayer = new VectorLayer({
                visible: true,
                source: this.polygonSource,
                style: this.getPolygonStyle,
            });
            return this.polygonLayer;
        },

        // UI
        togglePolygonAreaSelection() {
            if (this.polygonMode) {
                this.cancelAreaSelection();
            } else {
                this.startAreaSelection();
            }
        },
        startAreaSelection() {
            this.polygonMode = true;
            this.map?.un('click', this.updateMarkerPosition);
            this.polygonCoords = [];

            this.tempLineFeature = new Feature(new LineString([]));
            this.tempLineFeature.set('temp', true);
            this.polygonSource.addFeature(this.tempLineFeature);

            this.clickListener = this.handlePolygonClick;
            this.map.on('click', this.clickListener);
            this.map.on('pointermove', this.updateTempLineToMouse);
            window.addEventListener('keydown', this.handlePolygonKeydown);
        },
        cancelAreaSelection() {
            this.polygonMode = false;
            if (this.clickListener) {
                this.map.un('click', this.clickListener);
                this.clickListener = null;
            }
            this.polygonCoords = [];
            this.map?.on('click', this.updateMarkerPosition);
            this.map?.un('pointermove', this.updateTempLineToMouse);
            window.removeEventListener('keydown', this.handlePolygonKeydown);
            this.clearTempPolygonVisuals();
        },
        handlePolygonKeydown(event) {
            if (event.key === 'Escape' && this.polygonMode) {
                this.cancelAreaSelection();
            }
        },

        // Interaktionen
        updateTempLineToMouse(event) {
            if (!this.polygonCoords.length) return;
            const last = this.polygonCoords[this.polygonCoords.length - 1];
            const pointer = event.coordinate;
            this.tempLineFeature.getGeometry().setCoordinates([last, pointer]);
        },
        handlePolygonClick(event) {
            const coord = event.coordinate;

            if (this.polygonCoords.length > 2) {
                const first = this.polygonCoords[0];
                const dx = first[0] - coord[0];
                const dy = first[1] - coord[1];
                const dist = Math.sqrt(dx * dx + dy * dy);

                if (dist < 5) {
                    const polygon = new Polygon([[...this.polygonCoords, first]]);
                    const feature = new Feature(polygon);
                    this.polygonSource.addFeature(feature);
                    this.polygonAreaCounter += 1;

                    this.polygonAreas.push({
                        name: `Polygon: ${this.polygonAreaCounter}`,
                        active: true,
                        feature,
                    });

                    this.validateMarkerInArea();
                    this.clearTempPolygonVisuals();
                    this.cancelAreaSelection();
                    this.updatePolygonMask?.();
                    this.renderSimilarity?.();
                    return;
                }
            }

            this.polygonCoords.push(coord);

            if (this.polygonCoords.length > 1) {
                const last = this.polygonCoords[this.polygonCoords.length - 2];
                const lineFeature = new Feature(new LineString([last, coord]));
                lineFeature.set('temp', true);
                this.polygonSource.addFeature(lineFeature);
            }
        },
        clearTempPolygonVisuals() {
            const features = this.polygonSource.getFeatures();
            for (let i = features.length - 1; i >= 0; i--) {
                const f = features[i];
                if (f.get('temp')) {
                    this.polygonSource.removeFeature(f);
                }
            }
            this.tempLineFeature = null;
        },
        validateMarkerInArea() {
            const coord = this.markerFeature?.getGeometry().getCoordinates();
            const activePolygons = this.getActivePolygons();
            if (activePolygons.length === 0 || !coord) return;

            const inside = this.checkCoorInPolygons(coord);
            if (!inside) {
                this.markerLayer?.setVisible(false);
                this.emitUnselect?.();
                this.$emit('freeze', false);
            }
        },

        // Listen Aktionen
        togglePolygonArea(index) {
            this.polygonAreas[index].active = !this.polygonAreas[index].active;
            this.validateMarkerInArea();
            this.updatePolygonMask?.();
            this.renderSimilarity?.();
        },
        deletePolygonArea(index) {
            const feature = this.polygonAreas[index].feature;
            if (feature) this.polygonSource.removeFeature(feature);
            this.polygonAreas.splice(index, 1);
            this.validateMarkerInArea();
            this.updatePolygonMask?.();
            this.renderSimilarity?.();

            if (this.highlightFeature) {
                this.polygonSource.removeFeature(this.highlightFeature);
                this.highlightFeature = null;
            }
            this.polygonLayer?.changed();
        },
        highlightPolygon(feature) {
            if (this.highlightFeature) {
                this.polygonSource.removeFeature(this.highlightFeature);
                this.highlightFeature = null;
            }
            if (feature) {
                this.highlightFeature = feature.clone();
                this.highlightFeature.set('temp', true);
                this.highlightFeature.setStyle(this.highlightStyle);
                this.polygonSource.addFeature(this.highlightFeature);
            }
        },

        // Styles
        setHighlightStyle() {
            this.highlightStyle = [
                new Style({ stroke: new Stroke({ color: 'white', width: 16 }) }),
                new Style({ stroke: new Stroke({ color: 'rgba(106, 0, 255)', width: 6 }) }),
            ];
        },
        getPolygonStyle(feature) {
            for (const area of this.polygonAreas) {
                if (area.feature === feature) {
                    if (!area.active) return null;
                    break;
                }
            }
            return [
                new Style({ stroke: new Stroke({ color: 'white', width: 8 }),  fill: null }),
                new Style({ stroke: new Stroke({ color: 'rgba(106, 0, 255)', width: 4 }), fill: null }),
            ];
        },

        // Utils
        getActivePolygons() {
            const polygons = [];
            for (let i = 0; i < this.polygonAreas.length; i++) {
                const area = this.polygonAreas[i];
                if (area.active) {
                    polygons.push(area.feature);
                }
            }
            return polygons;
        },
        checkCoorInPolygons(point) {
            const polygons = this.getActivePolygons();

            if (!(polygons.length === 0)) {
                for (const feature of polygons) {
                    const geom = feature.getGeometry();
                    if (geom.intersectsCoordinate(point)) {
                        return true;
                    }
                }
            } else {
                return true;
            }
            return false;
        },
    },

    mounted() {
        this.setHighlightStyle?.();
    },
    beforeUnmount() {
        window.removeEventListener('keydown', this.handlePolygonKeydown);
    },
};
