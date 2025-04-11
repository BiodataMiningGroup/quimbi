# Parses a HDF5 MSI image to the Quimbi NumPy format
import os

import numpy as np
import argparse
import pandas as pd

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

  image = np.zeros((dimensions[0], dimensions[1], data.shape[1]), dtype=np.float32)

  for index, row in data.iterrows():
    values = row.values
    if values.ndim != 1:
      continue
    image[index[1] - minimum[0], index[0] - minimum[1]] = values

  np.savez(out_path, data=image, channels=data.columns.values.astype(str))

  file.close()

if __name__ == '__main__':
  parser = argparse.ArgumentParser(description="Convert a ProVim h5 to npy.")
  parser.add_argument("in_path", type=str, help="Path to HDF5 file.")
  parser.add_argument("out_path", type=str, help="Path to save the npy file.")
  args = parser.parse_args()
  execute(args.in_path, args.out_path)
