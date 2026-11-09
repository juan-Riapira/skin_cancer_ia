from typing import Optional
from pydantic import BaseModel, Field, field_validator
from app.database.base import MongoBaseModel, PyObjectId


class ZonaResidencialSchema(BaseModel):
    """
    Esquema para la zona residencial del usuario.
    """
    departamento: str
    municipio: str
    vereda: Optional[str] = None


class UsuarioBase(BaseModel):
    nombre: str
    edad: Optional[int] = None
    genero: Optional[str] = None
    zona_residencial: Optional[ZonaResidencialSchema] = None


class UsuarioCreate(UsuarioBase):
    """
    Esquema para creación de un nuevo usuario.
    Permite id_ubicacion opcional por compatibilidad con versiones cliente previas.
    """
    nombre: str = Field(..., min_length=1, max_length=100)
    edad: Optional[int] = Field(None, ge=0, le=120)
    id_ubicacion: Optional[int] = None

    @field_validator("nombre")
    @classmethod
    def nombre_sin_espacios(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("El nombre no puede estar vacío")
        return v


class UsuarioUpdate(BaseModel):
    """
    Esquema para actualización de usuario.
    """
    nombre: Optional[str] = None
    edad: Optional[int] = None
    genero: Optional[str] = None
    zona_residencial: Optional[ZonaResidencialSchema] = None


class UsuarioResponse(MongoBaseModel, UsuarioBase):
    """
    Esquema de respuesta para usuarios.
    Convierte el _id de MongoDB en id accesible en formato string.
    """
    pass