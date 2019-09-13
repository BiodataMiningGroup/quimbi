import Vue from 'vue';
import App from './App.vue';
import './assets/styles/styles.css';


import { library } from '@fortawesome/fontawesome-svg-core'
import { faUserSecret, faCog } from '@fortawesome/free-solid-svg-icons'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
library.add(faCog)
library.add(faUserSecret)



Vue.component('font-awesome-icon', FontAwesomeIcon)

import Vuesax from 'vuesax'
import 'vuesax/dist/vuesax.css' //Vuesax styles
Vue.use(Vuesax)


window.EventBus = new Vue();

// Create new Vue object
new Vue({
    el: '#app',
    render: h => h(App),
})
