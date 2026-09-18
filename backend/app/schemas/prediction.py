from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class PredictionBase(BaseModel):
    user_id: int
    body_part: Optional[str] = None

class PredictionCreate(PredictionBase):
    pass

class PredictionResponse(PredictionBase):
    id_prediccion: int
    classification: str
    disease: str
    confidence: float
    date: datetime
    image_url: str

    class Config:
        from_attributes = True