# Parses a HDF5 MSI image to the Quimbi format
import sys
import os
import pandas as pd
import numpy as np
from PIL import Image
import argparse

def execute(in_path, out_path):
  file = pd.HDFStore(in_path)
  key = file.keys()[0]
  data = file.get(key)

  coordinates = np.array(data.index.tolist())[:, 0:2]
  # Due to confusions in x and y in the current hdf5 format coordinates
  coordinates = np.array([(coord[1], coord[0]) for coord in coordinates]).astype(float).astype(int)
  minimum = coordinates.min(axis=0)
  maximum = coordinates.max(axis=0)
  dimensions = (maximum - minimum + 1)

  dataset_name = key.strip('/')
  # Dataset information
  with open(os.path.join(out_path, dataset_name) + ".txt", "w") as txt:
      # Dimension[1] / Dimension[0] also due to confusions in x and y in the current hdf5 format coordinates
      txt.write('{},data/{}/,.png,{},{},{}'.format(dataset_name, dataset_name, data.shape[1], dimensions[1], dimensions[0]) + "\n")
      # Preprocessing information
      txt.write('unknown\n')
      # Brightfield overlay information
      txt.write('TODO\n')

  global_max = data.max().max()
  global_min = data.min().min()

  chunk_size = 4
  current_channel_index = 0
  last_channel_index = data.shape[1]
  image = np.zeros((dimensions[0], dimensions[1], 4), dtype=np.float32)
  filename = []

  if not os.path.exists(os.path.join(out_path, dataset_name)):
      os.makedirs(os.path.join(out_path, dataset_name))

  for channel in data:
    image_channel_index = current_channel_index % chunk_size
    for coords, pixel in zip(coordinates, data[channel]):
        image[coords[0] - minimum[0], coords[1] - minimum[1], image_channel_index] = pixel

    current_channel_index += 1
    filename.append(str(channel))

    if image_channel_index == 3 or current_channel_index == last_channel_index:
        png_image = np.round((image - global_min) / global_max * 255)
        name = '{}/{}/{}.png'.format(out_path, dataset_name, '-'.join(filename))
        Image.fromarray(png_image.astype(np.uint8)).save(name)
        with open(os.path.join(out_path, dataset_name) + ".txt", "a") as txt:
          txt.write('-'.join(filename) + "\n")
        filename = []

  file.close()

if __name__ == '__main__':
  parser = argparse.ArgumentParser(description="Creation of necessary files (.txt and folder with .pngs) to start quimbi.")
  parser.add_argument("-d", "--datapath", action="store", dest="datapath", type=str, required=True, help="Path to HDF5 file.")
  parser.add_argument("-s", "--savepath", action='store', dest='savepath', type=str, required=True, help="Path to save the .txt and folder of .pngs.")
  args = parser.parse_args()
  in_path = args.datapath
  out_path = args.savepath
  if not os.path.isdir(os.path.dirname(out_path)):
    os.makedirs(os.path.dirname(out_path))
  execute(in_path, out_path)