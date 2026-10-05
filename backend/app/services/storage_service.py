import asyncio
import json
import logging
import os
import uuid
from pathlib import PurePosixPath

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)
_client = None


def _bucket() -> str:
    return os.getenv("MINIO_BUCKET", "lesiones")


def get_client():
    global _client
    if _client is None:
        esquema = "https" if os.getenv("MINIO_SECURE", "false").lower() == "true" else "http"
        _client = boto3.client(
            "s3",
            endpoint_url=f"{esquema}://{os.getenv('MINIO_ENDPOINT', 'localhost:9000')}",
            aws_access_key_id=os.getenv("MINIO_ACCESS_KEY", "rustfsadmin"),
            aws_secret_access_key=os.getenv("MINIO_SECRET_KEY", "rustfsadmin"),
            region_name="us-east-1",
            config=Config(signature_version="s3v4", s3={"addressing_style": "path"}),
        )
    return _client


def _ensure_bucket_sync() -> None:
    client, bucket = get_client(), _bucket()
    try:
        client.head_bucket(Bucket=bucket)
    except ClientError:
        client.create_bucket(Bucket=bucket)

    # Lectura pública para que la app móvil pueda mostrar la URL guardada en Mongo
    policy = {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"AWS": ["*"]},
            "Action": ["s3:GetObject"],
            "Resource": [f"arn:aws:s3:::{bucket}/*"],
        }],
    }
    try:
        client.put_bucket_policy(Bucket=bucket, Policy=json.dumps(policy))
    except Exception as e:
        logger.warning("No se pudo aplicar la política pública al bucket: %s", e)


async def ensure_bucket() -> None:
    await asyncio.to_thread(_ensure_bucket_sync)


def _upload_sync(data: bytes, key: str, content_type: str) -> None:
    get_client().put_object(
        Bucket=_bucket(), Key=key, Body=data, ContentType=content_type
    )


async def upload_image(data: bytes, filename: str, content_type: str, usuario_id: str) -> str:
    """Sube la imagen al almacenamiento S3 y devuelve la URL pública que se guarda en Mongo."""
    ext = PurePosixPath(filename or "").suffix.lower() or ".jpg"
    key = f"{usuario_id}/{uuid.uuid4().hex}{ext}"
    await asyncio.to_thread(_upload_sync, data, key, content_type)
    public_url = os.getenv("MINIO_PUBLIC_URL", "http://localhost:9000").rstrip("/")
    return f"{public_url}/{_bucket()}/{key}"