from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field, AliasChoices, model_validator
from app.database.base import MongoBaseModel, PyObjectId
from app.models.prediction import ResultadoAnalisis, AnalisisDermatologica


class ResultadoAnalisisSchema(BaseModel):
    """
    Resultados detallados arrojados por el modelo de IA.
    """
    clasificacion: str
    nivel_riesgo: str
    confianza: float
    arquitectura: str
    metrica: Optional[Dict[str, Any] | str] = None


class AnalisisDermatologicaSchema(BaseModel):
    """
    Estructura del análisis dermatológico en MongoDB.
    """
    imagen_dermatologica: Optional[str] = None
    clasificacion: str
    validacion_patologia: Optional[str] = None
    resultados: Optional[ResultadoAnalisisSchema] = None


class PredictionBase(BaseModel):
    usuario_id: str = Field(..., validation_alias=AliasChoices("usuario_id", "user_id"))
    zona_cuerpo: Optional[str] = Field(None, validation_alias=AliasChoices("zona_cuerpo", "body_part"))


class PredictionCreate(PredictionBase):
    imagen_movil: Optional[str] = None
    analisis_dermatologica: Optional[AnalisisDermatologicaSchema] = None


class PredictionResponse(MongoBaseModel):
    """
    Esquema de respuesta de predicción / lesión compatible con la colección 'lesiones'
    y con clientes que esperan campos planos.
    """
    usuario_id: str = Field(..., validation_alias=AliasChoices("usuario_id", "user_id"))
    fecha_captura: datetime = Field(default_factory=datetime.utcnow, validation_alias=AliasChoices("fecha_captura", "fecha", "date"))
    imagen_movil: str = Field(..., validation_alias=AliasChoices("imagen_movil", "url_imagen", "image_url"))
    zona_cuerpo: Optional[str] = Field(None, validation_alias=AliasChoices("zona_cuerpo", "body_part"))
    analisis_dermatologica: Optional[AnalisisDermatologicaSchema] = None

    # Campos de compatibilidad con clientes existentes
    classification: Optional[str] = None
    disease: Optional[str] = None
    confidence: Optional[float] = None
    image_url: Optional[str] = None

    @model_validator(mode="after")
    def populate_compatibility_fields(self):
        if not self.image_url:
            self.image_url = self.imagen_movil
        if self.analisis_dermatologica:
            if not self.classification:
                self.classification = self.analisis_dermatologica.clasificacion
            if not self.disease:
                self.disease = self.analisis_dermatologica.clasificacion
            if self.analisis_dermatologica.resultados and self.confidence is None:
                self.confidence = self.analisis_dermatologica.resultados.confianza
        return self


# Alias semánticos
LesionBase = PredictionBase
LesionCreate = PredictionCreate
LesionResponse = PredictionResponse