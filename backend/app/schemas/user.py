from pydantic import BaseModel


class UsuarioCreate(BaseModel):
    nombre: str
    edad: int | None = None
    genero: str | None = None
    id_ubicacion: int | None = None