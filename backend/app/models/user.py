from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base


class Usuario(Base):
    __tablename__ = "usuario"

    id_usuario: Mapped[int] = mapped_column(
        Integer,
        primary_key=True
    )

    nombre: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    edad: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True
    )

    genero: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True
    )

    id_ubicacion: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True
    )