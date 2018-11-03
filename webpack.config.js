const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const VueLoaderPlugin = require('vue-loader/lib/plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = {
    entry: './src/main.js',
    mode: 'development',
    output: {
        path: path.resolve(__dirname, './dist'),
        filename: 'js/main.js'
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                loader: 'babel-loader',
                exclude: /node_modules/,
                options: {
                    presets: [
                        '@babel/preset-env'
                    ]
                }
            },
            {
                test: /\.vue$/,
                loader: 'vue-loader'
            },
            {
                test: /\.css$/,
                use: [
                    'vue-style-loader',
                    {
                        loader: 'css-loader',
                        options: {
                            modules: true,
                            localIdentName: '[local]'
                        }
                    }
                ]

            },
        ],
    },
    resolve: {
        alias: {
            'node_modules': path.join(__dirname, 'node_modules'),
            'shader' : path.join(__dirname, 'src/shader'),
        }
    },
    plugins: [
        new HtmlWebpackPlugin({
            inject: true,
            filename: 'index.html',
            template: 'index.html'
        }),
        new VueLoaderPlugin(),
        // Copy Libaries
        new CopyWebpackPlugin([
            {
                from: './src/libs',
                to: 'js/libs',
                toType: 'dir'
            }
        ]),
        // Copy Openlayers CSS
        new CopyWebpackPlugin([
            {
                from: './node_modules/ol/ol.css',
                to: 'css/ol.css',
                toType: 'file'
            }
        ]),
        // Copy Shader
        new CopyWebpackPlugin([
            {
                from: './src/shader',
                to: 'shader',
                toType: 'dir'
            }
        ]),
    ]

};