import os
import uuid
import boto3
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import HTTPException, status, UploadFile

class S3Service:
    @staticmethod
    def _get_client():
        return boto3.client(
            "s3",
            aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
            aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
            region_name=os.getenv("AWS_REGION", "us-east-1")
        )

    @classmethod
    async def upload_image(cls, file: UploadFile) -> str:
        bucket_name = os.getenv("S3_BUCKET_NAME")
        region = os.getenv("AWS_REGION", "us-east-1")
        
        # Generar un nombre único para evitar que imágenes con el mismo nombre se sobrescriban
        file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
        unique_filename = f"lesions/{uuid.uuid4()}.{file_extension}"

        s3_client = cls._get_client()

        try:
            # Leer el contenido binario del archivo
            contents = await file.read()
            
            s3_client.put_object(
                Bucket=bucket_name,
                Key=unique_filename,
                Body=contents,
                ContentType=file.content_type
            )
            
            # Construir la URL pública de S3
            return f"https://{bucket_name}.s3.{region}.amazonaws.com/{unique_filename}"

        except (BotoCoreError, ClientError) as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al subir la imagen a AWS S3: {str(e)}"
            )