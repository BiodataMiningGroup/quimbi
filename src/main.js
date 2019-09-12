import Vue from 'vue';
import App from './App.vue';
import './assets/styles/styles.css';

import Vuesax from 'vuesax'

import 'vuesax/dist/vuesax.css' //Vuesax styles
Vue.use(Vuesax)


window.EventBus = new Vue();

// Create new Vue object
new Vue({
    el: '#app',
    render: h => h(App),
})
