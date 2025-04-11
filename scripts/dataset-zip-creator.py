import os
import numpy as np
from PIL import Image
import argparse
import json
from zipfile import ZipFile
import io

class ZipCreator(object):
    def __init__(self, file, name='', precision=8, overlay=None):
        self.file = os.path.abspath(file)
        self.out_file = '{}.{}.zip'.format(self.file, precision)
        self.name = os.path.basename(file) if name == '' else name
        self.precision = precision
        self.overlay = overlay

    def create8_(self, data, zip_file, metadata):
        uint8_max = np.iinfo(np.uint8).max
        global_max = data.reshape(-1).max()
        global_min = data.reshape(-1).min()

        # Add missing feature channels to make shape[2] divisible by 4.
        if data.shape[2] % 4 != 0:
            zeros = np.zeros((data.shape[0], data.shape[1], 4 - (data.shape[2] % 4)))
            data = np.concatenate((data, zeros), axis=2)

        splits = np.split(data, data.shape[2] // 4, axis=2)
        for i, split in enumerate(splits):
            split = np.round((split - global_min) / (global_max - global_min) * uint8_max).astype(np.uint8)
            filename = '{}.png'.format(i)
            bytes_io = io.BytesIO()
            Image.fromarray(split).save(bytes_io, format='png')
            zip_file.writestr(filename, bytes_io.getvalue())

    def create16_(self, data, zip_file, metadata):
        uint16_max = np.iinfo(np.uint16).max
        global_max = data.reshape(-1).max()
        global_min = data.reshape(-1).min()

        # Add missing feature channels to make shape[2] divisible by 2.
        if data.shape[2] % 2 != 0:
            zeros = np.zeros((data.shape[0], data.shape[1], 2 - (data.shape[2] % 2)))
            data = np.concatenate((data, zeros), axis=2)

        splits = np.split(data, data.shape[2] // 2, axis=2)
        for i, split in enumerate(splits):
            split = np.round((split - global_min) / (global_max - global_min) * uint16_max).astype(np.uint16)
            # Convert 2x uint16 to 4x uint8
            split = np.frombuffer(split.tobytes(), dtype=np.uint8).reshape(data.shape[0], data.shape[1], 4)
            filename = '{}.png'.format(i)
            bytes_io = io.BytesIO()
            Image.fromarray(split).save(bytes_io, format='png')
            zip_file.writestr(filename, bytes_io.getvalue())

    def create32_(self, data, zip_file, metadata):
        uint32_max = np.iinfo(np.uint32).max
        global_max = data.reshape(-1).max()
        global_min = data.reshape(-1).min()

        for i in range(data.shape[2]):
            split = np.round((data[:, :, i] - global_min) / (global_max - global_min) * uint32_max).astype(np.uint32)
            # Convert 1x uint32 to 4x uint8
            split = np.frombuffer(split.tobytes(), dtype=np.uint8).reshape(data.shape[0], data.shape[1], 4)
            filename = '{}.png'.format(i)
            bytes_io = io.BytesIO()
            Image.fromarray(split).save(bytes_io, format='png')
            zip_file.writestr(filename, bytes_io.getvalue())

    def create(self):
        with np.load(self.file) as npz_file:
            data = npz_file['data']
            channels = npz_file['channels'].tolist()

        if data.ndim != 3:
            raise ValueError('The input data has an unexpected number of dimensions ({} given, 3 expected).'.format(data.ndim))

        if data.shape[2] != len(channels):
            raise ValueError('Dataset depth {} does not match channel count {}.'.format(data.shape[2], len(channels)))

        zip_file = ZipFile(self.out_file, 'w')
        has_overlay = self.overlay != None

        metadata = {
            'name': self.name,
            'width': data.shape[1],
            'height': data.shape[0],
            'precision': self.precision,
            'overlay': has_overlay,
            'channels': channels,
        }

        if has_overlay:
            bytes_io = io.BytesIO()
            Image.open(self.overlay).save(bytes_io, format='jpeg', quality=85)
            zip_file.writestr('overlay.jpg', bytes_io.getvalue())

        if self.precision == 32:
            self.create32_(data, zip_file, metadata)
        elif self.precision == 16:
            self.create16_(data, zip_file, metadata)
        else:
            self.create8_(data, zip_file, metadata)

        zip_file.writestr('metadata.json', json.dumps(metadata))
        zip_file.close()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Create a QUIMBI ZIP from an NPZ or NPY file")
    parser.add_argument('file', type=str, help='path to the npz/npy file')
    parser.add_argument("-n", "--name", dest='name', type=str, default='', help="optional dataset name")
    parser.add_argument('-p', '--precision', dest='precision', choices=[8, 16, 32], default=8, type=int, help='bit precision to store the dataset in (default: 8)')
    parser.add_argument('-o', '--overlay', type=str, help='optional path to the overlay image')
    args = vars(parser.parse_args())

    creator = ZipCreator(**args)
    creator.create()
