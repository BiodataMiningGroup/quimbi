<style>

.vs-sidebar {
    height: 65vh !important;
}

.vs-sidebar--background {
    height: auto !important;
    width: auto !important;
}

.header-sidebar {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    width: 100%;
}

.header-sidebar h4 {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 100%;
}

.header-sidebar h4 > button {
    margin-left: 10px;
}

.footer-sidebar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
}

.footer-sidebar > button {
    border: 0px solid rgba(0, 0, 0, 0) !important;
    border-left: 1px solid rgba(0, 0, 0, 0.07) !important;
    border-radius: 0px !important;
}

</style>

<template>

<div id="sidebar">
    <vs-sidebar :reduce="reduce" :reduce-not-hover-expand="notExpand" parent="body" default-index="1" color="success" class="sidebarx" spacer v-model="active">
        <div class="header-sidebar" slot="header">
            <p>Interesting Regions</p>
        </div>
        <vs-divider icon-pack="fa" icon="fa fa-draw-polygon" position="center">Map Regions</vs-divider>
        <!--
        <vs-sidebar-group open title="Map Regions">
        -->
        <div v-for="(mapROI, index) in mapROIs">
            <vs-sidebar-group close :title="'Region ' + index">
                <vs-button icon-pack="fa" icon="fa-eye" color="danger" type="flat" @click="visibilityArea(mapROI.coords.toString())">show</vs-button>
                <vs-button icon-pack="fa" icon="fa-trash" color="danger" type="flat" @click="removeArea(mapROI.coords.toString())">remove</vs-button>
            </vs-sidebar-group>
        </div>
        <!--
        </vs-sidebar-group>
        -->
        <vs-divider icon-pack="fa" icon="fa fa-chart-area" />
        <!--
        <vs-sidebar-group open title="Spectral Regions">
        -->
        <div v-for="spectralROI in spectralROIs">
            <vs-sidebar-group close :title="spectralROI.id[0] + '-' + spectralROI.id[1]">
                <vs-button icon-pack="fa" icon="fa-eye" color="danger" type="flat" @click="visibilitySpectrum(spectralROI.id.toString())">show</vs-button>
                <vs-button icon-pack="fa" icon="fa-trash" color="danger" type="flat" @click="removeSpectrum(spectralROI.id.toString())">remove</vs-button>
            </vs-sidebar-group>
        </div>
        <!--
        </vs-sidebar-group>
        -->
    </vs-sidebar>
</div>

</template>

<script>

export default {
    props: [
        'spectralROIs',
        'mapROIs'
    ],
    data() {
        return {
            active: true,
            notExpand: false,
            reduce: true,
        }
    },
    methods: {
        removeSpectrum(id) {
                this.$emit("removespectrum", id);
            },
            visibilitySpectrum(id) {
                this.$emit("visibilityspectrum", id);
            },
            removeArea(id) {
                this.$emit("removearea", id);
            },
            visibilityArea(id) {
                this.$emit("visibilityarea", id);

            },
    }

}

</script>
