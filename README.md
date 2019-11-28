QUIMBI
======

A quick exploration tool for multivariate bioimages. A reference if you use QUIMBI in your own work will be available soon.

## Data Creation
To create appropriate data files use `quimbi_h5_parser.py` within the pyscripts folder.

For convenience we provide an anaconda environment which can be created by `conda env create -f environment.yml` and activated with `conda activate quimbi`.

Use `python quimbi_h5_parser.py -h` for further information about how to use the script.

As the script needs the MSI data to be in HDF5 format we refer to our preprocessing pipeline [A Mad Pie](https://github.com/Kawue/amadpie/).

## Data Files
It's important to place your data files in a folder called `data` in quimbis root directory: `quimbi/data`

## Local Version
### Installation
To run the project you need `node` and `npm`. To get access to both download node.js from https://nodejs.org/en/download/ and install the correct version for your OS. Afterwards, clone this repository, use your command shell to navigate into the repository and run `npm install` and then `npm run build` to build the project.
The bundled project is saved into the `dist` folder.

### Usage
#### Development
To start developing enter `npm run start:dev`. This starts a node based webpack development server at `localhost:8080` with live reload. Note: if you make 
changes to static files like the index.html or you edit the webpack config file, you need to
restart the server to see changes.
#### Production
To start the tool for production, go to the  `dist/index.html`. In this folder you have to start a webserver for example 
the build-in from php with `php -S localhost:8000`. You can then access the app in your browser
with the url `http://localhost:8000`

## Docker Version
To create a docker version of quimbi several prerequirements have to be fulfilled.
	1. docker must be installed
	2. the docker.service should be running 
### Build
To build the docker image you simply run `docker build -t $IMAGE_NAME .` in the root folder of the quimbi project.
If you want to change anything inside quimbi you have to rerun the build and run process.

### Run
To run the docker image enter `docker run -it -p $PORT:80 --rm --name $CONTAINER_NAME $IMAGE_NAME`. Afterwards quimbi is available
at `http://localhost:$PORT`.

### Example
The following lines will create a docker image of quimbi named quimbi_image and create/run a container of said image called quimbi_image1  
`docker build -t quimbi_image .`
`docker run -it -p 8080:80 --rm --name quimbi_image1 quimbi_image`

## Live Demo
A Github Pages live demo can be used at https://biodatamininggroup.github.io/quimbi/.

