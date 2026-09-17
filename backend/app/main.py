from fastapi import FastAPI

from app.api.user import router as usuarios_router


app = FastAPI(
    title="API Lesiones Cutáneas",
    version="1.0.0"
)


app.include_router(
    usuarios_router,
    prefix="/api"
)


@app.get("/")
def inicio():
    return {
        "mensaje": "API de lesiones cutáneas funcionando"
    }