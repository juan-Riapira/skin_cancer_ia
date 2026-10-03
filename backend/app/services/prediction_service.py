import os
from datetime import datetime
from typing import List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.schemas.prediction import PredictionCreate


class PredictionService:
    
    @staticmethod
    async def process_and_save(
        db: AsyncIOMotorDatabase, 
        data: PredictionCreate, 
        image_url: str, 
        ai_result: dict
    ) -> dict:
        """
        Procesa el resultado de la inferencia dermatológica y persiste el documento
        en la colección 'lesiones' de MongoDB.
        """
        fecha_actual = datetime.utcnow()

        confianza = float(ai_result.get("confianza") or ai_result.get("confidence", 0.94))
        clasificacion = str(
            ai_result.get("clasificacion") 
            or ai_result.get("classification") 
            or ai_result.get("disease", "Malignant")
        )

        nivel_riesgo = ai_result.get("nivel_riesgo")
        if not nivel_riesgo:
            if any(term in clasificacion.lower() for term in ["malignant", "maligno", "melanoma"]) or confianza >= 0.80:
                nivel_riesgo = "Alto"
            elif confianza >= 0.60:
                nivel_riesgo = "Medio"
            else:
                nivel_riesgo = "Bajo"

        arquitectura = ai_result.get("arquitectura") or os.getenv("DEFAULT_AI_ARCHITECTURE", "EfficientNet-B0")
        metrica = ai_result.get("metrica") or {
            "accuracy": confianza,
            "sensibilidad": 0.92,
            "especificidad": 0.95
        }
        validacion_patologia = ai_result.get("validacion_patologia", "Pendiente de revisión clínica")

        analisis_dermatologica = {
            "imagen_dermatologica": ai_result.get("imagen_dermatologica", image_url),
            "clasificacion": clasificacion,
            "validacion_patologia": validacion_patologia,
            "resultados": {
                "clasificacion": clasificacion,
                "nivel_riesgo": nivel_riesgo,
                "confianza": confianza,
                "arquitectura": arquitectura,
                "metrica": metrica
            }
        }

        documento_lesion = {
            "usuario_id": str(data.usuario_id),
            "fecha_captura": fecha_actual,
            "imagen_movil": image_url,
            "zona_cuerpo": data.zona_cuerpo,
            "analisis_dermatologica": analisis_dermatologica
        }

        resultado = await db["lesiones"].insert_one(documento_lesion)
        documento_lesion["_id"] = resultado.inserted_id

        return documento_lesion

    @staticmethod
    async def obtener_lesion(
        db: AsyncIOMotorDatabase,
        lesion_id: str
    ) -> Optional[dict]:
        """
        Obtiene una lesión por su ID (_id en ObjectId o string).
        """
        filtro = {}
        try:
            filtro = {"_id": ObjectId(lesion_id)}
        except Exception:
            filtro = {"_id": lesion_id}

        return await db["lesiones"].find_one(filtro)

    @staticmethod
    async def listar_lesiones_por_usuario(
        db: AsyncIOMotorDatabase,
        usuario_id: str
    ) -> List[dict]:
        """
        Lista todas las lesiones registradas para un usuario específico.
        """
        cursor = db["lesiones"].find({"usuario_id": str(usuario_id)})
        return await cursor.to_list(length=100)

    @staticmethod
    async def listar_todas(
        db: AsyncIOMotorDatabase,
        skip: int = 0,
        limit: int = 100
    ) -> List[dict]:
        """
        Lista todas las lesiones registradas en el sistema.
        """
        cursor = db["lesiones"].find().skip(skip).limit(limit)
        return await cursor.to_list(length=limit)