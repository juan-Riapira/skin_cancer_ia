from datetime import datetime
from typing import Optional, Any, Dict
from pydantic import BaseModel, Field
from app.database.base import MongoBaseModel, PyObjectId


class ResultadoAnalisis(BaseModel):
    """
    Subdocumento que contiene los resultados detallados de la inferencia del modelo de IA.
    """
    clasificacion: str
    nivel_riesgo: str
    confianza: float
    arquitectura: str
    metrica: Optional[Dict[str, Any] | str] = None


class AnalisisDermatologica(BaseModel):
    """
    Subdocumento que agrupa el análisis dermatológico y validación médica/patológica.
    """
    imagen_dermatologica: Optional[str] = None
    clasificacion: str
    validacion_patologia: Optional[str] = None
    resultados: Optional[ResultadoAnalisis] = None


class LesionModel(MongoBaseModel):
    """
    Modelo de documento para la colección 'lesiones' en MongoDB.
    """
    usuario_id: str
    fecha_captura: datetime = Field(default_factory=datetime.utcnow)
    imagen_movil: str
    zona_cuerpo: Optional[str] = None
    analisis_dermatologica: Optional[AnalisisDermatologica] = None


# Alias para mantener compatibilidad con imports existentes
PredictionModel = LesionModel
Lesion = LesionModel