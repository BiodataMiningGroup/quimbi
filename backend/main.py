import numpy as np
from math import floor, ceil
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.responses import Response

regions = []

def load_regions(npz_file):
    global regions

    dataset = np.load(npz_file)
    data = dataset["data"]
    global_max = data.reshape(-1).max()
    global_min = data.reshape(-1).min()

    regionHeight = data.shape[0]
    regionWidth = data.shape[1]
    regionSizeUpperLimit = 1000
    while regionWidth * regionHeight > regionSizeUpperLimit:
        regionWidth = regionWidth / 2
        regionHeight = regionHeight / 2
    regionWidth = ceil(regionWidth)
    regionHeight = ceil(regionHeight)

    for y in range(0, data.shape[0], regionHeight):
        for x in range(0, data.shape[1], regionWidth):
            region = data[y:y+regionHeight, x:x+regionWidth, :]
            region = (region - global_min) / (global_max - global_min)
            regions.append(region)


@asynccontextmanager
async def lifespan(app: FastAPI):
    load_regions("../data/20180406_AF_DHB_RP_hum_Skin_PXE_116_3_neu_autopicked.npz")
    yield
    app.state.my_service.close()


app = FastAPI(lifespan=lifespan)


@app.get("/spectrum")
def get_spectrum(index: int):
    return Response(
        content=regions[index].tobytes(),
        media_type="application/octet-stream",
    )
