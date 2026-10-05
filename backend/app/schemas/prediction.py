from datetime import datetime, timezone
from typing import Optional
from pydantic import BaseModel, Field, AliasChoices, field_validator, model_validator
from app.database.base import MongoBaseModel
from app.models.prediction import ResultadoAnalisis, AnalisisDermatologica

# Mismos nombres de antes para no romper imports
ResultadoAnalisisSchema = ResultadoAnalisis
AnalisisDermatologicaSchema = AnalisisDermatologica


class PredictionBase(BaseModel):
    usuario_id: str = Field(..., validation_alias=AliasChoices("usuario_id", "user_id"))
    zona_cuerpo: Optional[str] = Field(None, validation_alias=AliasChoices("zona_cuerpo", "body_part"))


class PredictionCreate(PredictionBase):
    imagen_movil: Optional[str] = None
    analisis_dermatologica: Optional[AnalisisDermatologicaSchema] = None


class PredictionResponse(MongoBaseModel):
    usuario_id: str = Field(..., validation_alias=AliasChoices("usuario_id", "user_id"))
    fecha_captura: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        validation_alias=AliasChoices("fecha_captura", "fecha", "date"),
    )
    imagen_movil: str = Field(..., validation_alias=AliasChoices("imagen_movil", "url_imagen", "image_url"))
    zona_cuerpo: Optional[str] = Field(None, validation_alias=AliasChoices("zona_cuerpo", "body_part"))
    analisis_dermatologica: Optional[AnalisisDermatologicaSchema] = None

    # Compatibilidad con clientes existentes
    classification: Optional[str] = None
    disease: Optional[str] = None
    confidence: Optional[float] = None
    image_url: Optional[str] = None

    @field_validator("usuario_id", mode="before")
    @classmethod
    def usuario_id_a_str(cls, v):
        return str(v)  # viene como ObjectId desde Mongo

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


LesionBase = PredictionBase
LesionCreate = PredictionCreate
LesionResponse = PredictionResponse