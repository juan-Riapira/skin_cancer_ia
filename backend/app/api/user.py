from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.schemas.user import UsuarioCreate
from app.services.user_service import crear_usuario


router = APIRouter()


@router.post("/usuarios")
def registrar_usuario(
    usuario: UsuarioCreate,
    db: Session = Depends(get_db)
):
    return crear_usuario(db, usuario)