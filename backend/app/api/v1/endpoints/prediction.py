import logging
from typing import List, Optional
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status

from app.database.connection import get_database
from app.schemas.prediction import PredictionCreate, PredictionResponse
from app.services.prediction_service import PredictionService
from app.services import storage_service
from app.services.user_service import obtener_usuario

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/predictions", tags=["Predicciones / Lesiones"])

TIPOS_PERMITIDOS = {"image/jpeg", "image/png", "image/webp", "image/jpg"}
MAX_BYTES = 10 * 1024 * 1024  # 10 MB


@router.post(
    "",
    response_model=PredictionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar una nueva lesión y subir imagen a MinIO",
)
@router.post(
    "/",
    response_model=PredictionResponse,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False,
)
async def crear_prediccion(
    usuario_id: str = Form(..., description="ID del usuario asociado a la captura"),
    zona_cuerpo: Optional[str] = Form(None, description="Zona anatómica de la lesión (ej: Brazo, Espalda)"),
    imagen: UploadFile = File(..., description="Archivo de imagen (JPEG, PNG o WebP)"),
    db=Depends(get_database),
):
    """
    Recibe la imagen enviada por el usuario (o la app móvil):
    1. La almacena en el servicio MinIO (Docker) y genera la URL pública.
    2. Procesa la inferencia diagnóstica con el modelo de IA.
    3. Almacena la predicción en MongoDB Atlas guardando la misma URL de MinIO
       tanto en 'imagen_movil' como en 'analisis_dermatologica.imagen_dermatologica'.
    """
    # 0. El usuario debe existir antes de guardar la imagen y el análisis
    if not await obtener_usuario(db, usuario_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado. Registra el usuario antes de enviar lesiones.",
        )

    if imagen.content_type not in TIPOS_PERMITIDOS:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Formato no permitido ({imagen.content_type}). Solo se aceptan imágenes JPEG, PNG o WebP.",
        )

    contenido = await imagen.read()
    if len(contenido) > MAX_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="La imagen supera el límite máximo permitido de 10 MB.",
        )

    # 1. Almacenar la imagen en MinIO (S3 compatible en Docker) y obtener URL pública
    try:
        image_url = await storage_service.upload_image(
            data=contenido,
            filename=imagen.filename or "lesion.jpg",
            content_type=imagen.content_type or "image/jpeg",
            usuario_id=usuario_id,
        )
    except Exception as e:
        logger.error("Error al subir imagen a MinIO: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al guardar la imagen en el almacenamiento MinIO: {str(e)}",
        )

    # 2. Inferencia de IA: Se pasa None para que el servicio genere o conecte el modelo
    ai_result = None

    # 3. Guardar en MongoDB Atlas
    data = PredictionCreate(usuario_id=usuario_id, zona_cuerpo=zona_cuerpo)
    documento = await PredictionService.process_and_save(
        db=db,
        data=data,
        image_url=image_url,
        ai_result=ai_result,
    )

    return documento


@router.get(
    "",
    response_model=List[PredictionResponse],
    summary="Listar todas las lesiones registradas",
)
@router.get(
    "/",
    response_model=List[PredictionResponse],
    include_in_schema=False,
)
async def listar_todas(
    skip: int = 0,
    limit: int = 100,
    db=Depends(get_database),
):
    """Retorna todas las lesiones registradas en la base de datos con paginación."""
    return await PredictionService.listar_todas(db, skip=skip, limit=limit)


@router.get(
    "/usuario/{usuario_id}",
    response_model=List[PredictionResponse],
    summary="Listar lesiones de un usuario específico",
)
async def listar_por_usuario(
    usuario_id: str,
    db=Depends(get_database),
):
    """Retorna el historial de lesiones analizadas para el usuario indicado."""
    return await PredictionService.listar_lesiones_por_usuario(db, usuario_id)


@router.get(
    "/{lesion_id}",
    response_model=PredictionResponse,
    summary="Obtener detalle de una lesión por ID",
)
async def obtener_lesion(
    lesion_id: str,
    db=Depends(get_database),
):
    """Consulta una lesión y su análisis dermatológico por su identificador único."""
    lesion = await PredictionService.obtener_lesion(db, lesion_id)
    if not lesion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesión no encontrada en el sistema.",
        )
    return lesion