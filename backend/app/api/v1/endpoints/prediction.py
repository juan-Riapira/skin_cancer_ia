import os
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.schemas.prediction import PredictionResponse, PredictionCreate
from app.services.prediction_service import PredictionService
from app.services.s3_service import S3Service

router = APIRouter(prefix="/predictions", tags=["Predictions"])

@router.post("/", response_model=PredictionResponse, status_code=status.HTTP_201_CREATED)
async def create_prediction(
    user_id: int = Form(...),
    body_part: str = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Uploaded file is not an image."
        )

    # 1. Subida real a AWS S3
    image_url = await S3Service.upload_image(file)

    # 2. Inferencia de la IA (Mock parametrizado desde .env)
    mock_ai_result = {
        "classification": os.getenv("DEFAULT_AI_CLASSIFICATION", "Malignant"),
        "disease": os.getenv("DEFAULT_AI_DISEASE", "Melanoma"),
        "confidence": float(os.getenv("DEFAULT_AI_CONFIDENCE", 0.94))
    }

    # 3. Guardar en Base de Datos RDS
    input_data = PredictionCreate(user_id=user_id, body_part=body_part)
    
    result = await PredictionService.process_and_save(
        db=db,
        data=input_data,
        image_url=image_url,
        ai_result=mock_ai_result
    )
    
    return result