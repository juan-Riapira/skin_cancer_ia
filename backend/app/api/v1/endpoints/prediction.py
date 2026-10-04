import os
from typing import List, Optional
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database.connection import get_db
from app.schemas.prediction import PredictionResponse, PredictionCreate
from app.services.prediction_service import PredictionService
from app.services.s3_service import S3Service

router = APIRouter(prefix="/predictions", tags=["Predictions"])


@router.post(
    "",
    response_model=PredictionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar una nueva predicción y subir imagen a S3"
)
@router.post(
    "/",
    response_model=PredictionResponse,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False
)
async def create_prediction(
    user_id: str = Form(...),
    body_part: Optional[str] = Form(None),
    file: UploadFile = File(...),
    db: AsyncIOMotorDatabase = Depends(get_db)
):
    """
    1. Sube la imagen médica/móvil a AWS S3.
    2. Ejecuta la inferencia o procesa resultados de IA.
    3. Almacena la información dermatológica en la colección 'lesiones' de MongoDB.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="El archivo proporcionado no es una imagen válida."
        )

    # 1. Subida real a AWS S3
    image_url = await S3Service.upload_image(file)

    # 2. Inferencia de la IA parametrizada desde variables de entorno
    clasificacion_default = os.getenv("DEFAULT_AI_CLASSIFICATION", "Malignant")
    confianza_default = float(os.getenv("DEFAULT_AI_CONFIDENCE", 0.94))
    nivel_riesgo_default = os.getenv("DEFAULT_AI_RISK_LEVEL", "Alto")
    arquitectura_default = os.getenv("DEFAULT_AI_ARCHITECTURE", "EfficientNet-B0")

    mock_ai_result = {
        "clasificacion": clasificacion_default,
        "disease": os.getenv("DEFAULT_AI_DISEASE", clasificacion_default),
        "confianza": confianza_default,
        "nivel_riesgo": nivel_riesgo_default,
        "arquitectura": arquitectura_default,
        "metrica": {"accuracy": confianza_default},
        "validacion_patologia": "Pendiente de validación médica"
    }

    # 3. Guardar en MongoDB Atlas (Colección 'lesiones')
    input_data = PredictionCreate(usuario_id=user_id, zona_cuerpo=body_part)
    
    result = await PredictionService.process_and_save(
        db=db,
        data=input_data,
        image_url=image_url,
        ai_result=mock_ai_result
    )
    
    return result


@router.get(
    "/{prediction_id}",
    response_model=PredictionResponse,
    summary="Obtener una predicción/lesión por ID"
)
async def get_prediction_by_id(
    prediction_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db)
):
    lesion = await PredictionService.obtener_lesion(db, prediction_id)
    if not lesion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesión no encontrada"
        )
    return lesion


@router.get(
    "/user/{user_id}",
    response_model=List[PredictionResponse],
    summary="Listar lesiones de un usuario específico"
)
async def get_predictions_by_user(
    user_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db)
):
    return await PredictionService.listar_lesiones_por_usuario(db, user_id)


@router.get(
    "",
    response_model=List[PredictionResponse],
    summary="Listar todas las predicciones"
)
@router.get(
    "/",
    response_model=List[PredictionResponse],
    include_in_schema=False
)
async def list_all_predictions(
    skip: int = 0,
    limit: int = 100,
    db: AsyncIOMotorDatabase = Depends(get_db)
):
    return await PredictionService.listar_todas(db, skip=skip, limit=limit)