quimbi
======

Quick exploration tool for multivariate bioimages

## Installation

To run the project you need `node` and `npm` . Clone this repository, run `npm install` and then `npm run build` to build the project.
The bundled project is saved into the `dist` folder.

## Usage
### Development
To start developing enter `npm run start:dev`. This starts a node based webpack development server at `localhost:8080` with live reload. Note: if you make 
changes to static files like the index.html or you edit the webpack config file, you need to
restart the server to see changes.
### Production
To start the tool for production, go to the  `dist/index.html`. In this folder you have to start a webserver for example 
the build-in from php with `php -S localhost:8000`. You can then access the app in your browser
with the url `http://localhost:8000`

## Data files
It's important to place your data files in a folder called `data` in quimbis root directory: `quimbi/data`
