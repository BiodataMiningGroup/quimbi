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
        <vs-sidebar-group open title="Application">
        <vs-sidebar-item index="1" icon-pack="fa" icon="fa-cog" @click="reduce=!reduce">
         Toggle Sidebar 
        </vs-sidebar-item>
        </vs-sidebar-group>
        <vs-sidebar-group open title="Map Regions">
            <vs-sidebar-item v-for="mapROI in mapROIs"  icon="menu">
                Toggle Sidebar
            </vs-sidebar-item>
        </vs-sidebar-group>
        <vs-divider/>
        <vs-sidebar-group open title="Spectral Regions">
            <vs-sidebar-item v-for="spectralROI in spectralROIs" icon="menu">
                Toggle Sidebar
            </vs-sidebar-item>
        </vs-sidebar-group>
        <!--
        <div class="footer-sidebar" slot="footer">
            <vs-button icon="settings" color="primary" type="border"></vs-button>
        </div>
        -->
    </vs-sidebar>
</div>

</template>

<script>

export default {
    props: [
        'spectralROIs',
    ],
    data() {
        return {
            mapROIs: null,
            active: true,
            notExpand: false,
            reduce: true,
            /*
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
            }], */
        }
    },

}

</script>
