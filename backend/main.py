import numpy as np
import h5py
from math import ceil
from fastapi import FastAPI, Response


class RegionHandler:
    H5_FILE = "regions.h5"
    NPZ_FILE = "../data/20180406_AF_DHB_RP_hum_Skin_PXE_116_3_neu_autopicked.npz"

    def __init__(self):
        self.num_regions = 0
        self.load_regions()

    def load_regions(self):
        dataset = np.load(self.NPZ_FILE)
        data = dataset["data"]
        global_max = data.max()
        global_min = data.min()

        regionHeight = data.shape[0]
        regionWidth = data.shape[1]
        regionSizeUpperLimit = 1000

        while regionWidth * regionHeight > regionSizeUpperLimit:
            regionWidth /= 2
            regionHeight /= 2

        regionWidth = ceil(regionWidth)
        regionHeight = ceil(regionHeight)

        with h5py.File(self.H5_FILE, "w") as h5f:
            i = 0
            for y in range(0, data.shape[0], regionHeight):
                for x in range(0, data.shape[1], regionWidth):
                    region = data[y:y + regionHeight, x:x + regionWidth, :]
                    region = (region - global_min) / (global_max - global_min)
                    h5f.create_dataset(
                        f"region_{i}",
                        data=region,
                        compression="gzip"
                    )
                    i += 1
            self.num_regions = i

    def get_region(self, index):
        if index < 0 or index >= self.num_regions:
            return None

        with h5py.File(self.H5_FILE, "r") as h5f:
            return h5f[f"region_{index}"][:]


class ChannelImageHandler:
    NPZ_FILE = "../data/20180406_AF_DHB_RP_hum_Skin_PXE_116_3_neu_autopicked.npz"

    def __init__(self):
        with np.load(self.NPZ_FILE) as npz_file:
            self.data = npz_file['data']
            self.channels = npz_file['channels'].tolist()

    def get_channel_image(self, index):
        if index < 0 or index >= self.data.shape[2]:
            return None

        # Select m/z-channel
        data = self.data[:, :, index]

        # Normalize intensities to [0, 255]
        uint8_max = np.iinfo(np.uint8).max
        max_val = data.reshape(-1).max()
        min_val = data.reshape(-1).min()
        data = np.round((data - min_val) / (max_val - min_val) * uint8_max).astype(np.uint8)

        # Fill all color channels (RGBA) with same image
        data = data.ravel()
        data = np.repeat(data, 4)

        return data


regionHandler = RegionHandler()
channelImageHandler = ChannelImageHandler()
app = FastAPI()


@app.get("/spectrum")
def get_spectrum(index: int):
    region = regionHandler.get_region(index)
    if region is None:
         return Response(status_code=404)

    return Response(
        content=region.tobytes(),
        media_type="application/octet-stream",
    )


@app.get("/channel")
def get_channel(index: float):
    image = channelImageHandler.get_channel_image(int(index))
    if image is None:
        return Response(status_code=404)

    return Response(
        content=image.tobytes(),
        media_type="application/octet-stream",
    )

