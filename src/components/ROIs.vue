<style>

.vs-sidebar {
    height: 100%;
    background: #353535 !important;
}

.vs-sidebar--background {
    height: 100%;
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

</style> <style scoped> .fa {
    font-size: 12px;
}

.button {
    height: 22.5px;
    width: 40px;
}

</style>

<template>

<vs-sidebar :reduce="reduce" :reduce-not-hover-expand="notExpand" default-index="1" color="success" class="sidebarx" spacer v-model="active" id="sidebar">
    <div class="header-sidebar" slot="header">
        <p>ROI</p>
    </div>
    <vs-divider icon-pack="fa" icon="fa fa-draw-polygon" position="center">Map Regions</vs-divider>

    <vs-sidebar-group open title="Map Regions">
        <div v-for="(mapROI, index) in mapROIs">
            <vs-sidebar-group open :title="'Region ' + index">
                <div class="has-addons" style="text-align:center">
                    <a class="button" color="red" type="flat" active=false @click="activationArea($event, mapROI.coords.toString())"><i class="fa fa-toggle-off"></i></a>
                    <a class="button" color="white" type="flat" active=true @click="visibilityArea($event, mapROI.coords.toString())"><i class="fa fa-eye"></i></a>
                    <a class="button" color="white" type="flat" active=true @click="removeArea(mapROI.coords.toString())"><i class="fa fa-trash""></i></a>
                </div>
            </vs-sidebar-group>
        </div>
    </vs-sidebar-group>
    <vs-divider icon-pack="fa" icon="fa fa-chart-area" />
    <vs-sidebar-group open title="Spectral Regions">
        <div v-for="spectralROI in spectralROIs">
            <vs-sidebar-group open :title="spectralROI.id.toString()">
                <div class="has-addons" style="text-align:center">
                    <a class="button" color="white" type="flat" active=false @click="activationSpectrum($event, spectralROI.id.toString())"><i class="fa fa-toggle-off"></i></a>
                    <a class="button" color="white" type="flat" active=true @click="visibilitySpectrum($event, spectralROI.id.toString())"><i class="fa fa-eye"></i></a>
                    <a class="button" color="white" type="flat" active=true @click="removeSpectrum(spectralROI.id.toString())"><i class="fa fa-trash""></i></a>
                </div>
            </vs-sidebar-group>
        </div>
    </vs-sidebar-group>
</vs-sidebar>

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
    mounted() {
        this.setVSSidebarGroupLogo();
    },
    updated() {
        this.setVSSidebarGroupLogo();
    },
    methods: {
            removeSpectrum(id) {
                this.$emit("removespectrum", id);
            },
            activationSpectrum(event, id) {
                this.spectralROIs.forEach((roi) => {
                    let roiID = roi.id.toString();
                    if (roiID === id) {
                        roi.active = !roi.active;
                        let element = event.currentTarget.firstChild;
                        if (roi.active == true) {
                            element.classList.remove('fa-toggle-off');
                            element.classList.add('fa-toggle-on');
                        } else {
                            element.classList.remove('fa-toggle-on');
                            element.classList.add('fa-toggle-off');
                        }
                        this.$emit("activationspectrum", id);
                    }
                });
            },
            visibilitySpectrum(event, id) {
                this.spectralROIs.forEach((roi) => {
                    let roiID = roi.id.toString();
                    if (roiID === id) {
                        roi.visible = !roi.visible;
                        let element = event.currentTarget.firstChild;
                        if (roi.visible == true) {
                            element.classList.remove('fa-eye-slash');
                            element.classList.add('fa-eye');
                        } else {
                            element.classList.remove('fa-eye');
                            element.classList.add('fa-eye-slash');
                        }
                        this.$emit("visibilityspectrum", id);        
                    }
                });
            },
            removeArea(id) {
                this.$emit("removearea", id);
            },
            activationArea(event, id) {
                this.mapROIs.forEach((roi) => {
                    let roiID = roi.coords.toString();
                    if (roiID === id) {
                        roi.active = !roi.active;
                        let element = event.currentTarget.firstChild;
                        if (roi.active == true) {
                            element.classList.remove('fa-toggle-off');
                            element.classList.add('fa-toggle-on');
                        } else {
                            element.classList.remove('fa-toggle-on');
                            element.classList.add('fa-toggle-off');
                        }
                        this.$emit("activationarea", id);
                    }
                });
            },

            visibilityArea(event, id) {
                this.mapROIs.forEach((roi) => {
                    let roiID = roi.coords.toString();
                    if (roiID === id) {
                        roi.visible = !roi.visible;
                        let element = event.currentTarget.firstChild;
                        if (roi.visible == true) {
                            element.classList.remove('fa-eye-slash');
                            element.classList.add('fa-eye');
                        } else {
                            element.classList.remove('fa-eye');
                            element.classList.add('fa-eye-slash');
                        }
                        this.$emit("visibilityarea", id);
                    }
                });
            },
            setVSSidebarGroupLogo() {
                for (let x of document.getElementById("sidebar").getElementsByClassName("vs-sidebar-group")) {
                    let element = x.getElementsByTagName("i")[0];
                    element.classList.remove('material-icons');
                    element.classList.add('fa');
                    element.classList.add('fa-chevron-down');
                    element.innerHTML = "";
                }
            }
    }

}

</script>
