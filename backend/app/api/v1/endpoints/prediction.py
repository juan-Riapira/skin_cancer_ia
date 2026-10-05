from typing import List, Optional
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile

from app.database.connection import get_database
from app.schemas.prediction import PredictionCreate, PredictionResponse
from app.services.prediction_service import PredictionService
from app.services import storage_service

router = APIRouter(prefix="/predictions", tags=["predictions"])

TIPOS_PERMITIDOS = {"image/jpeg", "image/png", "image/webp"}
MAX_BYTES = 10 * 1024 * 1024  # 10 MB


@router.post("", response_model=PredictionResponse, status_code=201)
async def crear_prediccion(
    usuario_id: str = Form(...),
    zona_cuerpo: Optional[str] = Form(None),
    imagen: UploadFile = File(...),
    db=Depends(get_database),
):
    if imagen.content_type not in TIPOS_PERMITIDOS:
        raise HTTPException(415, "Solo se aceptan imágenes JPEG, PNG o WebP")

    contenido = await imagen.read()
    if len(contenido) > MAX_BYTES:
        raise HTTPException(413, "La imagen supera los 10 MB")

    # 1) Guardar la imagen en MinIO y obtener su URL
    image_url = await storage_service.upload_image(
        contenido, imagen.filename, imagen.content_type, usuario_id
    )

    # 2) Inferencia: conecta aquí tu modelo (devuelve dict con clasificacion, confianza, arquitectura, ...)
    ai_result = None  # TODO: ai_result = await run_inference(contenido)

    # 3) Persistir en Mongo con la URL de MinIO
    data = PredictionCreate(usuario_id=usuario_id, zona_cuerpo=zona_cuerpo)
    return await PredictionService.process_and_save(db, data, image_url, ai_result)


@router.get("/usuario/{usuario_id}", response_model=List[PredictionResponse])
async def listar_por_usuario(usuario_id: str, db=Depends(get_database)):
    return await PredictionService.listar_lesiones_por_usuario(db, usuario_id)


@router.get("/{lesion_id}", response_model=PredictionResponse)
async def obtener_lesion(lesion_id: str, db=Depends(get_database)):
    lesion = await PredictionService.obtener_lesion(db, lesion_id)
    if not lesion:
        raise HTTPException(404, "Lesión no encontrada")
    return lesion