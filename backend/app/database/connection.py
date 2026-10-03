import os
from typing import Optional
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

load_dotenv()

MONGO_URI: str = os.getenv("MONGO_URI")
DB_NAME: str = os.getenv("DB_NAME")

client: Optional[AsyncIOMotorClient] = None


def get_mongo_client() -> AsyncIOMotorClient:
    """
    Obtiene o inicializa el cliente asíncrono de MongoDB (Motor).
    Mantiene una única instancia para reutilizar el pool de conexiones.
    """
    global client
    if client is None:
        client = AsyncIOMotorClient(
            MONGO_URI,
            serverSelectionTimeoutMS=5000
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
