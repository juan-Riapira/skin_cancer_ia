import os
import uuid

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import HTTPException, status, UploadFile


class S3Service:
    @staticmethod
    def _get_client():
        endpoint_url = os.getenv("MINIO_ENDPOINT") or os.getenv("S3_ENDPOINT_URL")
        use_ssl = os.getenv("MINIO_USE_SSL", "false").lower() == "true"
        region = os.getenv("MINIO_REGION") or os.getenv("AWS_REGION", "us-east-1")
        access_key = os.getenv("MINIO_ACCESS_KEY") or os.getenv("AWS_ACCESS_KEY_ID")
        secret_key = os.getenv("MINIO_SECRET_KEY") or os.getenv("AWS_SECRET_ACCESS_KEY")
        force_path_style = os.getenv("MINIO_FORCE_PATH_STYLE", "true").lower() == "true"

        config = Config(
            signature_version="s3v4",
            s3={"addressing_style": "path" if force_path_style else "virtual"},
        )

        client_kwargs = {
            "aws_access_key_id": access_key,
            "aws_secret_access_key": secret_key,
            "region_name": region,
            "config": config,
        }

        if endpoint_url:
            client_kwargs["endpoint_url"] = endpoint_url
            client_kwargs["use_ssl"] = use_ssl
            if not use_ssl:
                client_kwargs["verify"] = False

        return boto3.client("s3", **client_kwargs)

    @classmethod
    async def upload_image(cls, file: UploadFile) -> str:
        bucket_name = os.getenv("MINIO_BUCKET_NAME") or os.getenv("S3_BUCKET_NAME")
        if not bucket_name:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Bucket name not configured (MINIO_BUCKET_NAME or S3_BUCKET_NAME)",
            )

        endpoint_url = os.getenv("MINIO_ENDPOINT") or os.getenv("S3_ENDPOINT_URL")
        region = os.getenv("MINIO_REGION") or os.getenv("AWS_REGION", "us-east-1")
        force_path_style = os.getenv("MINIO_FORCE_PATH_STYLE", "true").lower() == "true"
        use_ssl = os.getenv("MINIO_USE_SSL", "false").lower() == "true"
        use_presigned = os.getenv("MINIO_USE_PRESIGNED_URL", "false").lower() == "true"
        presigned_expiry = int(os.getenv("MINIO_PRESIGNED_EXPIRY_SECONDS", "604800"))

        # Generar un nombre único para evitar que imágenes con el mismo nombre se sobrescriban
        file_extension = file.filename.split(".")[-1] if file and "." in file.filename else "jpg"
        unique_filename = f"lesions/{uuid.uuid4()}.{file_extension}"

        s3_client = cls._get_client()

        try:
            # Asegurar que el bucket exista (útil con MinIO en Docker)
            try:
                s3_client.head_bucket(Bucket=bucket_name)
            except ClientError as e:
                error_code = e.response.get("Error", {}).get("Code")
                if error_code in ("404", "NoSuchBucket", "NotFound"):
                    try:
                        s3_client.create_bucket(Bucket=bucket_name)
                    except ClientError as ce:
                        raise HTTPException(
                            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Error al crear bucket en storage: {str(ce)}",
                        )
                else:
                    raise

            # Leer el contenido binario del archivo
            contents = await file.read()
            if hasattr(file, "seek"):
                await file.seek(0)

            s3_client.put_object(
                Bucket=bucket_name,
                Key=unique_filename,
                Body=contents,
                ContentType=file.content_type or "image/jpeg",
            )

            # Construir la URL para guardar en MongoDB
            if endpoint_url:
                if use_presigned:
                    url = s3_client.generate_presigned_url(
                        "get_object",
                        Params={"Bucket": bucket_name, "Key": unique_filename},
                        ExpiresIn=presigned_expiry,
                    )
                    return url

                base = endpoint_url.rstrip("/")
                if force_path_style:
                    return f"{base}/{bucket_name}/{unique_filename}"
                return f"{base}/{unique_filename}"
            else:
                # AWS S3 (virtual-hosted)
                return f"https://{bucket_name}.s3.{region}.amazonaws.com/{unique_filename}"

        except (BotoCoreError, ClientError) as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al subir la imagen al storage: {str(e)}",
            )