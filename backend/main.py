import numpy as np
from fastapi import FastAPI
from fastapi.responses import Response

app = FastAPI()

@app.get("/spectrum")
def get_spectrum(index: int, width: int, height: int):
    DEPTH = 430
    DATA = np.random.rand(height, width, DEPTH).astype(np.float32)

    return Response(
        content=DATA.tobytes(),
        media_type="application/octet-stream",
    )
