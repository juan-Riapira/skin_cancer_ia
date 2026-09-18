from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.user import router as usuarios_router

app = FastAPI(
    title="API Lesiones Cutáneas",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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