# QUIMBI 2.0

Quick Exploration Tool for Multivariate Bioimages (QUIMBI) is a web application that allows you to visualize and explore mass spectrometry images interactively in the browser.

## Generating a Dataset

The script to generate a QUIMBI dataset ZIP file from an H5 file can be found in [`scripts/zip-creator`](scripts/zip-creator). Usage:

1. Install the requirements: `pip3 install -r scripts/zip-creator/requirements.txt`

2. Convert the MSI image to a H5 file

3. Execute the script: `python3 scripts/zip-creator/dataset-zip-creator.py <file>`

The script supports the following options:

- `-n`, `--name`: Optional dataset name. Default is the filename of the NumPy file.
- `-p`, `--precision`: Dataset numeric precision in bits (`8`, `16` or `32`). Default is `8`.
- `-o`, `--overlay`: Optional path to a bright field image. If supplied, the image is displayed in QUIMBI and can be blended with the heat map visualization.

## Installation

Clone this repository.

### Developing

1. Run `npm install`
2. Run `npm run dev`
3. Open the URL shown in the terminal

### Production

1. Run `npm install`
2. Update `base` in `vite.config.js`. If you are deploying to `https://example.com/<DIR>/`, then set base to `'/<DIR>/'`. If you are not deploying to a subdirectory, then set base to `'/'`.
3. Run `npm run build`
4. Expose the contents of the `dist` directory to a web server.
