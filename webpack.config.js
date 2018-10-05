const path = require('path')
const HtmlWebpackPlugin = require('html-webpack-plugin')

module.exports = {
    entry: './src/app.js',
    output: {
        path: path.resolve(__dirname, './dist'),
        filename: 'js/app.js'
    },
    plugins: [
        new HtmlWebpackPlugin({
            inject: true,
            filename: 'index.html',
            template: 'index.html'
        })
    ]

}