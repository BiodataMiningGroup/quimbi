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

            }
        ],
    },
    resolve: {
        // Todo Laden über Symlink klappt nicht
        //symlinks: true,
        alias: {
            'node_modules': path.join(__dirname, 'node_modules'),
        }
    },
    plugins: [
        new HtmlWebpackPlugin({
            inject: true,
            filename: 'index.html',
            template: 'index.html'
        }),
        new VueLoaderPlugin(),
        /*new CopyWebpackPlugin([
            {
                from: './data',
                to: 'data',
                toType: 'dir'
            }
        ]),*/
        new CopyWebpackPlugin([
            {
                from: './src/libs',
                to: 'js/libs',
                toType: 'dir'
            }
        ]),
        new CopyWebpackPlugin([
            {
                from: './node_modules/ol/ol.css',
                to: 'css/ol.css',
                toType: 'file'
            }
        ])
    ]

};