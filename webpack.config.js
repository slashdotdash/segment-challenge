var webpack = require('webpack');
var path = require('path');
var ExtractTextPlugin = require('extract-text-webpack-plugin');
var CopyWebpackPlugin = require('copy-webpack-plugin');

var env = process.env.MIX_ENV || 'dev';
var isProduction = (env === 'prod');

var alias = {
  phoenix_html: path.resolve(__dirname + '/deps/phoenix_html/priv/static/phoenix_html.js'),
  phoenix: path.resolve(__dirname + '/deps/phoenix/priv/static/phoenix.js')
};

var plugins = [
  new ExtractTextPlugin('css/[name].css'),
  new CopyWebpackPlugin([{
      from: 'assets/static'
    },
    {
      from: 'assets/css/font-awesome/css/font-awesome.min.css',
      to: 'css/font-awesome.min.css'
    },
    {
      from: 'assets/css/font-awesome/fonts',
      to: 'fonts'
    },
    {
      from: alias.phoenix_html,
      to: 'js/phoenix_html.js'
    }
  ]),
  new webpack.optimize.CommonsChunkPlugin('app', 'js/app.js')
];

// This is necessary to get the sass @import's working
var stylePathResolves = (
  'includePaths[]=' + path.resolve('./') + '&' +
  'includePaths[]=' + path.resolve('./node_modules')
);

if (isProduction) {
  plugins.push(new webpack.optimize.UglifyJsPlugin({
    minimize: true
  }));
}

var loaders = [{
    test: /\.jsx?$/,
    exclude: /(node_modules|bower_components)/,
    loader: 'babel',
    query: {
      presets: ['es2015', 'react', 'stage-2']
    }
  },
  {
    test: /\.json$/,
    loader: 'json-loader'
  },
  {
    test: /\.scss$/,
    loader: ExtractTextPlugin.extract(
      'style',
      'css' + '!sass?outputStyle=expanded&' + stylePathResolves
    )
  },
  {
    test: /\.(jpe?g|png|gif|svg)$/i,
    loaders: [
      'file?hash=sha512&digest=hex&name=./css/[hash].[ext]&publicPath=../'
    ]
  }
];

module.exports = {
  entry: {
    app: [
      './assets/js/app.js',
      './assets/css/app.scss'
    ],
    email: [
      './assets/css/email.scss'
    ],
    map: [
      './assets/js/map.js',
    ],
    CreateChallenge: [
      './assets/js/createChallenge/index.js'
    ],
    CreateStage: [
      './assets/js/createStage/index.js'
    ],
    MarkdownEditor: [
      './assets/js/markdownEditor/index.js'
    ],
  },

  output: {
    path: './priv/static',
    filename: 'js/[name].js'
  },

  resolve: {
    alias: alias,
    extensions: ['', '.js', '.scss']
  },

  module: {
    loaders: loaders
  },

  plugins: plugins
};
