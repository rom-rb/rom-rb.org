var webpack = require('webpack');
var path = require('path');
var Clean = require('clean-webpack-plugin');
var ExtractTextPlugin = require('extract-text-webpack-plugin');

module.exports = {
  debug: true,

  entry: {
    main: [
      './assets/javascripts/all.js',
      './assets/stylesheets/all.css.scss',
    ],
  },

  output: {
    path: __dirname + '/.tmp/dist',
    filename: 'assets/javascripts/all.js',
  },

  module: {
    preLoaders: [{
      test: /\.scss$/,
      exclude: /node_modules|\.tmp|vendor/,
      loader: 'import-glob',
    }],

    loaders: [
      { test: /\.js?$/, loader: "babel", exclude: /node_modules/ },
      { test: /\.scss$/, exclude: /node_modules|\.tmp|vendor/, loader: ExtractTextPlugin.extract('css!sass') },
    ],
  },

  plugins: [
    new Clean(['.tmp']),
    new ExtractTextPlugin('assets/stylesheets/all.css', {
      allChunks: true,
    }),
  ],
};
