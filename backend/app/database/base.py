from typing import Annotated, Optional, Any
from bson import ObjectId
from pydantic import BaseModel, ConfigDict, Field, AliasChoices
from pydantic.functional_validators import BeforeValidator

# Tipo personalizado para validar y convertir ObjectId a string en Pydantic
PyObjectId = Annotated[
    str,
    BeforeValidator(lambda v: str(v) if isinstance(v, ObjectId) else str(v) if v is not None else None)
]


class MongoBaseModel(BaseModel):
    """
    Clase base para modelos y esquemas que interactúan con MongoDB.
    Convierte automáticamente el campo _id de MongoDB en un campo id accesible en formato string.
    """
    id: Optional[PyObjectId] = Field(
        default=None,
        validation_alias=AliasChoices("_id", "id"),
        serialization_alias="id"
    )

    model_config = ConfigDict(
        populate_by_name=True,
        arbitrary_types_allowed=True,
    )

    def to_mongo(self, exclude_unset: bool = False, **kwargs) -> dict:
        """
        Convierte el modelo a un diccionario serializable para MongoDB.
        - Omite campos id o _id si su valor es None para que MongoDB asigne _id automáticamente.
        - Si id tiene un valor asignado, lo convierte a '_id' (como ObjectId si es hexadecimal de 24 caracteres).
        """
        data = self.model_dump(by_alias=False, exclude_unset=exclude_unset, **kwargs)
        if "id" in data:
            val = data.pop("id")
            if val is not None:
                try:
                    data["_id"] = ObjectId(val)
                except Exception:
                    data["_id"] = val
        if "_id" in data and data["_id"] is None:
            del data["_id"]
        return data


# Alias Base para compatibilidad
Base = MongoBaseModel