<style>

.v-sidebar-menu {
    height: 65% !important;
}

</style>

<template>

<sidebar-menu :collapsed="true" @item-click="onItemClick" :menu="menu" />

</template>

<script>

export default {
    props: [
        'spectralValues',
    ],
    data() {
        return {
            mapROIs: null,
            menu: [{
                header: true,
                title: 'Interesting Regions',
                visibleOnCollapse: false,
            }, {
                title: 'spectral regions',
                attributes: {
                    id: "spectralRegions",
                },
                icon: {
                    element: 'span',
                    class: 'fa fa-user',
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
                title: 'map regions',
                attributes: {
                    id: "mapRegions",
                },
                icon: {
                    element: 'span',
                    class: 'fa fa-user',
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
        'spectralValues': function() {
            let item = this._data.menu.filter((item) => {
                if (item.title === "spectral regions") {
                    return item;
                }
            })[0];
            item.child.length = 0;
            this.appendSpectralValues(item);
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
        //communication with IntensityMap.vue
        EventBus.$on('addMapROI', mapROIs => {
            that.mapROIs = mapROIs;
            that.mapROIs[0].visible = false;
        });
    },

    methods: {
        onItemClick(event, item) {
                switch (item.attributes["id"]) {
                    case "spectralRegions":
                        item.child.length = 0;
                        this.appendSpectralValues(item);
                        break;
                    case "mapRegions":
                        item.child.length = 0;
                        this.appendMapROIs(item);
                        break;
                }
            },

            appendSpectralValues(item) {
                if (item.child.length >= this.spectralValues.length) {
                    return;
                }
                for (let i = 0; i < this.spectralValues.length; i++) {
                    let range = this.spectralValues[i][0].xValue + ' - ' + this.spectralValues[i][this.spectralValues[i].length - 1].xValue;
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
                        title: "Region " + i,
                        attributes: {
                            id: "region" + i,
                        },
                        icon: {
                            class: 'fa fa-eye',
                        },
                        badge: {
                            class: 'fa fa-trash',
                            element: 'button',
                        },
                        /*
                        child: [{
                            title: 'show',
                            badge: {
                                element: 'button',
                                class: 'fa fa-eye',

                            },
                            hiddenOnCollapse: false
                        }, {
                            title: 'remove',
                            badge: {
                                element: 'button',
                                class: 'fa fa-trash',
                            },
                            hiddenOnCollapse: false
                        }],
                        */
                    });
                }
            }
    }
}

</script>
