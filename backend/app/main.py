from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.endpoints import prediction, user
from app.database.connection import close_mongo_connection, get_database


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: el cliente de MongoDB se inicializa de forma diferida (lazy) o en la primera petición
    yield
    # Shutdown: cerrar pools de conexión a MongoDB
    close_mongo_connection()


app = FastAPI(
    title="API Lesiones Cutáneas & Detección IA",
    version="1.0.0",
    lifespan=lifespan
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

# Rutas v1 (NoSQL MongoDB Atlas)
app.include_router(user.router, prefix="/api/v1")
app.include_router(prediction.router, prefix="/api/v1")

@app.get("/")
def inicio():
    return {
        "mensaje": "API de detección de lesiones cutáneas funcionando con MongoDB Atlas",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health")
async def health_check():
    """
    Verifica el estado del servicio y la conectividad básica con MongoDB.
    """
    try:
        db = get_database()
        # Ping a MongoDB Atlas
        await db.command("ping")
        mongo_status = "connected"
    except Exception as e:
        mongo_status = f"unreachable: {str(e)}"

    return {
        "status": "healthy" if mongo_status == "connected" else "degraded",
        "database": mongo_status
    }