QUIMBI
======

A quick exploration tool for multivariate bioimages. A reference if you use QUIMBI in your own work will be available soon.

## Data Creation
To create appropriate data files navigate into the quimbi/pyscripts directory and call:
`docker build -t quimbi/dataparser .`
`docker run -v path-to-data:/data --rm quimbi/dataparser`
For information about the required command line parameter use `-h`.

The script needs the MSI data to be in HDF5 format.
In case of raw data we refer to our preprocessing pipeline [ProViM](https://github.com/Kawue/provim).
In case of processed data we refer to our parser [imzML-to-HDF5-Parser](https://github.com/Kawue/imzML-to-HDF5).

## Data Files
It's important to place your data files in a folder called `data` in quimbis root directory: `quimbi/data`

## Docker Version
To create a docker version of quimbi several prerequirements have to be fulfilled.
	1. docker must be installed
	2. the docker.service (Docker Desktop) should be running

Docker is not compatible with Windows 7, 8 and 10 Home. For details about a workaround see instructions below.

### Build
To build the docker image you simply run `docker build -t $IMAGE_NAME .` in the root folder of the quimbi project.
If you want to change anything inside quimbi you have to rerun the build and run process.

### Run
To run the docker image enter `docker run -v $(pwd)/data:/usr/share/nginx/html/data -p $PORT:80 --rm --name $CONTAINER_NAME $IMAGE_NAME`. Afterwards quimbi is available
at `http://localhost:$PORT`.

### Example
The following lines will create a docker image of quimbi named quimbi_image and creates and runs a container of said image called quimbi_container  
`docker build -t quimbi_image .`

Powershell
`docker run -p 8080:80 -v  ${PWD}/data:/usr/share/nginx/html/data --rm --name quimbi_container quimbi_image`
CMD
`docker run -p 8080:80 -v  %cd%/data::/usr/share/nginx/html/data --rm --name quimbi_container quimbi_image`
Linux
`docker run -p 8080:80 -v  $(pwd)/data:/usr/share/nginx/html/data --rm --name quimbi_container quimbi_image`

Quimbi is now available at: `localhost:8080`

To stop docker:
Press CTRL+C and call `docker stop quimbi_container`


## Local Version (without Docker)
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


## Live Demo
A Github Pages live demo can be used at https://biodatamininggroup.github.io/quimbi/.


## Docker on Windows 7, 8 and 10 Home
1. Visit https://docs.docker.com/toolbox/toolbox_install_windows/. Follow the given instructions and install all required software to install the Docker Toolbox on Windows.
2. Control if virtualization is enabled on your system. Task Manager -> Performance tab -> CPU -> Virtualization. If it is enabled continue with Step X.
3. If virtualization is disabled, it needs to be enabled in your BIOS. Navigate into your systems BIOS and look for Virtualization Technology (VT). Enable VT, save settings and reboot. This option is most likely part of the Advanced or Security tab. This step can deviate based on your Windows and Mainboard Manufacturer.
4. Open your CMD as administrator and call `docker-machine create default --virtualbox-no-vtx-check`. A restart may be required.
5. In your OracleVM VirtualBox selected the appropriate machine (probably the one labeled "default") -> Settings -> Network -> Adapter 1 -> Advanced -> Port Forwarding. Click on "+" to add a new rule and set Host Port to 8080 and Guest Port to 8080. Be sure to leave Host IP and Guest IP empty. Also, add another rule for the Port 5000 in the same way. A restart of your VirtualBox may be needed.
6. Now you should be ready to use the Docker QuickStart Shell to call the Docker commands provided to start this tool.
