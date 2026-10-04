from sqlalchemy.orm import Session
from app.models.prediction import PredictionModel
from app.schemas.prediction import PredictionCreate

class PredictionService:
    
    @staticmethod
    async def process_and_save(
        db: Session, 
        data: PredictionCreate, 
        image_url: str, 
        ai_result: dict
    ):
        new_prediction = PredictionModel(
            id_usuario=data.user_id,
            clasificacion=ai_result["classification"],
            enfermedad=ai_result["disease"],
            confianza=ai_result["confidence"],
            zona_cuerpo=data.body_part,
            url_imagen=image_url
        )
        
        db.add(new_prediction)
        db.commit()
        db.refresh(new_prediction)
        
        return new_prediction