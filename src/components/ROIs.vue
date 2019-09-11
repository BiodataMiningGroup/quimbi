<style>

.v-sidebar-menu {
    height: 65% !important;
}

</style>

<template>

<sidebar-menu id="sidebar" :collapsed="true" @item-click="onItemClick" :menu="menu"/>

</template>

<script>

export default {
    props: [
        'spectralROIs',
    ],
    data() {
            return {
                mapROIs: null,
                menu: [{
                    header: true,
                    title: 'Interesting Regions',
                    hiddenOnCollapse: true,
                }, {
                    component: "spectralRegions",
                    title: 'spectral regions',
                    attributes: {
                        id: "spectralRegions",
                    },
                    icon: {
                        element: 'span',
                        class: 'fa fa-chart-area',
                        attributes: {},
                        text: '',
                    },
                    child: [{
                        title: '',
                        attributes: {
                            id: "spectralChild",
                        },
                    }],
                }, {
                    component: "mapRegions",
                    title: 'map regions',
                    attributes: {
                        id: "mapRegions",
                    },
                    icon: {
                        element: 'span',
                        class: 'fa fa-draw-polygon',
                        attributes: {},
                        text: '',
                    },
                    child: [{
                        title: '',
                        attributes: {
                            id: "mapChild",
                        },
                    }],
                }],
            }
        },
        watch: {
            //function to watch for changes in spectrumValues in order to recalculate the sidebar
            'spectralROIs': function() {
                let item = this._data.menu.filter((item) => {
                    if (item.title === "spectral regions") {
                        return item;
                    }
                })[0];
                item.child.length = 0;
                this.appendspectralROIs(item);
            },
            //function to watch for changes in mapROIs in order to recalculate the sidebar
            'mapROIs': function() {
                let item = this._data.menu.filter((item) => {
                    if (item.title === "map regions") {
                        return item;
                    }
                })[0];
                item.child.length = 0;
                this.appendMapROIs(item);
            }

        },
        mounted() {
            let that = this;
            //Todo add communication to both .vue
            //communication from IntensityMap.vue
            EventBus.$on('addMapROI', mapROIs => {
                that.mapROIs = mapROIs;
            });
            //communication from Spectrum.vue
            EventBus.$on('addSpectralROI', spectralROIs => {
                that.spectralROIs = spectralROIs;
            });
        },

        methods: {
            onItemClick(event, item) {
                    switch (item.attributes["id"]) {
                        case "spectralRegions":
                            item.child.length = 0;
                            this.appendspectralROIs(item);
                            break;
                        case "mapRegions":
                            item.child.length = 0;
                            this.appendMapROIs(item);
                            break;
                    };
                },

                appendspectralROIs(item) {
                    if (item.child.length >= this.spectralROIs.length) {
                        return;
                    }
                    for (let i = 0; i < this.spectralROIs.length; i++) {
                        let range = this.spectralROIs[i].id;
                        item.child.push({
                            title: range,
                            attributes: {
                                id: "spectral" + i,
                            },
                            icon: {
                                class: 'fa fa-eye',
                            },
                            badge: {
                                class: 'fa fa-trash',
                                element: 'button',
                            },
                        });
                    }
                },
                appendMapROIs(item) {
                    if (item.child.length > this.mapROIs.length) {
                        return;
                    }
                    for (let i = 0; i < this.mapROIs.length; i++) {
                        item.child.push({
                            title: "region " + i,
                            attributes: {
                                id: "region" + i,
                            },
                            /*
                            icon: {
                                class: 'fa fa-eye',
                            },
                            badge: {
                                class: 'fa fa-trash',
                                element: 'button',
                            },
                            */
                            child: [{
                                title: 'show',
                                badge: {
                                    element: 'button',
                                    class: 'fa fa-eye',
                                },
                            }, {
                                title: 'remove',
                                badge: {
                                    element: 'button',
                                    class: 'fa fa-trash',
                                },
                            }],
                        });
                    }
                }
        }
}

</script>
