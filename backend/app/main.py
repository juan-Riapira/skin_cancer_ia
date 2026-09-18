from fastapi import FastAPI

from app.api.v1.endpoints import prediction
from app.api.user import router as usuarios_router

app = FastAPI(
    title="API Lesiones Cutáneas",
    version="1.0.0"
)


app.include_router(
    usuarios_router,
    prefix="/api"
)
app.include_router(prediction.router, prefix="/api/v1")


@app.get("/")
def inicio():
    return {
        "mensaje": "API de lesiones cutáneas funcionando"
    }