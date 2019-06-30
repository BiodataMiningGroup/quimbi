import Vue from 'vue'
import App from './App.vue'
import './assets/styles/styles.css';
import VueSidebarMenu from 'vue-sidebar-menu'
import 'vue-sidebar-menu/dist/vue-sidebar-menu.css'

Vue.use(VueSidebarMenu)


// Create new Vue object
new Vue({
    el: '#app',
    render: h => h(App)
})
