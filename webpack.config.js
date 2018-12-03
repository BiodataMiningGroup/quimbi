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
            {
                test: /.(ttf|otf|eot|svg|woff(2)?)(\?[a-z0-9]+)?$/,
                use: [{
                    loader: 'file-loader',
                    options: {
                        name: '[name].[ext]',
                        outputPath: 'webfonts/',    // where the fonts will go
                    }
                }]
            },
        ],
    },
    resolve: {
        alias: {
            'node_modules': path.join(__dirname, 'node_modules'),
            'shader': path.join(__dirname, 'src/shader'),
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

        // Copy Fontawesome css
        new CopyWebpackPlugin([
            {
                from: './node_modules/@fortawesome/fontawesome-free/css/all.css',
                to: 'css/fontawesome.css',
                toType: 'file'
            }
        ]),
        // Copy Marker Icon
        new CopyWebpackPlugin([
            {
                from: './src/assets/marker.png',
                to: 'img/marker.png',
                toType: 'file'
            }
        ]),
    ]

};