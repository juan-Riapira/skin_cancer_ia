import asyncio
import json
import logging
import os
import uuid
from pathlib import Path, PurePosixPath
from typing import Optional

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import HTTPException, status

logger = logging.getLogger(__name__)
_client = None


def _bucket() -> str:
    """Retorna el nombre del bucket configurado para almacenar las imágenes dermatológicas."""
    return os.getenv("MINIO_BUCKET") or os.getenv("MINIO_BUCKET_NAME") or "lesiones"


def _build_endpoint_url() -> str:
    """Construye la URL del endpoint de MinIO asegurando el protocolo correcto."""
    endpoint = os.getenv("MINIO_ENDPOINT", "localhost:9000").strip()
    if endpoint.startswith("http://") or endpoint.startswith("https://"):
        return endpoint
    esquema = "https" if os.getenv("MINIO_SECURE", "false").lower() == "true" else "http"
    return f"{esquema}://{endpoint}"


def get_client():
    """
    Inicializa o reutiliza el cliente Boto3 configurado para MinIO en Docker.
    Utiliza el estilo 'path' requerido por emuladores locales de S3.
    """
    global _client
    if _client is None:
        endpoint_url = _build_endpoint_url()
        access_key = (
            os.getenv("MINIO_ACCESS_KEY")
            or os.getenv("MINIO_ROOT_USER")
            or os.getenv("S3_ACCESS_KEY")
            or "minioadmin"
        )
        secret_key = (
            os.getenv("MINIO_SECRET_KEY")
            or os.getenv("MINIO_ROOT_PASSWORD")
            or os.getenv("S3_SECRET_KEY")
            or "minioadmin"
        )
        region = os.getenv("MINIO_REGION", "us-east-1")

        _client = boto3.client(
            "s3",
            endpoint_url=endpoint_url,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name=region,
            config=Config(
                signature_version="s3v4",
                s3={"addressing_style": "path"},
                # Fallar rápido si MinIO está apagado (para usar el respaldo local).
                connect_timeout=3,
                read_timeout=30,
                retries={"max_attempts": 2},
            ),
        )
    return _client


def _ensure_bucket_sync() -> None:
    """
    Verifica que el bucket exista en MinIO; si no existe, lo crea y le aplica
    una política de acceso público de solo lectura (GetObject) para que las URLs
    puedan ser visualizadas por la aplicación móvil y navegadores sin autenticación adicional.
    """
    bucket = _bucket()
    try:
        client = get_client()
        try:
            client.head_bucket(Bucket=bucket)
        except ClientError:
            try:
                client.create_bucket(Bucket=bucket)
                logger.info("Bucket '%s' creado exitosamente en MinIO.", bucket)
            except Exception as ce:
                logger.warning("Aviso al intentar crear bucket '%s': %s", bucket, ce)

        # Política de lectura pública
        policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"AWS": ["*"]},
                    "Action": ["s3:GetObject"],
                    "Resource": [f"arn:aws:s3:::{bucket}/*"],
                }
            ],
        }
        try:
            client.put_bucket_policy(Bucket=bucket, Policy=json.dumps(policy))
        except Exception as pe:
            logger.warning("No se pudo aplicar la política pública al bucket: %s", pe)

    except Exception as e:
        logger.warning(
            "Aviso: No se pudo verificar o configurar el bucket en MinIO al iniciar: %s. "
            "Asegúrate de que el contenedor de Docker esté activo.",
            e,
        )


async def ensure_bucket() -> None:
    """Ejecuta de manera asíncrona la verificación/creación del bucket."""
    await asyncio.to_thread(_ensure_bucket_sync)


def _upload_sync(data: bytes, key: str, content_type: str) -> None:
    """Envía los bytes de la imagen a MinIO de forma síncrona."""
    bucket = _bucket()
    client = get_client()
    try:
        client.put_object(
            Bucket=bucket,
            Key=key,
            Body=data,
            ContentType=content_type,
        )
    except (BotoCoreError, ClientError) as e:
        logger.error("Error al subir objeto '%s' al bucket '%s': %s", key, bucket, e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al subir imagen a MinIO en Docker: {str(e)}",
        )


# Carpeta de respaldo cuando MinIO no está disponible (servida en /uploads).
LOCAL_UPLOAD_DIR = Path(__file__).resolve().parent.parent.parent / "uploads"


def _fallback_local_activo() -> bool:
    return os.getenv("STORAGE_FALLBACK_LOCAL", "true").lower() == "true"


def _guardar_local(data: bytes, key: str) -> str:
    """Guarda la imagen en backend/uploads/<key> y devuelve su URL pública."""
    destino = LOCAL_UPLOAD_DIR / key
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_bytes(data)
    base = (os.getenv("PUBLIC_API_URL") or "http://localhost:8000").rstrip("/")
    return f"{base}/uploads/{key}"


async def _minio_disponible() -> bool:
    def _check() -> bool:
        try:
            get_client().head_bucket(Bucket=_bucket())
            return True
        except ClientError as e:
            # El servidor respondió (p. ej. bucket inexistente): MinIO está vivo.
            return e.response.get("Error", {}).get("Code") not in (None, "")
        except Exception:
            return False

    return await asyncio.to_thread(_check)


async def upload_image(data: bytes, filename: str, content_type: str, usuario_id: str) -> str:
    """
    Sube la imagen dermatológica al almacenamiento MinIO (S3 compatible en Docker)
    y genera la URL pública que se almacena en MongoDB Atlas.

    Si MinIO no está disponible y STORAGE_FALLBACK_LOCAL=true (por defecto),
    guarda la imagen en la carpeta local backend/uploads y la sirve en /uploads.
    """
    ext = PurePosixPath(filename or "").suffix.lower() or ".jpg"
    key = f"{usuario_id}/{uuid.uuid4().hex}{ext}"

    if not await _minio_disponible():
        if not _fallback_local_activo():
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="El almacenamiento de imágenes (MinIO) no está disponible.",
            )
        logger.warning("MinIO no disponible: imagen guardada en almacenamiento local (%s).", key)
        return await asyncio.to_thread(_guardar_local, data, key)

    # Asegurar que el bucket exista antes de subir
    await ensure_bucket()
    await asyncio.to_thread(_upload_sync, data, key, content_type)

    public_base = os.getenv("MINIO_PUBLIC_URL")
    if not public_base:
        public_base = _build_endpoint_url()

    public_base = public_base.rstrip("/")
    return f"{public_base}/{_bucket()}/{key}"
