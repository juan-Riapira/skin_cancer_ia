from datetime import datetime, timezone
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field
from app.database.base import MongoBaseModel


class ResultadoAnalisis(BaseModel):
    clasificacion: str
    nivel_riesgo: str
    confianza: float
    arquitectura: str
    metrica: Optional[Dict[str, Any]] = None


class AnalisisDermatologica(BaseModel):
    imagen_dermatologica: Optional[str] = None
    clasificacion: str
    validacion_patologia: bool = False
    resultados: Optional[ResultadoAnalisis] = None


class LesionModel(MongoBaseModel):
    """Documento de la colección 'lesiones' (usuario_id se guarda como ObjectId)."""
    usuario_id: str
    fecha_captura: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    imagen_movil: str
    zona_cuerpo: Optional[str] = None
    analisis_dermatologica: Optional[AnalisisDermatologica] = None


PredictionModel = LesionModel
Lesion = LesionModel