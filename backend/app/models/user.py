from typing import Optional
from pydantic import BaseModel, Field
from app.database.base import MongoBaseModel, PyObjectId


class ZonaResidencial(BaseModel):
    """
    Subdocumento que representa la ubicación geográfica del usuario.
    """
    departamento: str
    municipio: str
    vereda: Optional[str] = None


class UsuarioModel(MongoBaseModel):
    """
    Modelo de documento para la colección 'usuarios' en MongoDB.
    """
    nombre: str
    edad: Optional[int] = None
    genero: Optional[str] = None
    zona_residencial: Optional[ZonaResidencial] = None


# Alias para mantener compatibilidad con código existente
Usuario = UsuarioModel