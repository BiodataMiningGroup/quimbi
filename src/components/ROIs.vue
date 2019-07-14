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
        'mapValues'
    ],
    data() {
        return {
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
                if(item.title === "spectral regions"){
                    return item;
                }
            })[0];
            item.child.length = 0;
            this.appendSpectralValues(item);
        }

    },
    methods: {
        onItemClick(event, item) {
                switch (item.attributes["id"]) {
                    case "spectralRegions":
                        item.child.length = 0;
                        this.appendSpectralValues(item);
                        break;
                    case "mapRegions":
                        this.appendMapValues(item);
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
                            id: i,
                        }
                    });
                }
            },
            appendMapValues(item) {
                if (item.child.length > this.mapValues.length) {
                    return;
                }
                for (let i = 0; i < this.mapValues.length; i++) {
                    item.child.push({
                        title: this.mapValues[i],
                        attributes: {
                            id: i,
                        }
                    });
                }
            }
    }
}

</script>
