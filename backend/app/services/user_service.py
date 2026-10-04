from typing import List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.schemas.user import UsuarioCreate, UsuarioUpdate


async def crear_usuario(
    db: AsyncIOMotorDatabase,
    usuario: UsuarioCreate
) -> dict:
    """
    Inserta un nuevo documento en la colección 'usuarios' de MongoDB.
    """
    data = usuario.model_dump(exclude_unset=True)
    # Extraer id_ubicacion si existía para mantener compatibilidad
    id_ubicacion = data.pop("id_ubicacion", None)

    # Si no se especificó zona_residencial explícita pero hay id_ubicacion o se requiere por esquema
    if "zona_residencial" not in data or data["zona_residencial"] is None:
        data["zona_residencial"] = {
            "departamento": "Boyacá",
            "municipio": "Tunja",
            "vereda": None
        }

    resultado = await db["usuarios"].insert_one(data)
    data["_id"] = resultado.inserted_id
    return data


async def obtener_usuario(
    db: AsyncIOMotorDatabase,
    usuario_id: str
) -> Optional[dict]:
    """
    Busca un usuario por su identificador (_id en ObjectId o string).
    """
    filtro = {}
    try:
        filtro = {"_id": ObjectId(usuario_id)}
    except Exception:
        filtro = {"_id": usuario_id}

    return await db["usuarios"].find_one(filtro)


async def listar_usuarios(
    db: AsyncIOMotorDatabase,
    skip: int = 0,
    limit: int = 100
) -> List[dict]:
    """
    Lista usuarios con paginación asíncrona usando Motor.
    """
    cursor = db["usuarios"].find().skip(skip).limit(limit)
    return await cursor.to_list(length=limit)