<style>
  .v-sidebar-menu {
    height: 65%;
  }
</style>

<template>

<sidebar-menu :menu="menu" />

</template>

<script>

export default {
    data() {
        return {
            menu: [{
                header: true,
                title: 'Interesting Regions',
                // component: componentName
                visibleOnCollapse: false
                    // class: ''
                    // attributes: {}
            }, {
                href: '/',
                title: 'Dashboard',
                icon: 'fa fa-user',
                /*
                // custom icon
                icon: {
                    element: 'span',
                    class: 'fa fa-user',
                    attributes: {}
                    text: ''
                }
                */
                // disabled: true
                // class: ''
                // attributes: {}
                // alias: '/path'
                /*
                badge: {
                    text: 'new',
                    class: 'default-badge'
                    // attributes: {}
                    // element: 'span'
                }
                */
            }, {
                title: 'Charts',
                icon: 'fa fa-chart-area',
                child: [{
                    href: '/charts/sublink',
                    title: 'Sub Link',
                }]
            }]
        }
    }
}

</script>
