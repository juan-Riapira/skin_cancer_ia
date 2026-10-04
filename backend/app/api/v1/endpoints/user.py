from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database.connection import get_db
from app.schemas.user import UsuarioCreate, UsuarioResponse
from app.services.user_service import crear_usuario, obtener_usuario, listar_usuarios

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])


@router.post(
    "",
    response_model=UsuarioResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar un nuevo usuario"
)
@router.post(
    "/",
    response_model=UsuarioResponse,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False
)
async def registrar_usuario_endpoint(
    usuario: UsuarioCreate,
    db: AsyncIOMotorDatabase = Depends(get_db)
):
    """
    Registra un usuario en la colección 'usuarios' de MongoDB Atlas.
    """
    nuevo_usuario = await crear_usuario(db, usuario)
    return nuevo_usuario


@router.get(
    "",
    response_model=List[UsuarioResponse],
    summary="Listar todos los usuarios"
)
@router.get(
    "/",
    response_model=List[UsuarioResponse],
    include_in_schema=False
)
async def listar_usuarios_endpoint(
    skip: int = 0,
    limit: int = 100,
    db: AsyncIOMotorDatabase = Depends(get_db)
):
    """
    Retorna la lista de usuarios almacenados en MongoDB.
    """
    return await listar_usuarios(db, skip=skip, limit=limit)


@router.get(
    "/{usuario_id}",
    response_model=UsuarioResponse,
    summary="Obtener usuario por ID"
)
async def obtener_usuario_endpoint(
    usuario_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db)
):
    """
    Obtiene los datos de un usuario mediante su ObjectId o identificador.
    """
    usuario = await obtener_usuario(db, usuario_id)
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )
    return usuario
