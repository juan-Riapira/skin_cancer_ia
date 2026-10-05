from datetime import datetime, timezone
from typing import List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.schemas.prediction import PredictionCreate


def _oid(value: str):
    return ObjectId(value) if ObjectId.is_valid(value) else value


def _derivar_riesgo(clasificacion: str) -> str:
    c = clasificacion.lower()
    if "benign" in c or "benigno" in c:
        return "Bajo"
    if any(t in c for t in ("malignant", "maligno", "melanoma")):
        return "Alto"
    return "Medio"


class PredictionService:

    @staticmethod
    async def process_and_save(
        db: AsyncIOMotorDatabase,
        data: PredictionCreate,
        image_url: str,
        ai_result: Optional[dict] = None,
    ) -> dict:
        """Guarda la lesión en 'lesiones'. image_url es la URL de MinIO."""
        analisis = None
        if ai_result:
            clasificacion = str(ai_result.get("clasificacion") or ai_result.get("classification"))
            resultado_clasificacion = str(ai_result.get("clasificacion_modelo") or clasificacion)
            analisis = {
                "imagen_dermatologica": ai_result.get("imagen_dermatologica", image_url),
                "clasificacion": clasificacion,
                "validacion_patologia": bool(ai_result.get("validacion_patologia", False)),
                "resultados": {
                    "clasificacion": resultado_clasificacion,
                    "nivel_riesgo": ai_result.get("nivel_riesgo") or _derivar_riesgo(resultado_clasificacion),
                    "confianza": float(ai_result.get("confianza") or ai_result.get("confidence")),
                    "arquitectura": ai_result["arquitectura"],
                    "metrica": ai_result.get("metrica"),
                },
            }

        documento = {
            "usuario_id": _oid(str(data.usuario_id)),
            "fecha_captura": datetime.now(timezone.utc),
            "imagen_movil": image_url,
            "zona_cuerpo": data.zona_cuerpo,
            "analisis_dermatologica": analisis,
        }
        res = await db["lesiones"].insert_one(documento)
        documento["_id"] = res.inserted_id
        return documento

    @staticmethod
    async def obtener_lesion(db: AsyncIOMotorDatabase, lesion_id: str) -> Optional[dict]:
        return await db["lesiones"].find_one({"_id": _oid(lesion_id)})

    @staticmethod
    async def listar_lesiones_por_usuario(db: AsyncIOMotorDatabase, usuario_id: str) -> List[dict]:
        cursor = db["lesiones"].find({"usuario_id": _oid(str(usuario_id))}).sort("fecha_captura", -1)
        return await cursor.to_list(length=100)

    @staticmethod
    async def listar_todas(db: AsyncIOMotorDatabase, skip: int = 0, limit: int = 100) -> List[dict]:
        cursor = db["lesiones"].find().skip(skip).limit(limit)
        return await cursor.to_list(length=limit)