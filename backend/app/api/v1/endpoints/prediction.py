from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.prediction import PredictionResponse, PredictionCreate
from app.services.prediction_service import PredictionService

router = APIRouter(prefix="/predictions", tags=["Predictions"])

@router.post("/", response_model=PredictionResponse, status_code=status.HTTP_201_CREATED)
async def create_prediction(
    user_id: int = Form(...),
    body_part: str = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Uploaded file is not an image.")

    mock_image_url = f"https://s3.amazonaws.com/bucket-lesions/{file.filename}"
    
    mock_ai_result = {
        "classification": "Malignant",
        "disease": "Melanoma",
        "confidence": 0.94
    }

    input_data = PredictionCreate(user_id=user_id, body_part=body_part)
    
    result = await PredictionService.process_and_save(
        db=db,
        data=input_data,
        image_url=mock_image_url,
        ai_result=mock_ai_result
    )
    
    return result