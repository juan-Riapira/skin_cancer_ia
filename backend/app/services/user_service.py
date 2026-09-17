from sqlalchemy.orm import Session

from app.models.user import Usuario
from app.schemas.user import UsuarioCreate


def crear_usuario(
    db: Session,
    usuario: UsuarioCreate
):

    nuevo_usuario = Usuario(
        nombre=usuario.nombre,
        edad=usuario.edad,
        genero=usuario.genero,
        id_ubicacion=usuario.id_ubicacion
    )

    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)

    return nuevo_usuario