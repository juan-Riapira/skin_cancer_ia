"""
Servicio de almacenamiento en AWS S3.

NOTA IMPORTANTE:
Toda la lógica original directa con AWS S3 ha sido comentada según requerimiento:
"modifica no borres solo pon como comentario toda la parte de s3,
por ahora como esta en el docker-compose vamos a utilizar minio".

NO BORRAR este código. Sirve de referencia directa para cuando se retome
el despliegue en producción con AWS S3 real.
"""

import os
import uuid
import logging
from typing import Optional
from fastapi import UploadFile, HTTPException, status
from app.services import storage_service

logger = logging.getLogger(__name__)

# ==============================================================================
# CÓDIGO ORIGINAL AWS S3 (COMENTADO - NO BORRAR SEGÚN INSTRUCCIÓN DEL USUARIO)
# ==============================================================================
# import boto3
# from botocore.config import Config
# from botocore.exceptions import BotoCoreError, ClientError
#
# class S3ServiceAWS:
#     @staticmethod
#     def _get_client():
#         endpoint_url = os.getenv("S3_ENDPOINT_URL")
#         use_ssl = os.getenv("AWS_USE_SSL", "true").lower() == "true"
#         region = os.getenv("AWS_REGION", "us-east-1")
#         access_key = os.getenv("AWS_ACCESS_KEY_ID")
#         secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")
#         force_path_style = False
#
#         config = Config(
#             signature_version="s3v4",
#             s3={"addressing_style": "virtual"},
#         )
#
#         client_kwargs = {
#             "aws_access_key_id": access_key,
#             "aws_secret_access_key": secret_key,
#             "region_name": region,
#             "config": config,
#         }
#
#         if endpoint_url:
#             client_kwargs["endpoint_url"] = endpoint_url
#             client_kwargs["use_ssl"] = use_ssl
#
#         return boto3.client("s3", **client_kwargs)
#
#     @classmethod
#     async def upload_image(cls, file: UploadFile) -> str:
#         bucket_name = os.getenv("S3_BUCKET_NAME")
#         if not bucket_name:
#             raise HTTPException(
#                 status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
#                 detail="Bucket name not configured (S3_BUCKET_NAME)",
#             )
#
#         region = os.getenv("AWS_REGION", "us-east-1")
#         file_extension = file.filename.split(".")[-1] if file and "." in file.filename else "jpg"
#         unique_filename = f"lesions/{uuid.uuid4()}.{file_extension}"
#
#         s3_client = cls._get_client()
#
#         try:
#             contents = await file.read()
#             if hasattr(file, "seek"):
#                 await file.seek(0)
#
#             s3_client.put_object(
#                 Bucket=bucket_name,
#                 Key=unique_filename,
#                 Body=contents,
#                 ContentType=file.content_type or "image/jpeg",
#             )
#
#             # AWS S3 (virtual-hosted URL)
#             return f"https://{bucket_name}.s3.{region}.amazonaws.com/{unique_filename}"
#
#         except (BotoCoreError, ClientError) as e:
#             raise HTTPException(
#                 status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
#                 detail=f"Error al subir la imagen a AWS S3: {str(e)}",
#             )
# ==============================================================================


class S3Service:
    """
    Adaptador de compatibilidad para S3Service.
    Redirige todas las operaciones de almacenamiento al servicio activo (MinIO en Docker)
    gestionado a través de 'storage_service.py'.
    """

    @classmethod
    async def upload_image(cls, file: UploadFile, usuario_id: str = "general") -> str:
        """
        Lee el archivo y delega la subida a MinIO en Docker.
        Retorna la URL accesible de la imagen en MinIO.
        """
        try:
            contenido = await file.read()
            if hasattr(file, "seek"):
                await file.seek(0)

            return await storage_service.upload_image(
                data=contenido,
                filename=file.filename or "imagen.jpg",
                content_type=file.content_type or "image/jpeg",
                usuario_id=usuario_id,
            )
        except Exception as e:
            logger.error("Error delegando subida a MinIO desde S3Service: %s", e)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al subir la imagen al almacenamiento MinIO: {str(e)}",
            )