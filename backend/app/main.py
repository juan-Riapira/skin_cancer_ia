import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.v1.endpoints import prediction, user
from app.database.connection import close_mongo_connection, get_database
from app.services.storage_service import ensure_bucket, get_client, _bucket, LOCAL_UPLOAD_DIR

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Asegura que el bucket de MinIO en Docker exista y tenga políticas públicas
    try:
        await ensure_bucket()
    except Exception as e:
        logger.warning("Aviso durante inicio de MinIO: %s", e)
    yield
    # Cierre ordenado de conexiones
    close_mongo_connection()


app = FastAPI(
    title="API Lesiones Cutáneas & Detección IA",
    description="API RESTful para el diagnóstico de lesiones dermatológicas con almacenamiento en MinIO (Docker) y MongoDB Atlas.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Imágenes guardadas localmente cuando MinIO no está disponible (respaldo)
LOCAL_UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=LOCAL_UPLOAD_DIR), name="uploads")

# Rutas v1 (MongoDB Atlas + MinIO)
app.include_router(user.router, prefix="/api/v1")
app.include_router(prediction.router, prefix="/api/v1")


@app.get("/", tags=["General"])
def inicio():
    return {
        "mensaje": "API de detección de lesiones cutáneas funcionando con MongoDB Atlas y MinIO",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health", tags=["General"])
async def health_check():
    """
    Verifica el estado del servicio, conectividad con MongoDB Atlas y MinIO (Docker).
    """
    # 1. Chequeo de MongoDB Atlas
    try:
        db = get_database()
        await db.command("ping")
        mongo_status = "connected"
    except Exception as e:
        mongo_status = f"unreachable: {str(e)}"

    # 2. Chequeo de MinIO (Docker)
    try:
        client = get_client()
        client.head_bucket(Bucket=_bucket())
        storage_status = "connected"
    except Exception as e:
        storage_status = f"unreachable: {str(e)}"

    is_healthy = mongo_status == "connected" and storage_status == "connected"

    return {
        "status": "healthy" if is_healthy else "degraded",
        "database_mongo": mongo_status,
        "storage_minio": storage_status,
    }