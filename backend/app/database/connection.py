import os
from typing import Optional
from pathlib import Path
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

# Cargar .env desde el directorio de backend o fallback al directorio de trabajo actual
BASE_DIR = Path(__file__).resolve().parent.parent.parent
load_dotenv(dotenv_path=BASE_DIR / ".env")
load_dotenv()

MONGO_URI: str = os.getenv("MONGO_URI")
DB_NAME: str = os.getenv("DB_NAME")

import asyncio

client: Optional[AsyncIOMotorClient] = None


def get_mongo_client() -> AsyncIOMotorClient:
    """
    Obtiene o inicializa el cliente asíncrono de MongoDB (Motor).
    Mantiene una única instancia por bucle de eventos y recrea si el loop se cerró.
    """
    global client
    try:
        current_loop = asyncio.get_running_loop()
    except RuntimeError:
        current_loop = None

    needs_new = False
    if client is None:
        needs_new = True
    else:
        try:
            client_loop = client.get_io_loop()
            if client_loop is None or client_loop.is_closed() or (current_loop and client_loop != current_loop):
                needs_new = True
        except Exception:
            needs_new = True

    if needs_new:
        client = AsyncIOMotorClient(
            MONGO_URI,
            serverSelectionTimeoutMS=5000,
            # Devuelve fechas con zona horaria (UTC) para que el JSON incluya el offset
            # y los clientes (app móvil) puedan convertirlas a hora local correctamente.
            tz_aware=True,
        )
    return client


def get_database() -> AsyncIOMotorDatabase:
    """
    Retorna la instancia de la base de datos MongoDB configurada.
    """
    mongo_client = get_mongo_client()
    return mongo_client[DB_NAME]


async def get_db() -> AsyncIOMotorDatabase:
    """
    Inyección de dependencias para FastAPI que proporciona
    la base de datos asíncrona de MongoDB.
    """
    return get_database()


def close_mongo_connection() -> None:
    """
    Cierra la conexión del cliente MongoDB.
    """
    global client
    if client:
        client.close()
        client = None
